extends CharacterBody2D
class_name Ship

# Basic ship properties
var thruster: Thruster
var turning: Turning
var locked: bool = false
var pilot: Pilot
var max_velocity: float = 1000 # Default value

# Hull properties (integrated directly into Ship)
@export var max_hull_health: int = 100
@export var current_hull_health: int = 100

# Cache these components for better performance
var _thruster_cached: bool = false
var _turning_cached: bool = false

# Component references
var shield: ShieldBase
var armor: ArmorBase
var capacitor: CapacitorBase
var generator: GeneratorBase
var weapon_manager: WeaponManager

# Faction/team for targeting purposes
var faction: String = "neutral"

# Signals
signal weapon_fired(weapon, projectile)
signal ship_destroyed()
signal hull_damaged(current, max_health)
signal shield_changed(current, max_shield)
signal energy_changed(current, max_energy)
signal component_attached(component)
signal component_detached(component)

# Damage types enum (shared with armor)
enum DamageType {KINETIC, ENERGY, EXPLOSIVE, THERMAL}

func _ready() -> void:
	# Set up pilot
	pilot = set_pilot_or_null()
	
	# Cache components at initialization
	thruster = get_thruster()
	turning = get_turning()
	_thruster_cached = thruster != null
	_turning_cached = turning != null
	
	# Initialize hull health
	current_hull_health = max_hull_health
	
	# Find and connect specialized systems
	_find_and_connect_systems()
	
	# Connect signals
	_connect_signals()
	
func _physics_process(delta: float) -> void:
	move_and_slide()

# Connect systems to the ship (called on _ready and when new components are added)
func _find_and_connect_systems() -> void:
	# Find shield, armor, capacitor, and generator
	for child in get_children():
		if child is ShieldBase and shield != child:
			shield = child
			shield.ship = self
			
		elif child is ArmorBase and armor != child:
			armor = child
			armor.ship = self
			
		elif child is CapacitorBase and capacitor != child:
			capacitor = child
			capacitor.ship = self
			
		elif child is GeneratorBase and generator != child:
			generator = child
			generator.ship = self
			
		elif child is WeaponManager and weapon_manager != child:
			weapon_manager = child
	
	# Set up weapon manager if it doesn't exist
	if not weapon_manager:
		weapon_manager = WeaponManager.new()
		weapon_manager.name = "WeaponManager"
		add_child(weapon_manager)

# Movement methods

func accelerate(delta: float) -> void:
	if locked == false:
		locked = true
	
	if not _thruster_cached:
		thruster = get_thruster()
		_thruster_cached = thruster != null
	
	if _thruster_cached:
		# Check energy system if available
		if capacitor and thruster:
			# Calculate energy cost based on thruster
			var thrust_energy_cost = thruster.drain
			
			# Only accelerate if we have enough energy
			if capacitor.drain_energy(thrust_energy_cost * delta, "thruster"):
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

func accelerate_done() -> void:
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

# Damage handling - centralized in the ship
func take_damage(amount: int, source: Node = null, hit_position: Vector2 = Vector2.ZERO, damage_type: int = DamageType.KINETIC) -> void:
	var damage_remaining = amount
	
	# First try to absorb with shields if available
	if shield and shield.is_active and shield.current_shield > 0:
		damage_remaining = shield.absorb_damage(damage_remaining, hit_position)
	
	# Then try armor if available and damage remains
	if damage_remaining > 0 and armor:
		damage_remaining = armor.absorb_damage(damage_remaining, damage_type)
	
	# Finally, apply remaining damage to hull
	if damage_remaining > 0:
		damage_hull(damage_remaining, source, hit_position)

# Apply damage directly to hull
func damage_hull(amount: int, source: Node = null, hit_position: Vector2 = Vector2.ZERO) -> void:
	current_hull_health = max(0, current_hull_health - amount)
	
	emit_signal("hull_damaged", current_hull_health, max_hull_health)
	
	# Check if ship is destroyed
	if current_hull_health <= 0:
		_handle_destruction()

