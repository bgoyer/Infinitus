extends Equipment
class_name Thruster

## Thruster equipment that provides forward acceleration to ships

# Thruster properties
@export var thrust: int = 10  # Base thrust power
@export var drain: int = 1    # Energy drain per second when active
@export var capacitor_need: int = 1  # Minimum energy required to operate

# Signals
signal thrust_activated()
signal thrust_deactivated()

# Current thruster state
var is_active: bool = false

func _ready() -> void:
	super._ready()
	
	# Default description if none provided
	if description.is_empty():
		description = "A basic thruster that provides forward acceleration."

## Activate the thruster
func activate() -> bool:
	if not is_active and equipped_ship != null:
		# Check if the ship has enough energy
		if equipped_ship.has_method("has_energy") and not equipped_ship.has_energy(capacitor_need):
			return false
		
		is_active = true
		emit_signal("thrust_activated")
		return true
	return false

## Deactivate the thruster
func deactivate() -> void:
	if is_active:
		is_active = false
		emit_signal("thrust_deactivated")

## Process energy consumption (called from ship)
func process_energy_consumption(delta: float) -> int:
	if is_active:
		return ceil(drain * delta)
	return 0

## Get the current thrust power, potentially affected by conditions
func get_current_thrust() -> float:
	# Base implementation just returns the thrust value
	# Override in child classes to implement thrust modifications
	return thrust
