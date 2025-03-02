extends Pilot
class_name AI_Pilot

# State machine variables
enum State {IDLE, PATROL, CHASE, ATTACK, FLEE, LAND, WARP_IN, WARP_OUT}
var current_state: int = State.IDLE
var previous_state: int = State.IDLE

# AI attributes
var aggressiveness: float = 0.5  # 0.0 to 1.0, affects flee threshold and attack decisions
var flee_health_threshold: float = 0.25  # Percentage of health that triggers fleeing
var detection_range: float = 1000.0  # How far the AI can detect other ships
var target: Ship = null  # Current target ship
var home_planet: Orbiting_Body = null  # Planet this AI considers "home" for landing
var patrol_points: Array[Vector2] = []  # Points to patrol between
var current_patrol_index: int = 0
var last_state_change_time: float = 0.0
var min_state_duration: float = 1.0  # Minimum time in seconds to stay in a state

# Navigation parameters
var arrive_distance: float = 100.0  # Distance at which we consider "arrived" at a destination
var avoid_distance: float = 200.0  # Distance to start avoiding obstacles
var max_turn_rate: float = 0.1  # Maximum rotation per physics frame
var max_speed: float = 500.0  # Maximum speed for AI navigation

# References
var ship: Ship
var visible_ships: Array[Ship] = []
var visible_planets: Array[Orbiting_Body] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup detection area (we'll need to add an Area2D as a child)
	var detection_area = $DetectionArea
	if detection_area:
		detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_body_exited"))
		# Set the detection range
		var collision_shape = detection_area.get_node("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = detection_range

func _physics_process(delta: float) -> void:
	# Only process if we have a ship
	if not ship:
		return
	
	# Update state machine
	_update_state_machine(delta)
	
	# Process current state
	match current_state:
		State.IDLE:
			_process_idle_state(delta)
		State.PATROL:
			_process_patrol_state(delta)
		State.CHASE:
			_process_chase_state(delta)
		State.ATTACK:
			_process_attack_state(delta)
		State.FLEE:
			_process_flee_state(delta)
		State.LAND:
			_process_land_state(delta)
		State.WARP_IN:
			_process_warp_in_state(delta)
		State.WARP_OUT:
			_process_warp_out_state(delta)

# State machine update logic
func _update_state_machine(delta: float) -> void:
	previous_state = current_state
	
	# Check if enough time has passed in current state before allowing a transition
	if Time.get_ticks_msec() / 1000.0 - last_state_change_time < min_state_duration:
		return
	
	# Default state transitions will be implemented in derived classes
	# Base class only handles general transitions like fleeing when damaged
	
	# Example of a generic transition: flee when health is low
	# This would need to be expanded once you have a health system
	if current_state != State.FLEE and current_state != State.WARP_OUT:
		# Placeholder for health check. Replace with actual health system.
		var health_percentage = 1.0 # Placeholder
		if health_percentage < flee_health_threshold * (1.0 + aggressiveness * 0.5):
			_change_state(State.FLEE)

# Helper to change state with timing
func _change_state(new_state: int) -> void:
	if new_state != current_state:
		previous_state = current_state
		current_state = new_state
		last_state_change_time = Time.get_ticks_msec()
		# You could emit a signal here if needed
		# emit_signal("state_changed", current_state)

# State processing functions
func _process_idle_state(delta: float) -> void:
	# Base implementation: Just stay put
	ship.accelerate_done()

func _process_patrol_state(delta: float) -> void:
	if patrol_points.size() == 0:
		_change_state(State.IDLE)
		return
	
	var target_point = patrol_points[current_patrol_index]
	_navigate_to_position(target_point, delta)
	
	# Check if we've reached the current patrol point
	if global_position.distance_to(target_point) < arrive_distance:
		# Move to the next patrol point
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func _process_chase_state(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_change_state(State.PATROL)
		return
	
	_navigate_to_position(target.global_position, delta)
	
	# Check if we're close enough to attack
	if global_position.distance_to(target.global_position) < 300.0:
		_change_state(State.ATTACK)

func _process_attack_state(delta: float) -> void:
	if not target or not is_instance_valid(target):
		_change_state(State.PATROL)
		return
	
	# Position for attack (keeping some distance)
	var ideal_distance = 200.0
	var current_distance = global_position.distance_to(target.global_position)
	
	if current_distance > ideal_distance * 1.5:
		# Too far, move closer
		_navigate_to_position(target.global_position, delta)
	elif current_distance < ideal_distance * 0.5:
		# Too close, back off
		var away_vector = global_position - target.global_position
		_navigate_to_position(global_position + away_vector.normalized() * 200, delta)
	else:
		# Good range, focus on facing target
		_face_position(target.global_position, delta)
		# Strafe or perform attack maneuvers here
		# For now, we'll just toggle acceleration
		if randf() > 0.95:  # Random acceleration pattern
			ship.accelerate(delta)
		else:
			ship.accelerate_done()
	
	# Here you would trigger weapon firing if implemented

func _process_flee_state(delta: float) -> void:
	# If no threat, go back to patrol
	if not target or not is_instance_valid(target) or global_position.distance_to(target.global_position) > detection_range * 1.5:
		_change_state(State.PATROL)
		return
	
	# Flee away from target
	var flee_direction = (global_position - target.global_position).normalized()
	_navigate_to_position(global_position + flee_direction * 1000, delta)
	
	# If we've fled far enough, maybe warp out
	if global_position.distance_to(target.global_position) > detection_range:
		if randf() < 0.1:  # 10% chance per physics frame to decide to warp out
			_change_state(State.WARP_OUT)

func _process_land_state(delta: float) -> void:
	# Landing not implemented yet, placeholder
	if not home_planet or not is_instance_valid(home_planet):
		_change_state(State.PATROL)
		return
	
	_navigate_to_position(home_planet.global_position, delta)
	
	# Check if we've reached the planet
	if global_position.distance_to(home_planet.global_position) < 100:
		# Placeholder for landing procedure
		# For now, just idle at the planet
		_change_state(State.IDLE)

func _process_warp_in_state(delta: float) -> void:
	# Placeholder for warp in effect
	# Would trigger animations and effects here
	
	# For now, just transition to idle after a delay
	if Time.get_ticks_msec() / 1000.0 - last_state_change_time > 2.0:
		_change_state(State.IDLE)

func _process_warp_out_state(delta: float) -> void:
	# Placeholder for warp out effect
	# Would trigger animations and effects here
	
	# For now, just make the ship "disappear" after a delay
	if Time.get_ticks_msec() / 1000.0 - last_state_change_time > 2.0:
		# This would be replaced with proper cleanup/pooling logic
		ship.queue_free()

# Navigation helper functions
func _navigate_to_position(target_position: Vector2, delta: float) -> void:
	# Face the target
	_face_position(target_position, delta)
	
	# Accelerate if facing approximately the right direction
	var direction_to_target = target_position - global_position
	var facing_direction = -ship.transform.y  # Assuming ship faces -Y direction
	var dot_product = facing_direction.normalized().dot(direction_to_target.normalized())
	
	if dot_product > 0.9:  # Facing approximately the right direction
		ship.accelerate(delta)
	else:
		ship.accelerate_done()

func _face_position(target_position: Vector2, delta: float) -> void:
	var direction_to_target = target_position - global_position
	var angle_to_target = direction_to_target.angle() + PI/2  # Adjust for Godot's 0 angle
	
	# Calculate the smallest angle difference in the range [-PI, PI]
	var angle_diff = wrapf(angle_to_target - ship.rotation, -PI, PI)
	
	# Check if we need to rotate
	if abs(angle_diff) > 0.01:
		if angle_diff > 0:
			ship.turn_right(delta)
		else:
			ship.turn_left(delta)
	else:
		# Already facing the right direction
		pass

# Detection area signal callbacks
func _on_body_entered(body: Node) -> void:
	if body is Ship and body != ship:
		visible_ships.append(body)
	elif body is Orbiting_Body:
		visible_planets.append(body)

func _on_body_exited(body: Node) -> void:
	if body is Ship:
		visible_ships.erase(body)
	elif body is Orbiting_Body:
		visible_planets.erase(body)

# Override from Pilot
func set_ship(new_ship: Ship) -> void:
	ship = new_ship
	# Initialize other AI related data here if needed
