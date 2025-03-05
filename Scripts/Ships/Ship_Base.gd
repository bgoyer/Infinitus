extends CharacterBody2D
class_name Ship

# Base ship properties
var thruster: Thruster
var turning: Turning
var locked: bool = false
var pilot: Pilot
var max_velocity: float = 1000 # Default value

# Cache these components for better performance
var _thruster_cached: bool = false
var _turning_cached: bool = false

# Combat system references
var weapon_manager: WeaponManager
var health: ShipHealth
var energy: ShipEnergy

# Faction/team for targeting purposes
var faction: String = "neutral"

# Signals
signal weapon_fired(weapon, projectile)
signal destroyed()
signal health_changed(current, max_health)
signal shield_changed(current, max_shield)
signal energy_changed(current, max_energy)

func _ready() -> void:
	# Set up pilot
	pilot = set_pilot_or_null()
	
	# Cache components at initialization
	thruster = get_thruster()
	turning = get_turning()
	_thruster_cached = thruster != null
	_turning_cached = turning != null
	
	# Initialize combat systems
	_setup_combat_systems()
	
	# Connect signals
	_connect_signals()
	
func _physics_process(delta: float) -> void:
	move_and_slide()

func accelerate(delta: float) -> void:
	if locked == false:
		locked = true
	
	if not _thruster_cached:
		thruster = get_thruster()
		_thruster_cached = thruster != null
	
	if _thruster_cached:
		# Check energy system if available
		if energy and thruster:
			# Calculate energy cost based on thruster
			var thrust_energy_cost = thruster.drain
			
			# Only accelerate if we have enough energy
			if energy.consume_energy(thrust_energy_cost * delta, "thruster"):
				var current_speed = velocity.length()
				if current_speed < max_velocity:
					# Apply thrust in the direction the ship is facing
					velocity += -transform.y * thruster.thrust * delta * 100
					# Cap velocity at max_velocity
					if velocity.length() > max_velocity:
						velocity = velocity.normalized() * max_velocity
			return
			
		# If no energy system or not enough energy, use standard acceleration
		var current_speed = velocity.length()
		if current_speed < max_velocity:
			# Apply thrust in the direction the ship is facing
			velocity += -transform.y * thruster.thrust * delta * 100
			# Cap velocity at max_velocity
			if velocity.length() > max_velocity:
				velocity = velocity.normalized() * max_velocity
		else:
			# Slight slowdown when at max speed to prevent exceeding it
			velocity *= 0.99

func accelerate_done():
	locked = false

func turn_left(delta: float) -> void:
	if not _turning_cached:
		turning = get_turning()
		_turning_cached = turning != null
	
	if _turning_cached:
		self.global_rotation += (-turning.thrust * delta)

func turn_right(delta: float) -> void:
	if not _turning_cached:
		turning = get_turning()
		_turning_cached = turning != null
	
	if _turning_cached:
		self.rotate(turning.thrust * delta)

func turn_behind(delta: float) -> void:
	if not _turning_cached:
		turning = get_turning()
		_turning_cached = turning != null
	
	if _turning_cached and velocity.length() > 10: # Small threshold to prevent jitter
		# Compute the target rotation (adjust the PI/2 offset if your sprite faces a different direction)
		var target_rotation = (-velocity).angle() + PI/2
		# Calculate the smallest angle difference in the range [-PI, PI]
		var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
		# If the difference is negligible, do nothing
		if abs(angle_diff) < 0.01:
			return
		# Call the appropriate turning function to gradually rotate toward the target
		if angle_diff > 0:
			turn_right(delta)
		else:
			turn_left(delta)

# Set up weapon, health, and energy systems
func _setup_combat_systems() -> void:
	# Create weapon manager if it doesn't exist
	if not has_node("WeaponManager"):
		weapon_manager = WeaponManager.new()
		weapon_manager.name = "WeaponManager"
		add_child(weapon_manager)
	else:
		weapon_manager = $WeaponManager
	
	# Create health system if it doesn't exist
	if not has_node("Health"):
		health = ShipHealth.new()
		health.name = "Health"
		add_child(health)
	else:
		health = $Health
	
	# Create energy system if it doesn't exist
	if not has_node("Energy"):
		energy = ShipEnergy.new()
		energy.name = "Energy"
		add_child(energy)
	else:
		energy = $Energy

