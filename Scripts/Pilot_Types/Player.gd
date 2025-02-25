extends Pilot
class_name Player

var background: Polygon2D
var nebula: Polygon2D
var dust: Polygon2D
var ship: Ship
var camera: Camera2D


func _ready() -> void:
	background = get_node_or_null("Camera2D/Background")
	nebula = get_node_or_null("Camera2D/Nubula")
	dust = get_node_or_null("Camera2D/Dust")

func _physics_process(delta: float) -> void:
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
		if camera.zoom.x < 1:
			camera.zoom.x += .01
			camera.zoom.y += .01
	
	if Input.is_action_just_released("zoom_out"):
		if camera.zoom.x > 0.05:
			camera.zoom.x -= .01
			camera.zoom.y -= .01


func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera

func set_ship(new_ship: Ship) -> void:
	ship = new_ship
	print(ship)
