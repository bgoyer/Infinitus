extends Weapon
class_name MissileLauncher

# Missile-specific properties
var missile_tracking_time: float = 5.0  # How long missiles track before expiring
var missile_turning_speed: float = 2.0  # How quickly missiles can turn
var missile_acceleration: float = 100.0  # How fast missiles accelerate
var missile_max_speed: float = 500.0  # Maximum missile speed
var missile_arm_distance: float = 50.0  # Distance before missile can start tracking
var missile_blast_radius: float = 50.0  # Explosion radius
var launch_spread: float = 5.0  # Random spread on launch (degrees)
var salvo_size: int = 1  # How many missiles to fire at once
var salvo_delay: float = 0.1  # Delay between missiles in salvo
var current_salvo: int = 0
var salvo_timer: float = 0.0
var is_firing_salvo: bool = false

func _init() -> void:
	weapon_name = "Missile Launcher"
	auto_target = true
	fire_rate = 0.5  # Slower fire rate than guns
	damage = 50  # Higher damage than bullets
	energy_cost = 15  # Higher energy cost
	ammo_capacity = 20  # Limited ammo by default

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Handle salvo firing
	if is_firing_salvo:
		salvo_timer += delta
		if salvo_timer >= salvo_delay:
			salvo_timer = 0
			_launch_missile()
			current_salvo += 1
			
			if current_salvo >= salvo_size:
				is_firing_salvo = false
				current_salvo = 0

func fire() -> bool:
	if not can_fire():
		return false
	
	# Start firing salvo
	is_firing_salvo = true
	current_salvo = 0
	salvo_timer = salvo_delay  # Fire first missile immediately
	
	# Mark weapon as on cooldown
	fire_ready = false
	cooldown_timer = 0.0
	
	return true

func _launch_missile() -> void:
	# Get the launcher's forward direction
	var forward_direction = -global_transform.y.normalized()
	
	# Apply launch spread
	var spread_rad = deg_to_rad(launch_spread)
	forward_direction = forward_direction.rotated(randf_range(-spread_rad, spread_rad))
	
	# Create missile
	var missile = projectile_scene.instantiate()
	get_tree().root.add_child(missile)
	
	# Set basic projectile properties
	missile.global_position = muzzle_position.global_position
	missile.global_rotation = global_rotation
	missile.direction = forward_direction
	missile.initial_speed = projectile_speed * 0.5  # Start slower, then accelerate
	missile.max_speed = missile_max_speed
	missile.acceleration = missile_acceleration
	missile.damage = damage
	missile.source_weapon = self
	missile.source_ship = equipped_ship
	
	# Set missile-specific properties
	missile.tracking_time = missile_tracking_time
	missile.turning_speed = missile_turning_speed
	missile.arm_distance = missile_arm_distance
	missile.blast_radius = missile_blast_radius
	
	# Set target if available
	if current_target and is_instance_valid(current_target):
		missile.target = current_target
	
	emit_signal("weapon_fired", missile)
	
	# Consume ammo
	if ammo_capacity > 0:
		ammo_count -= 1
		if ammo_count <= 0:
			emit_signal("ammo_depleted")
			is_firing_salvo = false
	
	# If ship has energy system, consume energy
	if equipped_ship and equipped_ship.has_method("consume_energy"):
		equipped_ship.consume_energy(energy_cost / salvo_size)  # Divide energy cost across salvo
