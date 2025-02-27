extends CharacterBody2D
class_name Ship

var thruster: Thruster
var turning: Turning
var locked: bool = false
var pilot: Pilot
var max_velocity: float = 1000 # Default value

# Cache these components for better performance
var _thruster_cached: bool = false
var _turning_cached: bool = false

func _ready() -> void:
	pilot = set_pilot_or_null()
	# Cache components at initialization
	thruster = get_thruster()
	turning = get_turning()
	_thruster_cached = thruster != null
	_turning_cached = turning != null
	
func _physics_process(delta: float) -> void:
	# Add velocity dampening when not under thrust to simulate space friction
	# This helps prevent ships from drifting endlessly at high speeds
	if not locked and velocity.length() > 0:
		velocity *= 0.995
	move_and_slide()

func accelerate(delta: float) -> void:
	if locked == false:
		locked = true
	
	if not _thruster_cached:
		thruster = get_thruster()
		_thruster_cached = thruster != null
	
	if _thruster_cached:
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
