extends Node
class_name ShipEnergy

## Energy management system for ships
## Handles energy storage, consumption, and regeneration

# Energy properties
@export var max_energy: int = 100
@export var current_energy: int = 100
@export var recharge_rate: float = 10.0  # Energy per second
@export var weapon_efficiency: float = 1.0  # Multiplier for weapon energy cost (lower = more efficient)
@export var thruster_efficiency: float = 1.0  # Multiplier for thruster energy cost

# Energy thresholds
@export var energy_critical_threshold: float = 0.2  # Percentage where energy is considered critical

# State tracking
var energy_low_warning: bool = false

# References
var ship: Ship

# Signals
signal energy_changed(new_energy, max_energy)
signal energy_depleted()
signal energy_critical(is_critical)
signal energy_consumption(amount, source)

func _ready() -> void:
	# Get reference to the ship
	ship = get_parent() if get_parent() is Ship else null
	
	# Initialize energy
	current_energy = max_energy
	emit_signal("energy_changed", current_energy, max_energy)

func _process(delta: float) -> void:
	# Recharge energy
	if current_energy < max_energy:
		var new_energy = min(current_energy + recharge_rate * delta, max_energy)
		
		if new_energy != current_energy:
			current_energy = new_energy
			emit_signal("energy_changed", current_energy, max_energy)
			
			# Check if we're no longer in critical state
			if energy_low_warning and current_energy > max_energy * energy_critical_threshold:
				energy_low_warning = false
				emit_signal("energy_critical", false)

## Check if ship has enough energy
func has_energy(amount: int) -> bool:
	return current_energy >= amount

## Consume energy for an action
## Returns true if energy was successfully consumed
func consume_energy(amount: float, source: String = "unknown") -> bool:
	# Apply appropriate efficiency based on source
	var actual_amount = amount
	match source:
		"weapon":
			actual_amount = ceil(amount * weapon_efficiency)
		"thruster":
			actual_amount = ceil(amount * thruster_efficiency)
	
	# Check if we have enough energy
	if current_energy < actual_amount:
		emit_signal("energy_depleted")
		return false
	
	# Consume the energy
	current_energy -= actual_amount
	emit_signal("energy_changed", current_energy, max_energy)
	emit_signal("energy_consumption", actual_amount, source)
	
	# Check if energy is now critical
	if not energy_low_warning and current_energy <= max_energy * energy_critical_threshold:
		energy_low_warning = true
		emit_signal("energy_critical", true)
	
	return true

## Add energy (from pickups, etc.)
func add_energy(amount: int) -> void:
	current_energy = min(current_energy + amount, max_energy)
	emit_signal("energy_changed", current_energy, max_energy)
	
	# Check if we're no longer critical
	if energy_low_warning and current_energy > max_energy * energy_critical_threshold:
		energy_low_warning = false
		emit_signal("energy_critical", false)

## Get current energy percentage
func get_energy_percentage() -> float:
	return float(current_energy) / max_energy

## Set max energy (for upgrades)
func set_max_energy(new_max: int, fill: bool = false) -> void:
	max_energy = new_max
	
	if fill:
		current_energy = max_energy
	else:
		current_energy = min(current_energy, max_energy)
	
	emit_signal("energy_changed", current_energy, max_energy)

## Set recharge rate (for upgrades)
func set_recharge_rate(new_rate: float) -> void:
	recharge_rate = new_rate

## Set efficiency (for upgrades)
func set_weapon_efficiency(new_efficiency: float) -> void:
	weapon_efficiency = new_efficiency

## Set thruster efficiency (for upgrades)
func set_thruster_efficiency(new_efficiency: float) -> void:
	thruster_efficiency = new_efficiency
