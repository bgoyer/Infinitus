extends Camera2D
class_name Player_Camera

var player
var background: Polygon2D
var nebula: Polygon2D
var dust: Polygon2D

func _ready() -> void:
	background = $Background
	nebula = $Nubula
	dust = $Dust

func _process(delta: float) -> void:
	if player:
		global_position = player.global_position
	if background:
		background.texture_offset = self.position / 8000

	if nebula:
		nebula.texture_offset = self.position / 1500
		
	if nebula:
		dust.texture_offset = self.position / 55

func set_player(new_player: Player):
	player = new_player
	player.set_camera(self)
