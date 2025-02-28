extends CanvasLayer
class_name Indicator_Manager

# Reference to the camera following the player
var camera: Player_Camera
# Dictionary to store all active indicators by target node
var active_indicators = {}
# Preload the indicator scene
@export var indicator_scene: PackedScene
# Preload default icon texture
@export var default_icon_texture: Texture2D
# Controls how often to scan for new tracked objects (in seconds)
@export var scan_interval: float = 2.0
# Timer for scanning
var scan_timer: float = 0.0

# Tracking settings
@export var track_ships: bool = true
@export var track_celestial_bodies: bool = true
@export var track_only_meta_tagged: bool = false

func _ready():
	# Find the player camera
	camera = find_player_camera()
	# Perform initial scan for tracked objects
	scan_for_tracked_objects()

func _process(delta):
	# Update scan timer
	scan_timer += delta
	if scan_timer >= scan_interval:
		scan_timer = 0
		scan_for_tracked_objects()
	
	# Clean up any invalid indicators
	clean_invalid_indicators()

# Find the player camera in the scene
func find_player_camera() -> Player_Camera:
	var main = get_tree().get_root().get_node_or_null("Main")
	if main and main.has_method("get_camera"):
		return main.get_camera()
	
	# Fallback: search through all nodes
	var cameras = get_tree().get_nodes_in_group("PlayerCamera")
	if cameras.size() > 0:
		return cameras[0]
	
	# Another fallback
	var all_cameras = get_tree().get_nodes_in_group("Camera2D")
	for cam in all_cameras:
		if cam is Player_Camera:
			return cam
	
	push_error("IndicatorManager: Could not find Player_Camera")
	return null

# Scan the scene for objects that should have indicators
func scan_for_tracked_objects():
	if not camera:
		camera = find_player_camera()
		if not camera:
			return
			
	# Get all relevant nodes in the scene
	var track_nodes = []
	
	# Scan for ships
	if track_ships:
		var ships = get_tree().get_nodes_in_group("Ships")
		for ship in ships:
			# Skip player's ship
			if camera.player and camera.player.ship == ship:
				continue
			
			if track_only_meta_tagged:
				if ship.has_meta("Tracked") and ship.get_meta("Tracked"):
					track_nodes.append(ship)
			else:
				track_nodes.append(ship)
				
	# Scan for celestial bodies
	if track_celestial_bodies:
		var bodies = get_tree().get_nodes_in_group("CelestialBodies")
		for body in bodies:
			if track_only_meta_tagged:
				if body.has_meta("Tracked") and body.get_meta("Tracked"):
					track_nodes.append(body)
			else:
				track_nodes.append(body)
	
	# Scan for any object with "Tracked" metadata
	var all_nodes = get_tree().get_nodes_in_group("Tracked")
	for node in all_nodes:
		if node is Node2D and not track_nodes.has(node):
			track_nodes.append(node)
	
	# Create indicators for all tracked nodes
	for node in track_nodes:
		if not active_indicators.has(node):
			create_indicator_for_node(node)

# Create a new indicator for a node
func create_indicator_for_node(node: Node2D):
	if not is_instance_valid(node) or not indicator_scene:
		return
	
	# Create the indicator instance
	var new_indicator = indicator_scene.instantiate()
	add_child(new_indicator)
	
	# Get custom properties from metadata if available
	var icon_texture = default_icon_texture
	var icon_color = Color.WHITE
	var show_distance = true
	
	if node.has_meta("icon_texture"):
		icon_texture = node.get_meta("icon_texture")
	elif node is Ship:
		icon_texture = default_icon_texture # Use ship icon
	elif node is Celestial_Body:
		icon_texture = default_icon_texture # Use planet icon
		
	if node.has_meta("icon_color"):
		icon_color = node.get_meta("icon_color")
	elif node is Ship:
		icon_color = Color(0.2, 0.6, 1.0) # Blue for ships
	elif node is Celestial_Body:
		icon_color = Color(1.0, 0.7, 0.2) # Orange for celestial bodies
		
	if node.has_meta("show_distance"):
		show_distance = node.get_meta("show_distance")
	
	# Initialize the indicator
	new_indicator.initialize(node, camera, icon_texture, icon_color, show_distance)
	
	# Store in our dictionary
	active_indicators[node] = new_indicator

# Remove any indicators whose target nodes no longer exist
func clean_invalid_indicators():
	var to_remove = []
	
	for node in active_indicators:
		if not is_instance_valid(node):
			to_remove.append(node)
			
	for node in to_remove:
		if is_instance_valid(active_indicators[node]):
			active_indicators[node].queue_free()
		active_indicators.erase(node)
