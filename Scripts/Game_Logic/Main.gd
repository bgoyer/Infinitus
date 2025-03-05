extends Node2D

var camera: PlayerCamera


func get_camera() -> PlayerCamera:
		for child in get_children():
			if child is PlayerCamera:
				return child
		return null
		
func get_player() -> Player:
	for game_item in get_children():
		if game_item is Map:
			for map_item in game_item.get_children():
				if map_item is Ship:
					for ship_item in map_item.get_children():
						if ship_item is Player:
							return ship_item
							
	return null
