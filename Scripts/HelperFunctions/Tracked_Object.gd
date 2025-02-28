extends Node
class_name Tracked_Object

# This is a helper mixin script you can add to any objects you want tracked

@export var tracked: bool = true
@export var indicator_name: String = ""
@export var indicator_color: Color = Color.WHITE
@export var show_distance: bool = true
@export var custom_icon: Texture2D
@export var max_tracking_distance: float = 0  # 0 = unlimited

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
