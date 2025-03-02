extends CanvasLayer
class_name IndicatorManager

# Reference to the camera following the player
var camera: PlayerCamera
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

# Dictionary to store tracked groups for optimization
var tracked_groups = {
	"Ships": [],
	"CelestialBodies": [],
	"Tracked": []
}

func _ready():
	# Find the player camera
	camera = find_player_camera()
	
	# Connect signals to track when nodes are added/removed from groups
	get_tree().connect("node_added", Callable(self, "_on_node_added"))
	get_tree().connect("node_removed", Callable(self, "_on_node_removed"))
	
	# Perform initial scan for tracked objects
	call_deferred("scan_for_tracked_objects")

func _process(delta):
	# Update scan timer
	scan_timer += delta
	if scan_timer >= scan_interval:
		scan_timer = 0
		scan_for_tracked_objects()
	
	# Clean up any invalid indicators
	clean_invalid_indicators()

# Find the player camera in the scene
func find_player_camera() -> PlayerCamera:
	if get_viewport().get_camera_2d():
		return get_viewport().get_camera_2d()
	
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
		tracked_groups["Ships"] = ships
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
		tracked_groups["CelestialBodies"] = bodies
		for body in bodies:
			if track_only_meta_tagged:
				if body.has_meta("Tracked") and body.get_meta("Tracked"):
					track_nodes.append(body)
			else:
				track_nodes.append(body)
	
	# Scan for any object with "Tracked" metadata
	var all_nodes = get_tree().get_nodes_in_group("Tracked")
	tracked_groups["Tracked"] = all_nodes
	for node in all_nodes:
		if node is Node2D and not track_nodes.has(node):
			track_nodes.append(node)
	
	# Create indicators for all tracked nodes
	for node in track_nodes:
		if not active_indicators.has(node):
			create_indicator_for_node(node)
	
	# Remove indicators for nodes that are no longer tracked
	var nodes_to_remove = []
	for node in active_indicators.keys():
		if not track_nodes.has(node):
			nodes_to_remove.append(node)
	
	for node in nodes_to_remove:
		remove_indicator_for_node(node)

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
	elif node is CelestialBody:
		icon_texture = default_icon_texture # Use planet icon
		
	if node.has_meta("icon_color"):
		icon_color = node.get_meta("icon_color")
	elif node is Ship:
		# Color code different ship types
		var is_pirate = false
		var is_police = false
		var is_trader = false
		
		for child in node.get_children():
			if child is PiratePilot:
				is_pirate = true
				break
			elif child is PolicePilot:
				is_police = true
				break
			elif child is TraderPilot:
				is_trader = true
				break
		
		if is_pirate:
			icon_color = Color(1.0, 0.2, 0.2) # Red for pirates
		elif is_police:
			icon_color = Color(0.2, 0.2, 1.0) # Blue for police
		elif is_trader:
			icon_color = Color(0.2, 1.0, 0.2) # Green for traders
		else:
			icon_color = Color(0.2, 0.6, 1.0) # Default blue for other ships
	elif node is CelestialBody:
		icon_color = Color(1.0, 0.7, 0.2) # Orange for celestial bodies
		
	if node.has_meta("show_distance"):
		show_distance = node.get_meta("show_distance")
	
	# Initialize the indicator
	new_indicator.initialize(node, camera, icon_texture, icon_color, show_distance)
	
	# Store in our dictionary
	active_indicators[node] = new_indicator

# Remove an indicator for a node
func remove_indicator_for_node(node: Node2D):
	if active_indicators.has(node) and is_instance_valid(active_indicators[node]):
		active_indicators[node].queue_free()
	active_indicators.erase(node)

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

# Handle nodes added to the scene
func _on_node_added(node: Node):
	# Only process 2D nodes
	if not node is Node2D:
		return
		
	# Check if this node should be tracked
	var should_track = false
	
	if node.is_in_group("Ships") and track_ships:
		if not track_only_meta_tagged or (node.has_meta("Tracked") and node.get_meta("Tracked")):
			should_track = true
	
	if node.is_in_group("CelestialBodies") and track_celestial_bodies:
		if not track_only_meta_tagged or (node.has_meta("Tracked") and node.get_meta("Tracked")):
			should_track = true
	
	if node.is_in_group("Tracked"):
		should_track = true
	
	# If this node should be tracked and doesn't have an indicator yet, create one
	if should_track and not active_indicators.has(node):
		create_indicator_for_node(node)

# Handle nodes removed from the scene
func _on_node_removed(node: Node):
	# If this node has an indicator, remove it
	if active_indicators.has(node):
		remove_indicator_for_node(node)

# Add a node to tracking manually
func add_tracked_node(node: Node2D):
	if not active_indicators.has(node):
		create_indicator_for_node(node)

# Remove a node from tracking manually
func remove_tracked_node(node: Node2D):
	if active_indicators.has(node):
		remove_indicator_for_node(node)