# Handle ship destruction
func _handle_destruction() -> void:
	emit_signal("ship_destroyed")
	
	# Create explosion effect (would be replaced with actual effect)
	# var explosion = preload("res://Scenes/Effects/ShipExplosion.tscn").instantiate()
	# get_tree().root.add_child(explosion)
	# explosion.global_position = global_position
	
	# Remove the ship
	queue_free()

# Energy management methods
func has_energy(amount: int) -> bool:
	return capacitor != null and capacitor.has_energy(amount)

func consume_energy(amount: int, source: String = "unknown") -> bool:
	return capacitor != null and capacitor.drain_energy(amount, source)

func add_energy(amount: int) -> int:
	if capacitor:
		return capacitor.add_energy(amount)
	return 0

# Repair methods
func repair_hull(amount: int) -> void:
	current_hull_health = min(current_hull_health + amount, max_hull_health)
	emit_signal("hull_damaged", current_hull_health, max_hull_health)

func repair_armor(amount: float) -> void:
	if armor:
		armor.repair(amount)

func recharge_shield(amount: int) -> void:
	if shield:
		shield.current_shield = min(shield.current_shield + amount, shield.max_shield)
		emit_signal("shield_changed", shield.current_shield, shield.max_shield)

# Signal connections
func _connect_signals() -> void:
	# Connect shield signals
	if shield:
		if not shield.is_connected("shield_changed", Callable(self, "_on_shield_changed")):
			shield.connect("shield_changed", Callable(self, "_on_shield_changed"))
	
	# Connect capacitor signals
	if capacitor:
		if not capacitor.is_connected("energy_changed", Callable(self, "_on_energy_changed")):
			capacitor.connect("energy_changed", Callable(self, "_on_energy_changed"))
	
	# Connect weapon manager signals
	if weapon_manager:
		if not weapon_manager.is_connected("weapon_fired", Callable(self, "_on_weapon_fired")):
			weapon_manager.connect("weapon_fired", Callable(self, "_on_weapon_fired"))

# Signal handlers
func _on_shield_changed(current: int, max_value: int) -> void:
	emit_signal("shield_changed", current, max_value)

func _on_energy_changed(current: int, max_value: int) -> void:
	emit_signal("energy_changed", current, max_value)

func _on_weapon_fired(weapon: Weapon, projectile) -> void:
	emit_signal("weapon_fired", weapon, projectile)

# Called when new node is added to this ship
func _on_child_entered_tree(node: Node) -> void:
	# Check if this is a component we need to connect
	if node is ShieldBase or node is ArmorBase or node is CapacitorBase or node is GeneratorBase:
		_find_and_connect_systems()
		emit_signal("component_attached", node)

# Called when a node is removed from this ship
func _on_child_exiting_tree(node: Node) -> void:
	# Check if this is a component we need to disconnect
	if node is ShieldBase or node is ArmorBase or node is CapacitorBase or node is GeneratorBase:
		emit_signal("component_detached", node)
		
		# Reset references if needed
		if node is ShieldBase and shield == node:
			shield = null
		elif node is ArmorBase and armor == node:
			armor = null
		elif node is CapacitorBase and capacitor == node:
			capacitor = null
		elif node is GeneratorBase and generator == node:
			generator = null

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

# Check if ship is allied with another ship (for targeting)
func is_allied_with(other_ship: Ship) -> bool:
	return other_ship.faction == faction

# Helper function to add a component to the ship
func add_component(component: Node) -> void:
	add_child(component)
	# The _on_child_entered_tree handler will take care of connections

# Helper function to remove a component from the ship
func remove_component(component: Node) -> void:
	if component and component.get_parent() == self:
		remove_child(component)
		# The _on_child_exiting_tree handler will take care of disconnections
