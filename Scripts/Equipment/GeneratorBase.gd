extends Equipment
class_name GeneratorBase

# Generator properties
@export var generation_rate: float = 10.0     # Energy per second
@export var efficiency: float = 1.0           # Efficiency multiplier (1.0 = 100%)
@export var is_active: bool = true            # Whether generator is currently working
@export var power_up_time: float = 0.5        # Time in seconds to reach full generation
@export var heat_generation: float = 1.0      # Heat generated per energy unit (if heat system is used)

# Reference to parent ship and capacitor
var ship: Ship
var target_capacitor: CapacitorBase

# Internal state
var current_output_percentage: float = 1.0    # Current output level (0.0 to 1.0)
var power_up_timer: float = 0.0               # Current power-up timer
var malfunction: bool = false                 # If true, generator is malfunctioning
var overload_threshold: float = 1.5           # Multiplier at which generator risks damage if pushed beyond

# Signals
signal output_changed(new_output)
signal generator_status_changed(is_active)
signal generator_overloaded()
signal generator_malfunction(is_malfunctioning)

func _ready() -> void:
	# Find parent ship if not set
	if not ship and get_parent() is Ship:
		ship = get_parent()
	
	# Find target capacitor if not set
	if ship and not target_capacitor:
		for child in ship.get_children():
			if child is CapacitorBase:
				target_capacitor = child
				break

func _process(delta: float) -> void:
	if not is_active or malfunction:
		return
	
	# Handle power up time
	if current_output_percentage < 1.0:
		if power_up_time > 0:
			power_up_timer += delta
			current_output_percentage = min(power_up_timer / power_up_time, 1.0)
			emit_signal("output_changed", current_output_percentage)
		else:
			current_output_percentage = 1.0
			emit_signal("output_changed", current_output_percentage)
	
	# Generate energy
	if target_capacitor:
		var energy_amount = get_energy_output(delta)
		target_capacitor.add_energy(energy_amount)

# Get current energy output per tick
func get_energy_output(delta: float) -> int:
	return floor(generation_rate * efficiency * current_output_percentage * delta)

# Activate or deactivate the generator
func set_active(active: bool) -> void:
	if is_active != active:
		is_active = active
		
		if not is_active:
			current_output_percentage = 0.0
			power_up_timer = 0.0
		
		emit_signal("generator_status_changed", is_active)
		emit_signal("output_changed", current_output_percentage)

# Attempt to boost generator output (can cause malfunctions if pushed too hard)
func boost_output(boost_multiplier: float, duration: float = 1.0) -> bool:
	if not is_active or malfunction:
		return false
	
	# Check if boost would exceed overload threshold
	if boost_multiplier > overload_threshold:
		# Risk of malfunction increases with boost amount
		var malfunction_chance = (boost_multiplier - overload_threshold) / (2.0 - overload_threshold)
		
		if randf() < malfunction_chance:
			_trigger_malfunction()
			return false
	
	# Apply boost temporarily
	var current_efficiency = efficiency
	efficiency *= boost_multiplier
	
	# Reset efficiency after duration
	await get_tree().create_timer(duration).timeout
	
	if is_active:  # Only reset if still active
		efficiency = current_efficiency
	
	return true

# Handle generator malfunction
func _trigger_malfunction() -> void:
	malfunction = true
	is_active = false
	emit_signal("generator_malfunction", true)
	emit_signal("generator_status_changed", is_active)
	emit_signal("generator_overloaded")

# Repair generator
func repair() -> void:
	malfunction = false
	power_up_timer = 0.0
	current_output_percentage = 0.0
	emit_signal("generator_malfunction", false)

# Upgrade generator
func upgrade_generation_rate(new_rate: float) -> void:
	generation_rate = max(0.1, new_rate)

func upgrade_efficiency(new_efficiency: float) -> void:
	efficiency = max(0.1, new_efficiency)
