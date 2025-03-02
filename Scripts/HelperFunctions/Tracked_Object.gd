extends Node
class_name TrackedObject

# This is a helper mixin script you can add to any objects you want tracked

@export var tracked: bool = true
@export var indicator_name: String = ""
@export var indicator_color: Color = Color.WHITE
@export var show_distance: bool = true
@export var custom_icon: Texture2D
@export var max_tracking_distance: float = 0  # 0 = unlimited
@export var add_screen_notifier: bool = true
@export var screen_notifier_size: Vector2 = Vector2(100, 100)

func _ready():
	# Add to tracked group if enabled
	if tracked:
		get_parent().add_to_group("Tracked")
	
	# Set metadata on parent
	get_parent().set_meta("Tracked", tracked)
	
	if indicator_name != "":
		get_parent().set_meta("indicator_name", indicator_name)
	else:
		get_parent().set_meta("indicator_name", get_parent().name)
		
	get_parent().set_meta("icon_color", indicator_color)
	get_parent().set_meta("show_distance", show_distance)
	
	if custom_icon:
		get_parent().set_meta("icon_texture", custom_icon)
		
	if max_tracking_distance > 0:
		get_parent().set_meta("max_tracking_distance", max_tracking_distance)
	
	# Add screen notifier if enabled
	if add_screen_notifier:
		create_screen_notifier(screen_notifier_size)

# Creates and adds a VisibleOnScreenNotifier2D to the parent
func create_screen_notifier(rect_size: Vector2 = Vector2(100, 100)) -> VisibleOnScreenNotifier2D:
	# Check if parent already has a screen notifier
	for child in get_parent().get_children():
		if child is VisibleOnScreenNotifier2D:
			return child
	
	# Create a new screen notifier
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-rect_size/2, rect_size)
	notifier.name = "ScreenNotifier"
	
	# Add it to the parent
	get_parent().add_child.call_deferred(notifier)
	
	return notifier

# Updates tracking settings at runtime
func update_tracking_settings(new_name: String = "", new_color: Color = Color.WHITE, 
							  new_show_distance: bool = true, new_max_distance: float = 0) -> void:
	if new_name != "":
		indicator_name = new_name
		get_parent().set_meta("indicator_name", indicator_name)
	
	indicator_color = new_color
	get_parent().set_meta("icon_color", indicator_color)
	
	show_distance = new_show_distance
	get_parent().set_meta("show_distance", show_distance)
	
	max_tracking_distance = new_max_distance
	get_parent().set_meta("max_tracking_distance", max_tracking_distance)

# Enables or disables tracking at runtime
func set_tracked(enable: bool) -> void:
	tracked = enable
	get_parent().set_meta("Tracked", tracked)
	
	if tracked:
		get_parent().add_to_group("Tracked")
	else:
		if get_parent().is_in_group("Tracked"):
			get_parent().remove_from_group("Tracked")

# Adjusts the screen notifier size
func update_screen_notifier_size(new_size: Vector2) -> void:
	screen_notifier_size = get_tree().root.get_node("Sprite2D").get_size()
	
	# Find existing notifier
	for child in get_parent().get_children():
		if child is VisibleOnScreenNotifier2D:
			child.rect = Rect2(-new_size/2, new_size)
			return
	
	# If no notifier exists yet, create one
	if add_screen_notifier:
		create_screen_notifier(screen_notifier_size)
