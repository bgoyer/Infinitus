extends Node
class_name Pilot

var actions = {
	Turn = false,
	Accelerate = false,
	Turn_Behind = false
}

func is_pilot_available() -> bool:
	if get_node_or_null("Pilot") == null:
		return false
	else:
		return true
