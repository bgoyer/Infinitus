extends Equipment
class_name Turning

## Turning equipment that provides rotation capabilities to ships

# Turning properties
@export var thrust: int = 4    # Angular thrust power (rotational speed)
@export var drain: int = 1     # Energy drain per second when active
@export var capacitor_need: int = 1  # Minimum energy required to operate

# Signals
signal turning_activated(direction)
signal turning_deactivated()

# Current turning state
var is_active: bool = false
var direction: int = 0  # -1 for left, 1 for right, 0 for inactive

func _ready() -> void:
	super._ready()
	
	# Default description if none provided
	if description.is_empty():
		description = "A basic turning mechanism that provides rotational control."

## Activate turning in a direction (-1 = left, 1 = right)
func activate(turn_direction: int) -> bool:
	if equipped_ship != null:
		# Check if the ship has enough energy
		if equipped_ship.has_method("has_energy") and not equipped_ship.has_energy(capacitor_need):
			return false
		
		direction = sign(turn_direction)  # Ensure we only get -1, 0, or 1
		
		if direction != 0:
			is_active = true
			emit_signal("turning_activated", direction)
			return true
	
	return false

## Deactivate turning
func deactivate() -> void:
	if is_active:
		is_active = false
		direction = 0
		emit_signal("turning_deactivated")

## Process energy consumption (called from ship)
func process_energy_consumption(delta: float) -> int:
	if is_active:
		return ceil(drain * delta)
	return 0

## Get the current turning power, potentially affected by conditions
func get_current_thrust() -> float:
	# Base implementation just returns the thrust value
	# Override in child classes to implement thrust modifications
	return thrust * direction
