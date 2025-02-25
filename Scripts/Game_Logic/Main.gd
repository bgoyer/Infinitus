extends Node2D

var camera: Player_Camera

func _ready() -> void:
	camera = get_camera()
	load_scene()

func load_scene() -> void:
	camera.set_player(get_player())

func get_camera() -> Player_Camera:
		for child in get_children():
			if child is Player_Camera:
				return child
		return null
		
func get_player() -> Player:
	for game_item in get_children():
		if game_item is Map:
			for map_item in game_item.get_children():
				if map_item is Ship:
					for ship_item in map_item.get_children():
						if ship_item is Player:
							ship_item.set_ship(map_item)
							return ship_item
							
	return null
