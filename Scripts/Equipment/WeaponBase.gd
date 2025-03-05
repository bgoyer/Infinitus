extends Equipment
class_name Weapon

# Base weapon properties
var damage: int = 10
var fire_rate: float = 1.0  # Shots per second
var range_distance: float = 1000.0
var fire_ready: bool = true
var cooldown_timer: float = 0.0
var projectile_speed: float = 800.0
var energy_cost: int = 5  # Energy cost per shot
var ammo_capacity: int = -1  # -1 means unlimited ammo
var ammo_count: int = -1  # Current ammo count
var weapon_name: String = "Generic Weapon"
var accuracy: float = 1.0  # 1.0 = perfect accuracy, lower values add spread


# Projectile scene to instance when firing
var projectile_scene: PackedScene

# Targeting properties
var current_target: Node2D = null
var auto_target: bool = false  # Whether weapon auto-acquires targets
var target_acquisition_range: float = 1000.0
var can_target_planets: bool = false
var can_target_ships: bool = true

# References
var muzzle_position: Marker2D  # Actual firing point
var visual_model: Node2D  # Visual representation of the weapon

# Signals
signal weapon_fired(projectile_instance)
signal ammo_depleted
signal target_acquired(target)
signal target_lost

func _ready() -> void:
	add_to_group("Weapons")
	muzzle_position = $MuzzlePosition
	visual_model = $VisualModel
	
	# Initialize with max ammo
	if ammo_capacity > 0:
		ammo_count = ammo_capacity

func _physics_process(delta: float) -> void:
	# Handle cooldown
	if not fire_ready:
		cooldown_timer += delta
		if cooldown_timer >= 1.0 / fire_rate:
			fire_ready = true
			cooldown_timer = 0.0
	
	# Handle auto targeting if enabled
	if auto_target and current_target == null:
		find_target()
	
	# Check if target is still valid
	if current_target and not is_instance_valid(current_target):
		lose_target()

# Try to fire the weapon - core mechanic, will be extended by subclasses
func fire() -> bool:
	if not can_fire():
		return false
		
	# Start cooldown
	fire_ready = false
	cooldown_timer = 0.0
	
	# Consume ammo if limited
	if ammo_capacity > 0:
		ammo_count -= 1
		if ammo_count <= 0:
			emit_signal("ammo_depleted")
	
	# Instantiate projectile at muzzle position
	if projectile_scene:
		_spawn_projectile()
	
	return true

# Check if weapon can fire
func can_fire() -> bool:
	if not fire_ready:
		return false
		
	if ammo_capacity > 0 and ammo_count <= 0:
		return false
		
	# Check energy if ship has energy system
	if equipped_ship and equipped_ship.has_method("has_energy") and equipped_ship.has_energy(energy_cost):
		return true
	elif energy_cost == 0 or equipped_ship == null:
		return true
	else:
		return false

# Spawn a projectile - implementation varies by weapon type
func _spawn_projectile() -> void:
	pass

# Target acquisition
func find_target() -> bool:
	if not auto_target:
		return false
		
	var potential_targets = []
	
	# Get all potential targets within range
	if can_target_ships:
		var ships = get_tree().get_nodes_in_group("Ships")
		for ship in ships:
			# Skip our own ship
			if ship == equipped_ship:
				continue
				
			# Skip allied ships (if faction system exists)
			if equipped_ship and equipped_ship.has_method("is_allied_with") and equipped_ship.is_allied_with(ship):
				continue
				
			# Check if in range
			var distance = global_position.distance_to(ship.global_position)
			if distance <= target_acquisition_range:
				potential_targets.append(ship)
	
	# Add planets if allowed
	if can_target_planets:
		var planets = get_tree().get_nodes_in_group("CelestialBodies")
		for planet in planets:
			var distance = global_position.distance_to(planet.global_position)
			if distance <= target_acquisition_range:
				potential_targets.append(planet)
	
	# Select closest target
	if potential_targets.size() > 0:
		var closest_target = potential_targets[0]
		var closest_distance = global_position.distance_to(closest_target.global_position)
		
		for target in potential_targets:
			var distance = global_position.distance_to(target.global_position)
			if distance < closest_distance:
				closest_target = target
				closest_distance = distance
		
		set_target(closest_target)
		return true
	
	return false

# Set a specific target
func set_target(target: Node2D) -> void:
	if target and is_instance_valid(target):
		current_target = target
		emit_signal("target_acquired", current_target)

# Clear current target
func lose_target() -> void:
	current_target = null
	emit_signal("target_lost")

# Reload with new ammo
func reload(amount: int = -1) -> void:
	if ammo_capacity <= 0:
		return  # Unlimited ammo, no need to reload
		
	if amount == -1:
		ammo_count = ammo_capacity  # Full reload
	else:
		ammo_count = min(ammo_count + amount, ammo_capacity)

# Called when the weapon is equipped on a ship
func equip(ship: Ship) -> void:
	equipped_ship = ship

# Called when the weapon is unequipped from a ship
func unequip() -> void:
	equipped_ship = null
	lose_target()
