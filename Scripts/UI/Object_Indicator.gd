extends Control
class_name Object_Indicator

# The target node this indicator is tracking
var target_node: Node2D
# Reference to the viewport size
var viewport_size: Vector2
# Reference to the camera following the player
var camera: Camera2D
# Visual elements
#@onready var icon = $Icon
@onready var label = $Label
# Appearance settings
var icon_color: Color = Color.WHITE
var distance_display: bool = true
var icon_texture: Texture2D
# Max tracking distance (0 = unlimited)
var max_tracking_distance: float = 0
# Padding from screen edge
var edge_padding: float = 50.0
# Reference to the screen notifier if available
var screen_notifier: VisibleOnScreenNotifier2D

func _ready():
	get_viewport().size_changed.connect(update_viewport_size)
	# Set initial properties
#	if icon_texture:
#		icon.texture = icon_texture

func initialize(target: Node2D, cam: Camera2D, texture: Texture2D = null, color: Color = Color.WHITE, show_distance: bool = true):
	target_node = target
	camera = cam
	viewport_size = get_viewport_rect().size
	icon_color = color
	distance_display = show_distance
	icon_texture = texture
	
	# Set icon properties
#	icon.modulate = icon_color
#	if icon_texture:
#		icon.texture = icon_texture
	
	# Set label properties based on target
	if target_node.has_meta("indicator_name"):
		label.text = target_node.get_meta("indicator_name")
	else:
		label.text = target_node.name
	
	# Check for max tracking distance
	if target_node.has_meta("max_tracking_distance"):
		max_tracking_distance = target_node.get_meta("max_tracking_distance")
	await get_tree().create_timer(0.1).timeout
	# Try to find a screen notifier on the target
	for child in target_node.get_children():
		if child is VisibleOnScreenNotifier2D:
			screen_notifier = child
			print(child)
			screen_notifier.screen_entered.connect(_on_screen_entered)
			screen_notifier.screen_exited.connect(_on_screen_exited)
			break

func _process(_delta):
	if not is_instance_valid(target_node) or not is_instance_valid(camera):
		queue_free()
		return
	
	var distance = camera.global_position.distance_to(target_node.global_position)
	
	# Check max tracking distance
	if max_tracking_distance > 0 and distance > max_tracking_distance:
		visible = false
		return
	
	# If we have a screen notifier, use it to determine visibility
	if screen_notifier and screen_notifier.is_on_screen():
		visible = false
		return
		
	update_position()
	update_distance_text(distance)

# Calculate the position along the screen edge
func update_position():
	# Get the camera's global transform
	var camera_position = camera.global_position
	var camera_zoom = camera.zoom
	
	# Convert target's position to screen coordinates
	var target_position = target_node.global_position
	var screen_center = viewport_size / 2
	
	# Calculate direction from camera to target in screen space
	var direction = (target_position - camera_position)
	
	# Scale direction by zoom (a crucial step)
	direction = direction / camera_zoom
	
	# Calculate screen bounds accounting for zoom
	var half_width = viewport_size.x / 2
	var half_height = viewport_size.y / 2
	
	# Check if target is within screen bounds
	if abs(direction.x) < half_width and abs(direction.y) < half_height:
		# Target is on screen - use screen notifier or hide indicator
		if not screen_notifier:
			visible = false
		return
	else:
		# Target is off screen - show indicator
		visible = true
	
	# Calculate the position on screen edge
	var edge_position = Vector2.ZERO
	
	# Normalize the direction for easier calculations
	var normalized_dir = direction.normalized()
	
	# Calculate the intersection point with the screen rectangle
	var scale_x = half_width / max(abs(normalized_dir.x), 0.001)
	var scale_y = half_height / max(abs(normalized_dir.y), 0.001)
	var scale = min(scale_x, scale_y)
	
	edge_position = normalized_dir * scale
	
	# Apply padding from screen edge
	if abs(edge_position.x) >= half_width - edge_padding:
		edge_position.x = (half_width - edge_padding) * sign(edge_position.x)
	if abs(edge_position.y) >= half_height - edge_padding:
		edge_position.y = (half_height - edge_padding) * sign(edge_position.y)
	
	# Rotate the icon to point toward the target
	var angle = direction.angle()
#	icon.rotation = angle
	
	# Position the indicator at the calculated edge position
	position = screen_center + edge_position
	
	# Make the label readable by keeping it upright
#	label.rotation = -icon.rotation
	
func update_distance_text(distance: float):
	if distance_display and is_instance_valid(target_node):
		var name_text = target_node.get_meta("indicator_name") if target_node.has_meta("indicator_name") else target_node.name
		# Format distance to be more readable (no decimal places)
		label.text = name_text + "\n" + str(int(distance)) + " units"
	elif not distance_display and target_node.has_meta("indicator_name"):
		label.text = str(target_node.get_meta("indicator_name"))
	else:
		label.text = target_node.name
func update_viewport_size():
	viewport_size = get_viewport_rect().size
# Signal callbacks for screen notifier
func _on_screen_entered():
	visible = false

func _on_screen_exited():
	visible = true
