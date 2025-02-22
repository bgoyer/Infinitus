extends Ship
var installed_equipment: Array[Equipment] = []
var Test: Thruster

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Alive")
	Test = Thruster.new()
	installed_equipment.append(Test)
	print(is_equipment_installed(installed_equipment, Thruster))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
