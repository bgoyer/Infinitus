extends Node
var actions = {
	Turn = false,
	Accelerate = false,
	
}
var background: Polygon2D
var nebula: Polygon2D

func _ready() -> void:
	background = get_node_or_null("Camera2D/Background")
	nebula = get_node_or_null("Camera2D/Nubula")
	

func _process(delta: float) -> void:
	if Input.is_action_pressed("accelerate") and is_pilot_available():
		pass

	if Input.is_action_pressed("rotate_behind") and is_pilot_available():
		print("Continue")

	if Input.is_action_pressed("rotate_left") and is_pilot_available():
		print("Continue")

	if Input.is_action_pressed("rotate_right") and is_pilot_available():
		print("Continue")

	background.texture_offset = self.position / 10
	nebula.texture_offset = self.position / 15
	

func is_pilot_available() -> bool:
	if get_node_or_null("Pilot") == null:
		return false
	else:
		return true
