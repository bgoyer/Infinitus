extends Equipment
class_name ArmorBase

# Armor properties
@export var armor_rating: int = 10            # Base damage reduction
@export var current_integrity: float = 100.0  # Current armor integrity percentage
@export var damage_threshold: int = 5         # Damage below this amount is negated completely
@export var max_absorption: float = 0.8       # Maximum percentage of damage that can be absorbed

# Damage type resistances (multipliers, lower is better)
@export var kinetic_resistance: float = 1.0   # Standard projectiles
@export var energy_resistance: float = 1.0    # Lasers, plasma
@export var explosive_resistance: float = 1.0 # Missiles, bombs
@export var thermal_resistance: float = 1.0   # Heat-based weapons

# Reference to parent ship
var ship: Ship

# Signals
signal armor_damaged(current_integrity)
signal armor_breached()

# Enum for damage types
enum DamageType {KINETIC, ENERGY, EXPLOSIVE, THERMAL}

func _ready() -> void:
	# Find parent ship if not set
	if not ship and get_parent() is Ship:
		ship = get_parent()

# Absorb damage and return remaining damage
func absorb_damage(amount: int, damage_type: int = DamageType.KINETIC) -> int:
	# No absorption if armor is breached
	if current_integrity <= 0:
		return amount
	
	# Apply damage threshold
	if amount <= damage_threshold:
		return 0  # Completely absorbed
	
	# Get resistance for this damage type
	var resistance = _get_resistance_for_type(damage_type)
	
	# Calculate damage after resistance and armor
	var effective_armor = armor_rating * (current_integrity / 100.0)
	var damage_reduction = min(effective_armor / resistance, amount * max_absorption)
	var remaining_damage = max(amount - damage_reduction, 0)
	
	# Damage the armor itself
	_damage_armor(amount * 0.1)  # Armor takes 10% of incoming damage to itself
	
	return int(remaining_damage)

# Damage the armor itself
func _damage_armor(amount: float) -> void:
	var previous_integrity = current_integrity
	current_integrity = max(0.0, current_integrity - amount)
	
	emit_signal("armor_damaged", current_integrity)
	
	# Check if armor was just breached
	if previous_integrity > 0 and current_integrity <= 0:
		emit_signal("armor_breached")

# Get the appropriate resistance for the damage type
func _get_resistance_for_type(damage_type: int) -> float:
	match damage_type:
		DamageType.KINETIC:
			return kinetic_resistance
		DamageType.ENERGY:
			return energy_resistance
		DamageType.EXPLOSIVE:
			return explosive_resistance
		DamageType.THERMAL:
			return thermal_resistance
		_:
			return 1.0  # Default resistance

# Repair the armor
func repair(amount: float) -> void:
	current_integrity = min(100.0, current_integrity + amount)
	emit_signal("armor_damaged", current_integrity)  # Reuse signal for updates

# Get current armor effectiveness
func get_current_effectiveness() -> float:
	return armor_rating * (current_integrity / 100.0)

# Upgrade armor
func upgrade_armor(new_rating: int) -> void:
	armor_rating = max(1, new_rating)
	
# Upgrade damage threshold
func upgrade_threshold(new_threshold: int) -> void:
	damage_threshold = max(0, new_threshold)
