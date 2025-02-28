extends Control
class_name Object_Indicator

# The target node this indicator is tracking
var target_node: Node2D
# Reference to the viewport size
var viewport_size: Vector2
# Reference to the camera following the player
var camera: Camera2D
# Visual elements
@onready var icon = $Icon
@onready var label = $Label
# Appearance settings
var icon_color: Color = Color.WHITE
var distance_display: bool = true
var icon_texture: Texture2D

func _ready():
	# Set initial properties
	if icon_texture:
		icon.texture = icon_texture

func initialize(target: Node2D, cam: Camera2D, texture: Texture2D = null, color: Color = Color.WHITE, show_distance: bool = true):
	target_node = target
	camera = cam
	viewport_size = get_viewport_rect().size
	icon_color = color
	distance_display = show_distance
	icon_texture = texture
	
	# Set icon properties
	icon.modulate = icon_color
	if icon_texture:
		icon.texture = icon_texture
	
	# Set label properties based on target
	if target_node.has_meta("indicator_name"):
		label.text = target_node.get_meta("indicator_name")
	else:
		label.text = target_node.name

func _process(_delta):
	if not is_instance_valid(target_node) or not is_instance_valid(camera):
		queue_free()
		return
		
	update_position()
	update_distance_text()

# Calculate the position along the screen edge
func update_position():
	# Get the camera's global transform
	var camera_position = camera.global_position
	var camera_zoom = camera.zoom
	
	# Convert target's position to screen coordinates
	var target_position = target_node.global_position
	var screen_center = viewport_size / 2
	
	# Calculate direction from camera to target in screen space
	var direction = (target_position - camera_position) / camera_zoom
	
	# Check if target is within screen bounds
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2
	
	if abs(direction.x) < half_width and abs(direction.y) < half_height:
		# Target is on screen - hide indicator
		visible = false
		return
	else:
		# Target is off screen - show indicator
		visible = true
	
	# Calculate the position on screen edge
	var edge_position = Vector2.ZERO
	
	# Calculate the slope
	var slope = direction.y / direction.x if direction.x != 0 else 1000000
	
	# Determine screen intersection based on slope
	if abs(slope) * half_width > half_height:
		# Intersection with top/bottom edge
		edge_position.y = half_height * sign(direction.y)
		edge_position.x = direction.x / abs(direction.y) * half_height
	else:
		# Intersection with left/right edge
		edge_position.x = half_width * sign(direction.x)
		edge_position.y = direction.y / abs(direction.x) * half_width
	
	# Apply padding from screen edge (10 pixels)
	var padding = 10
	if abs(edge_position.x) >= half_width - 1:
		edge_position.x = (half_width - padding) * sign(edge_position.x)
	if abs(edge_position.y) >= half_height - 1:
		edge_position.y = (half_height - padding) * sign(edge_position.y)
	
	# Rotate the icon to point toward the target
	var angle = direction.angle()
	icon.rotation = angle
	
	# Position the indicator at the calculated edge position
	position = screen_center + edge_position
	
func update_distance_text():
	if distance_display and is_instance_valid(camera) and is_instance_valid(target_node):
		# Calculate distance to target
		var distance = camera.global_position.distance_to(target_node.global_position)
		label.text = str(target_node.get_meta("indicator_name") if target_node.has_meta("indicator_name") else target_node.name) + "\n" + str(int(distance)) + " units"
	elif not distance_display and target_node.has_meta("indicator_name"):
		label.text = str(target_node.get_meta("indicator_name"))
	else:
		label.text = target_node.name
