extends Pilot
class_name Player

var background: Polygon2D
var nebula: Polygon2D
var dust: Polygon2D
var ship: Ship
var camera: Camera2D

# Touch control variables
var touch_positions = {}  # Dictionary to store touch positions
var pinch_distance_start = 0.0  # Starting distance for pinch gesture
var is_pinching = false  # Track if we're currently pinching
var is_touching = false  # Track if we're currently touching
var touch_position = Vector2.ZERO  # Current touch position for ship rotation

func _ready() -> void:
	background = get_node_or_null("Camera2D/Background")
	nebula = get_node_or_null("Camera2D/Nubula")
	dust = get_node_or_null("Camera2D/Dust")
	
	# Make sure input processing is enabled
	set_process_input(true)

func _physics_process(delta: float) -> void:
	# Keep original keyboard controls
	if Input.is_action_pressed("accelerate") and ship:
		ship.accelerate(delta)

	if Input.is_action_just_released("accelerate") and ship:
		ship.accelerate_done()

	if Input.is_action_pressed("rotate_behind") and ship:
		ship.turn_behind(delta)

	if Input.is_action_pressed("rotate_left") and ship:
		ship.turn_left(delta)

	if Input.is_action_pressed("rotate_right") and ship:
		ship.turn_right(delta)

	if Input.is_action_just_released("zoom_in"):
		zoom_in()
	
	if Input.is_action_just_released("zoom_out"):
		zoom_out()
		
	# Handle touch movement - this runs every frame as long as is_touching is true
	if is_touching and ship and !is_pinching:
		# Convert screen touch position to global world position
		var viewport = get_viewport()
		var global_touch_position = get_global_mouse_position()
		
		# Calculate the direction from the ship to the touch position
		var direction = (global_touch_position - ship.global_position).normalized()
		
		# Calculate the target angle the ship needs to face
		var target_angle = direction.angle() + PI/2  # PI/2 offset because ship faces up
		
		# Calculate the smallest angle difference in the range [-PI, PI]
		var angle_diff = wrapf(target_angle - ship.rotation, -PI, PI)
		
		# Rotate ship toward touch position
		if abs(angle_diff) > 0.01:  # Small threshold to prevent jitter
			if angle_diff > 0:
				ship.turn_right(delta)
			else:
				ship.turn_left(delta)
		else:
			# Once we're facing the right direction, accelerate
			ship.accelerate(delta)
		
		# Always accelerate while touching, even if still rotating
		# Uncomment the line below if you want to accelerate regardless of facing direction
		# ship.accelerate(delta)

func _input(event: InputEvent) -> void:
	# Handle touch input events
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Store the touch position
		touch_positions[event.index] = event.position
		
		# If this is the first touch and we're not pinching
		if touch_positions.size() == 1 and !is_pinching:
			is_touching = true
			touch_position = event.position
			# We'll convert to global coordinates in _physics_process
		
		# If this is the second touch, start pinch detection
		elif touch_positions.size() == 2:
			is_touching = false  # Disable single touch while pinching
			is_pinching = true
			
			# Calculate initial pinch distance
			var touch1 = touch_positions.values()[0]
			var touch2 = touch_positions.values()[1]
			pinch_distance_start = touch1.distance_to(touch2)
	else:
		# Touch released
		touch_positions.erase(event.index)
		
		# If we were pinching but now have fewer than 2 touches
		if is_pinching and touch_positions.size() < 2:
			is_pinching = false
			
		# If all touches are released
		if touch_positions.size() == 0:
			is_touching = false
			if ship:
				ship.accelerate_done()

func _handle_drag(event: InputEventScreenDrag) -> void:
	# Update the stored touch position
	touch_positions[event.index] = event.position
	
	# If we're doing a pinch gesture (2 fingers)
	if touch_positions.size() == 2 and is_pinching:
		var touch_keys = touch_positions.keys()
		var touch1 = touch_positions[touch_keys[0]]
		var touch2 = touch_positions[touch_keys[1]]
		
		# Calculate current distance between fingers
		var pinch_distance_current = touch1.distance_to(touch2)
		
		# Check if pinching in or out
		var pinch_difference = pinch_distance_current - pinch_distance_start
		
		# Apply zoom based on pinch
		if abs(pinch_difference) > 10:  # Add a threshold to avoid small movements
			if pinch_difference > 0:
				zoom_in()
			else:
				zoom_out()
				
			# Update the start distance for next check
			pinch_distance_start = pinch_distance_current
	elif touch_positions.size() == 1 and is_touching:
		# Update touch position for ship rotation
		touch_position = event.position
		# We'll convert to global coordinates in _physics_process

func zoom_in() -> void:
	if camera and camera.zoom.x < 1:
		camera.zoom.x += .01
		camera.zoom.y += .01

func zoom_out() -> void:
	if camera and camera.zoom.x > 0.05:
		camera.zoom.x -= .01
		camera.zoom.y -= .01

func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera

func set_ship(new_ship: Ship) -> void:
	ship = new_ship
	print(ship)
