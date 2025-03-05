extends Weapon
class_name Turret

# Turret-specific properties
var rotation_speed: float = 3.0  # Radians per second
var aim_ahead_factor: float = 1.0  # How much to lead the target, 1.0 = perfect lead
var current_rotation: float = 0.0
var target_angle: float = 0.0
var fire_arc: float = 180.0  # Firing arc in degrees
var base_inaccuracy: float = 0.1  # Base inaccuracy applied even when not moving
var inaccuracy_from_movement: float = 0.2  # Additional inaccuracy when target is moving fast

# Nodes
var turret_base: Node2D
var turret_barrel: Node2D

func _init() -> void:
	weapon_name = "Auto Turret"
	auto_target = true

func _ready() -> void:
	super._ready()
	
	# Set up turret parts
	turret_base = $TurretBase
	turret_barrel = $TurretBase/TurretBarrel
	
	# Make sure muzzle position is set
	if not muzzle_position:
		muzzle_position = $TurretBase/TurretBarrel/MuzzlePosition

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Rotate turret toward target if we have one
	if current_target and is_instance_valid(current_target):
		_update_rotation(delta)

# Update turret rotation to face target
func _update_rotation(delta: float) -> void:
	# Calculate target position with lead
	var target_pos = _calculate_target_position()
	
	# Get direction to target
	var target_dir = (target_pos - global_position).normalized()
	
	# Calculate target angle
	target_angle = target_dir.angle() + PI/2  # Adjust based on your sprite's forward direction
	
	# Calculate shortest rotation path
	var angle_diff = wrapf(target_angle - turret_base.rotation, -PI, PI)
	
	# Rotate turret smoothly
	if abs(angle_diff) > 0.01:
		var rotation_amount = sign(angle_diff) * min(rotation_speed * delta, abs(angle_diff))
		turret_base.rotation += rotation_amount
	
	# Check if target is within firing arc
	var is_in_arc = abs(angle_diff) <= deg_to_rad(fire_arc / 2)
	
	# Auto fire if target is in arc and weapon is ready
	if is_in_arc and fire_ready and auto_target:
		fire()

# Calculate target position with lead based on target velocity
func _calculate_target_position() -> Vector2:
	if not current_target or not is_instance_valid(current_target):
		return global_position
	
	var target_position = current_target.global_position
	
	# If target has velocity, lead the target
	if current_target is Ship and aim_ahead_factor > 0:
		var target_velocity = current_target.velocity
		var distance = global_position.distance_to(target_position)
		var time_to_hit = distance / projectile_speed
		
		# Lead the target based on its velocity and our projectile speed
		target_position += target_velocity * time_to_hit * aim_ahead_factor
	
	return target_position

func _spawn_projectile() -> void:
	# Get the turret's aiming direction
	var forward_direction = -turret_barrel.global_transform.y.normalized()
	
	# Calculate actual inaccuracy based on target movement
	var actual_inaccuracy = base_inaccuracy
	
	# Add inaccuracy based on target movement if it's a ship
	if current_target is Ship:
		var target_speed = current_target.velocity.length()
		actual_inaccuracy += inaccuracy_from_movement * (target_speed / 1000.0)
	
	# Apply inaccuracy scaled by accuracy stat
	var max_deviation = (1.0 - accuracy) * actual_inaccuracy
	var random_angle = randf_range(-max_deviation, max_deviation)
	forward_direction = forward_direction.rotated(random_angle)
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Set projectile properties
	projectile.global_position = muzzle_position.global_position
	projectile.global_rotation = turret_barrel.global_rotation
	projectile.direction = forward_direction
	projectile.speed = projectile_speed
	projectile.damage = damage
	projectile.source_weapon = self
	projectile.source_ship = equipped_ship
	projectile.max_range = range_distance
	
	emit_signal("weapon_fired", projectile)
	
	# If ship has energy system, consume energy
	if equipped_ship and equipped_ship.has_method("consume_energy"):
		equipped_ship.consume_energy(energy_cost)

# Fire only if target is within arc
func fire() -> bool:
	if current_target and is_instance_valid(current_target):
		var target_pos = current_target.global_position
		var target_dir = (target_pos - global_position).normalized()
		var aim_dir = -turret_barrel.global_transform.y.normalized()
		
		# Check if target is within firing arc using dot product
		var angle_dot = target_dir.dot(aim_dir)
		var min_dot = cos(deg_to_rad(fire_arc / 2))
		
		if angle_dot >= min_dot:
			return super.fire()
		
	return false
