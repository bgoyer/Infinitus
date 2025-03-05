extends Equipment
class_name CapacitorBase

# Capacitor properties
@export var max_capacity: int = 100
@export var current_energy: int = 100
@export var discharge_efficiency: float = 1.0  # How efficiently energy is used (1.0 = 100%)
@export var recharge_efficiency: float = 1.0   # How efficiently energy is stored (1.0 = 100%)
@export var discharge_rate_limit: float = 50.0 # Maximum energy per second that can be discharged

# Reference to parent ship
var ship: Ship

# Signals
signal capacity_changed(new_capacity)
signal energy_changed(new_energy, max_capacity)
signal energy_depleted()
signal energy_critical(is_critical)

# Critical energy threshold (percentage)
var energy_critical_threshold: float = 0.2
var energy_critical_state: bool = false

func _ready() -> void:
	# Initialize with full energy by default
	current_energy = max_capacity
	
	# Find parent ship if not set
	if not ship and get_parent() is Ship:
		ship = get_parent()
	
	# Emit initial signals
	emit_signal("energy_changed", current_energy, max_capacity)

# Check if capacitor has enough energy
func has_energy(amount: int) -> bool:
	return current_energy >= amount

# Drain energy from the capacitor
func drain_energy(amount: int, source: String = "unknown") -> bool:
	# Apply discharge efficiency
	var actual_amount = ceil(amount / discharge_efficiency)
	
	# Check if we have enough energy
	if current_energy < actual_amount:
		emit_signal("energy_depleted")
		return false
	
	# Consume the energy
	current_energy -= actual_amount
	emit_signal("energy_changed", current_energy, max_capacity)
	
	# Check if energy is now critical
	var was_critical = energy_critical_state
	energy_critical_state = current_energy <= max_capacity * energy_critical_threshold
	
	if energy_critical_state != was_critical:
		emit_signal("energy_critical", energy_critical_state)
	
	return true

# Add energy to the capacitor
func add_energy(amount: int) -> int:
	# Apply recharge efficiency
	var actual_amount = floor(amount * recharge_efficiency)
	
	# Calculate how much energy was actually added (accounting for max capacity)
	var energy_before = current_energy
	current_energy = min(current_energy + actual_amount, max_capacity)
	var energy_added = current_energy - energy_before
	
	emit_signal("energy_changed", current_energy, max_capacity)
	
	# Check if we're no longer critical
	var was_critical = energy_critical_state
	energy_critical_state = current_energy <= max_capacity * energy_critical_threshold
	
	if energy_critical_state != was_critical:
		emit_signal("energy_critical", energy_critical_state)
	
	return energy_added

# Set new maximum capacity (for upgrades)
func set_max_capacity(new_capacity: int, fill: bool = false) -> void:
	max_capacity = max(1, new_capacity)
	
	if fill:
		current_energy = max_capacity
	else:
		current_energy = min(current_energy, max_capacity)
	
	emit_signal("capacity_changed", max_capacity)
	emit_signal("energy_changed", current_energy, max_capacity)

# Get current energy percentage
func get_energy_percentage() -> float:
	return float(current_energy) / max_capacity
