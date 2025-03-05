extends Node2D
class_name Equipment

## Base class for all equipment that can be installed on ships
## Equipment includes thrusters, turning mechanisms, weapons, etc.

# Basic equipment properties
@export var description: String = "Basic equipment item"
@export var mass: int = 1
@export var equipment_name: String = "Generic Equipment"
@export var value: int = 10
@export var volume: int = 1

# Signal for when equipment is installed or removed
signal equipment_installed(ship)
signal equipment_removed(ship)

# Reference to the ship this equipment is installed on
var equipped_ship: Ship = null

func _ready() -> void:
	# Check if we're directly under a ship and register automatically
	var parent = get_parent()
	if parent is Ship:
		_register_with_ship(parent)

func _exit_tree() -> void:
	# Clean up when removed from scene tree
	if equipped_ship != null:
		_unregister_from_ship()

## Spawn the equipment into the world (if applicable)
## Override in child classes if needed
func spawn(_position: Vector2) -> void:
	pass

## Called when equipment is installed on a ship
func install(ship: Ship) -> void:
	if equipped_ship != null and equipped_ship != ship:
		# Already equipped on another ship, unregister first
		_unregister_from_ship()
	
	equipped_ship = ship
	emit_signal("equipment_installed", ship)

## Called when equipment is removed from a ship
func uninstall() -> void:
	if equipped_ship != null:
		_unregister_from_ship()
		emit_signal("equipment_removed", equipped_ship)
		equipped_ship = null

## Internal method to register with a ship
func _register_with_ship(ship: Ship) -> void:
	equipped_ship = ship
	emit_signal("equipment_installed", ship)

## Internal method to unregister from a ship
func _unregister_from_ship() -> void:
	emit_signal("equipment_removed", equipped_ship)