# Connect signals from subsystems
func _connect_signals() -> void:
	if weapon_manager:
		if not weapon_manager.is_connected("weapon_fired", Callable(self, "_on_weapon_fired")):
			weapon_manager.connect("weapon_fired", Callable(self, "_on_weapon_fired"))
	
	if health:
		if not health.is_connected("health_changed", Callable(self, "_on_health_changed")):
			health.connect("health_changed", Callable(self, "_on_health_changed"))
		
		if not health.is_connected("shield_changed", Callable(self, "_on_shield_changed")):
			health.connect("shield_changed", Callable(self, "_on_shield_changed"))
		
		if not health.is_connected("ship_destroyed", Callable(self, "_on_ship_destroyed")):
			health.connect("ship_destroyed", Callable(self, "_on_ship_destroyed"))
	
	if energy:
		if not energy.is_connected("energy_changed", Callable(self, "_on_energy_changed")):
			energy.connect("energy_changed", Callable(self, "_on_energy_changed"))

# Weapon firing methods
func fire_primary() -> void:
	if weapon_manager:
		weapon_manager.fire_weapons("primary")

func fire_secondary() -> void:
	if weapon_manager:
		weapon_manager.fire_weapons("secondary")

func fire_tertiary() -> void:
	if weapon_manager:
		weapon_manager.fire_weapons("tertiary")

# Target management
func set_target(target: Node2D) -> void:
	if weapon_manager:
		weapon_manager.set_target(target)

func clear_target() -> void:
	if weapon_manager:
		weapon_manager.clear_targets()

# Damage handling - redirect to health system
func take_damage(amount: int, source: Node = null, hit_position: Vector2 = Vector2.ZERO) -> void:
	if health:
		health.take_damage(amount, source, hit_position)

# Energy management
func has_energy(amount: int) -> bool:
	return energy != null and energy.has_energy(amount)

func consume_energy(amount: int, source: String = "unknown") -> bool:
	return energy != null and energy.consume_energy(amount, source)

# Check if ship is allied with another ship (for targeting)
func is_allied_with(other_ship: Ship) -> bool:
	return other_ship.faction == faction

# Signal handlers
func _on_weapon_fired(weapon: Weapon, projectile) -> void:
	emit_signal("weapon_fired", weapon, projectile)

func _on_health_changed(current: int, max_value: int) -> void:
	emit_signal("health_changed", current, max_value)

func _on_shield_changed(current: int, max_value: int) -> void:
	emit_signal("shield_changed", current, max_value)

func _on_energy_changed(current: int, max_value: int) -> void:
	emit_signal("energy_changed", current, max_value)

func _on_ship_destroyed() -> void:
	emit_signal("destroyed")

# Called when weapons are fired (for reactions like recoil)
func on_weapons_fired(group_name: String) -> void:
	# Add visual feedback, camera shake, etc.
	if group_name == "primary":
		# Maybe add a small impulse in the opposite direction
		pass
	elif group_name == "secondary":
		# Different reaction for secondary weapons
		pass
	elif group_name == "tertiary":
		# Different reaction for missiles/heavy weapons
		pass

# Helper function to add a weapon to the ship
func add_weapon(weapon_scene: PackedScene, hardpoint_index: int) -> Weapon:
	if not weapon_manager:
		return null
		
	var weapon = weapon_scene.instantiate()
	if weapon_manager.add_weapon(weapon, hardpoint_index):
		return weapon
	else:
		weapon.queue_free()
		return null

# Helper to get all weapons on the ship
func get_weapons() -> Array[Weapon]:
	if weapon_manager:
		return weapon_manager.weapons
	return []

####################################Checks######################################

func set_pilot_or_null() -> Pilot:
	for child in get_children():
		if child is Pilot:
			child.set_ship(self)
			return child
	return null

func is_thruster_installed() -> bool:
	return _thruster_cached || get_thruster() != null

func get_thruster() -> Thruster:
	for child in get_children():
		if child is Thruster:
			return child
	return null
	
func is_turning_installed() -> bool:
	return _turning_cached || get_turning() != null

func get_turning() -> Turning:
	for child in get_children():
		if child is Turning:
			return child
	return null
