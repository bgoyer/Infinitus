extends Pilot
class_name Player

# Original player variables
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

# Fleet management variables
var fleet: Fleet = null
var is_fleet_commander: bool = false
var fleet_commander: PlayerFleetCommander = null

# UI feedback
var ui_feedback_timer: float = 0.0
var ui_feedback_duration: float = 2.0
var show_ui_feedback: bool = false
var ui_feedback_text: String = ""

func _ready() -> void:
	# Original Player ready functionality
	background = get_node_or_null("Camera2D/Background")
	nebula = get_node_or_null("Camera2D/Nubula")
	dust = get_node_or_null("Camera2D/Dust")
	
	# Make sure input processing is enabled
	set_process_input(true)
	
	# Fleet command setup if player is a fleet commander
	if is_fleet_commander:
		_setup_fleet_command()

func _physics_process(delta: float) -> void:
	# Original Physics processing
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
	
	# Update UI feedback timer
	if show_ui_feedback:
		ui_feedback_timer += delta
		if ui_feedback_timer >= ui_feedback_duration:
			show_ui_feedback = false
			ui_feedback_timer = 0.0

func _input(event: InputEvent) -> void:
	# Original input handling
	# Handle touch input events
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	
	# Fleet management hotkeys
	if is_fleet_commander and fleet and fleet_commander:
		if event.is_action_pressed("fleet_command_toggle"):
			# Toggle fleet command mode
			fleet_commander.is_command_mode_active = !fleet_commander.is_command_mode_active
			if fleet_commander.is_command_mode_active:
				fleet_commander._activate_command_mode()
			else:
				fleet_commander._deactivate_command_mode()
		
		# Direct fleet commands when not in command mode
		if not fleet_commander.is_command_mode_active:
			if event.is_action_pressed("fleet_follow_me"):
				_command_fleet_follow()
			elif event.is_action_pressed("fleet_hold_position"):
				_command_fleet_hold()
			elif event.is_action_pressed("fleet_attack_target"):
				_command_fleet_attack_target()

# Original methods for touch control
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

# Fleet management methods
func set_as_fleet_commander(new_fleet: Fleet = null) -> void:
	is_fleet_commander = true
	
	if new_fleet:
		fleet = new_fleet
	else:
		# Create a new fleet with this ship as flagship
		fleet = FleetFactory.create_fleet_for_ship(ship, FleetFactory.FleetFaction.PLAYER, 2)
	
	# Set up fleet command if player is already initialized
	if is_inside_tree():
		_setup_fleet_command()

func _setup_fleet_command() -> void:
	# Create fleet commander if needed
	if not fleet_commander:
		fleet_commander = PlayerFleetCommander.new()
		add_child(fleet_commander)
		fleet_commander.set_fleet(fleet)
	
	# Create fleet HUD if it doesn't exist
	var fleet_hud = get_tree().get_nodes_in_group("FleetHUD")
	if fleet_hud.size() == 0:
		# Create HUD
		var hud = load("res://UI/Fleet/FleetHUD.tscn").instantiate()
		add_child(hud)
		hud.set_fleet(fleet)
	
	# Make sure the flagship has this player as pilot
	if fleet and fleet.flagship:
		var flagship_has_player = false
		for child in fleet.flagship.get_children():
			if child is Player:
				flagship_has_player = true
				break
		
		if not flagship_has_player:
			# Remove this player from current ship
			if ship and ship.get_parent():
				ship.remove_child(self)
				
				# Add player to flagship
				fleet.flagship.add_child(self)
				set_ship(fleet.flagship)

# Quick command: Fleet follows player
func _command_fleet_follow() -> void:
	if fleet and fleet_commander:
		fleet.execute_command("form_up")
		show_command_feedback("Following")

# Quick command: Fleet holds position
func _command_fleet_hold() -> void:
	if fleet and fleet_commander:
		# Get current position for holding
		var hold_position = fleet.get_average_position()
		fleet.execute_command("move_to", hold_position)
		show_command_feedback("Holding Position")

# Quick command: Fleet attacks current target
func _command_fleet_attack_target() -> void:
	if fleet and fleet_commander:
		# Find target
		var target = _find_target_in_front()
		
		if target:
			fleet.execute_command("attack", target)
			show_command_feedback("Attacking Target")
		else:
			show_command_feedback("No Target Found")

# Helper to find a target in front of the player
func _find_target_in_front() -> Ship:
	var search_distance = 1000.0
	var search_angle = PI / 4  # 45 degrees each side
	
	# Get player's forward direction
	var forward_direction = -ship.transform.y
	
	# Find all ships
	var ships = get_tree().get_nodes_in_group("Ships")
	var closest_target = null
	var closest_distance = search_distance
	
	for potential_target in ships:
		# Skip own fleet ships
		if fleet and potential_target in fleet.member_ships:
			continue
		
		# Calculate direction and distance to target
		var to_target = potential_target.global_position - ship.global_position
		var distance = to_target.length()
		
		if distance > search_distance:
			continue
		
		# Check if target is in front of player
		var normalized_to_target = to_target.normalized()
		var dot_product = forward_direction.dot(normalized_to_target)
		
		# Target is in front if dot product is positive and within search angle
		if dot_product > cos(search_angle) and distance < closest_distance:
			closest_target = potential_target
			closest_distance = distance
	
	return closest_target

# Handle releasing a ship from the fleet
func release_ship_from_fleet(ship_to_release: Ship) -> void:
	if fleet:
		fleet.remove_ship(ship_to_release)
		show_command_feedback("Ship Released")

# Add ship to player's fleet
func add_ship_to_fleet(ship_to_add: Ship) -> void:
	if fleet:
		fleet.add_ship(ship_to_add)
		show_command_feedback("Ship Added to Fleet")
	else:
		# Create fleet if needed
		set_as_fleet_commander()
		fleet.add_ship(ship_to_add)
		show_command_feedback("Fleet Created")

# Commands to change fleet formation
func set_fleet_formation(formation_type: int) -> void:
	if fleet and fleet.formation_manager:
		fleet.formation_manager.set_formation(formation_type)
		
		# Get formation name for feedback
		var formation_name = "Formation Changed"
		if formation_type == FleetFormationManager.FormationType.LINE:
			formation_name = "Line Formation"
		elif formation_type == FleetFormationManager.FormationType.V_FORMATION:
			formation_name = "V Formation"
		elif formation_type == FleetFormationManager.FormationType.CIRCLE:
			formation_name = "Circle Formation"
		elif formation_type == FleetFormationManager.FormationType.WEDGE:
			formation_name = "Wedge Formation"
		elif formation_type == FleetFormationManager.FormationType.ECHELON:
			formation_name = "Echelon Formation"
		
		show_command_feedback(formation_name)

# UI feedback for fleet commands
func show_command_feedback(text: String) -> void:
	ui_feedback_text = text
	show_ui_feedback = true
	ui_feedback_timer = 0.0

##func _draw() -> void:
	# Draw UI feedback if active
	#if show_ui_feedback:
	#	var font_color = Color(1, 1, 1, 1 - (ui_feedback_timer / ui_feedback_duration))
	#	draw_string(get_font("font", "Label"), Vector2(10, 40), ui_feedback_text, 
	#			   font_color, 400)
