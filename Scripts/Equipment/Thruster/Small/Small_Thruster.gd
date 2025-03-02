extends Thruster
class_name SmallThruster

func _init() -> void:
	description = "A small thruster. Typically used in frigates and destroyers"
	mass = 100
	equipment_name = "Small Thruster"
	value = 100
	volume = 10
	thrust = 25
	drain = 1
	capcitor_need = 1
