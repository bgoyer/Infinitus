extends Camera2D
class_name PlayerCamera

var player
var background: Polygon2D
var nebula_level_1: Polygon2D
var nebula_level_2: Polygon2D
var nebula_level_3: Polygon2D
var dust: Polygon2D

func _ready() -> void:
	background = $Background
	nebula_level_1 = $Nubula_Level_1
	nebula_level_2 = $Nubula_Level_2
	nebula_level_3 = $Nubula_Level_3
	dust = $Dust

func _process(delta: float) -> void:
	if player:
		global_position = player.global_position
	if background:
		background.texture_offset = Vector2(0, 0) + (self.position / 2000)

	if nebula_level_3:
		nebula_level_3.texture_offset = Vector2(25, 90) + (self.position / 1500)

	if nebula_level_2:
		nebula_level_2.texture_offset = Vector2(106, -53) + (self.position / 1250)

	if nebula_level_1:
		nebula_level_1.texture_offset = Vector2(-49, 354) + (self.position / 750)
		
	if dust:
		dust.texture_offset = Vector2(0, 0) + (self.position / 55)

func set_player(new_player: Player):
	player = new_player
	player.set_camera(self)
