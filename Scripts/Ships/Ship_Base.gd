extends Node
class_name Ship




func accelerate() -> void:
	pass

func turn_left() -> void:
	pass

func turn_right() -> void:
	pass

func turn_behind() -> void:
	pass

func is_equipment_installed(installed_equipment: Array[Equipment], equip_type) -> bool:
	for equip in installed_equipment:
		if equip.is_instance(equip_type.get_class()):
			return true
	return false
