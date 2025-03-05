extends Projectile
class_name Missile

# Missile-specific properties
var target: Node2D
var tracking_time: float = 5.0
var turning_speed: float = 2.0
var acceleration: float = 100.0
var max_speed: float = 500.0
var initial_speed: float = 200.0
var arm_distance: float = 50.0
var blast_radius: float = 50.0
var is_armed: bool = false

# Time tracking
var time_alive: float = 0.0
var is_exploding: bool = false

# Engine particles
var engine_particles: GPUParticles2D

func _init() -> void:
	speed = 200.0  # Initial slower speed
	damage = 50
	max_range = 3000.0
	penetrates = false

func _ready() -> void:
	super._ready()
	
	# Get engine particles if they exist
	engine_particles = $EngineParticles if has_node("EngineParticles") else null

func _physics_process(delta: float) -> void:
	time_alive += delta
	
	# Don't move if exploding
	if is_exploding:
		return
	
	# Accelerate the missile
	speed = min(speed + acceleration * delta, max_speed)
	
	# Check if missile is now armed (minimum distance from launcher)
	if not is_armed and distance_traveled >= arm_distance:
		is_armed = true
	
	# If armed and has target, update direction to track target
	if is_armed and target and is_instance_valid(target) and time_alive < tracking_time:
		_track_target(delta)
	else:
		# If tracking time expired or target lost, just continue straight
		position += direction * speed * delta
	
	# Update distance traveled
	distance_traveled += speed * delta
	
	# Check if we've exceeded max range or tracking time
	if distance_traveled >= max_range or time_alive >= tracking_time:
		explode()

# Track target by adjusting missile direction
func _track_target(delta: float) -> void:
	# Get direction to target
	var target_direction = (target.global_position - global_position).normalized()
	
	# Calculate angle to target
	var current_angle = direction.angle()
	var target_angle = target_direction.angle()
	
	# Find the shortest turn direction
	var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
	
	# Adjust direction with limited turning speed
	var turn_amount = sign(angle_diff) * min(turning_speed * delta, abs(angle_diff))
	direction = direction.rotated(turn_amount)
	
	# Update sprite rotation to match direction
	rotation = direction.angle() + PI/2  # Adjust based on sprite orientation
	
	# Move missile
	position += direction * speed * delta

# Override to create explosion
func _on_body_entered(body: Node) -> void:
	# Skip collision with source and already exploding
	if body == source_ship or is_exploding:
		return
	
	# Create explosion
	explode()

# Handle explosion
func explode() -> void:
	if is_exploding:
		return
		
	is_exploding = true
	
	# Create explosion effect
	var explosion = preload("res://Scenes/Effects/MissileExplosion.tscn").instantiate()
	get_tree().root.add_child(explosion)
	explosion.global_position = global_position
	explosion.scale = Vector2.ONE * (blast_radius / 50.0)  # Scale based on blast radius
	
	# Apply area damage to nearby objects
	var nearby_bodies = _get_bodies_in_radius(blast_radius)
	for body in nearby_bodies:
		if body != source_ship:  # Don't damage source ship
			var distance = global_position.distance_to(body.global_position)
			var damage_factor = 1.0 - (distance / blast_radius)  # Damage falls off with distance
			var applied_damage = damage * damage_factor
			
			if body.has_method("take_damage"):
				body.take_damage(applied_damage, source_ship)
			elif body is Ship:
				var health = body.get_node_or_null("Health")
				if health and health.has_method("take_damage"):
					health.take_damage(applied_damage, source_ship)
	
	# Hide missile sprite
	if sprite:
		sprite.visible = false
	
	# Disable engine particles
	if engine_particles:
		engine_particles.emitting = false
	
	# Emit hit signal
	emit_signal("hit", null, global_position, -direction)
	
	# Wait for explosion animation to finish before removing
	await get_tree().create_timer(0.5).timeout
	
	# Call parent expire
	expire()

# Helper to find bodies within explosion radius
func _get_bodies_in_radius(radius: float) -> Array:
	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.set_shape(shape)
	query.transform = global_transform
	query.collision_mask = collision_mask
	
	var results = space_state.intersect_shape(query)
	var bodies = []
	
	for result in results:
		if result.collider is PhysicsBody2D or result.collider is Ship:
			bodies.append(result.collider)
	
	return bodies
