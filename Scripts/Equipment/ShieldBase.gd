extends Equipment
class_name ShieldBase

# Shield properties
@export var max_shield: int = 50
@export var current_shield: int = 50
@export var recharge_rate: float = 5.0        # Shield points per second
@export var recharge_delay: float = 3.0       # Seconds after damage before recharging
@export var energy_drain: float = 1.0         # Energy consumed per second to maintain shields
@export var hit_energy_cost: float = 2.0      # Additional energy consumed when hit (per damage point)

# Special shield properties
@export var projectile_reflection_chance: float = 0.0  # Chance to reflect projectiles
@export var damage_conversion: float = 0.0             # Percentage of damage converted to shield energy

# Visual properties
@export var shield_color: Color = Color(0.3, 0.5, 1.0, 0.7)
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var hit_flash_duration: float = 0.2

# Reference to parent ship and capacitor
var ship: Ship
var capacitor: CapacitorBase

# Internal state
var last_damage_time: float = 0.0
var is_active: bool = true
var visual_shield: Node2D
var hit_flash_timer: float = 0.0

# Signals
signal shield_changed(current, maximum)
signal shield_depleted()
signal shield_recharge_started()
signal shield_hit(damage, position)

func _ready() -> void:
	# Find parent ship if not set
	if not ship and get_parent() is Ship:
		ship = get_parent()
	
	# Find capacitor if not set
	if ship and not capacitor:
		for child in ship.get_children():
			if child is CapacitorBase:
				capacitor = child
				break
	
	# Find or create shield visual
	_setup_shield_visual()
	
	# Initialize shield
	current_shield = max_shield
	emit_signal("shield_changed", current_shield, max_shield)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Handle hit flash effect
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0 and visual_shield:
			visual_shield.modulate = shield_color
	
	# Drain energy to maintain shields
	if capacitor and current_shield > 0:
		var energy_needed = energy_drain * delta
		if not capacitor.drain_energy(ceil(energy_needed)):
			# Not enough energy to maintain shields
			deactivate()
			return
	
	# Handle shield recharging
	var time_since_damage = Time.get_ticks_msec() / 1000.0 - last_damage_time
	
	if current_shield < max_shield and time_since_damage >= recharge_delay:
		var recharge_amount = recharge_rate * delta
		
		# Check if we have enough energy to recharge
		if capacitor and recharge_amount > 0:
			var energy_for_recharge = recharge_amount * 2.0  # Energy cost per shield point
			
			if capacitor.drain_energy(ceil(energy_for_recharge)):
				if current_shield == 0:
					emit_signal("shield_recharge_started")
				
				current_shield = min(current_shield + floor(recharge_amount), max_shield)
				emit_signal("shield_changed", current_shield, max_shield)
				
				# Update shield visibility
				if visual_shield:
					visual_shield.visible = current_shield > 0
					visual_shield.modulate.a = shield_color.a * (float(current_shield) / max_shield)

# Absorb damage and return remaining damage
func absorb_damage(amount: int, position: Vector2 = Vector2.ZERO) -> int:
	if not is_active or current_shield <= 0:
		return amount
	
	# Record damage time for recharge delay
	last_damage_time = Time.get_ticks_msec() / 1000.0
	
	# Calculate energy cost for absorbing hit
	var energy_needed = amount * hit_energy_cost
	var can_absorb_fully = true
	
	# Check if we have enough energy to absorb the hit
	if capacitor and energy_needed > 0:
		can_absorb_fully = capacitor.drain_energy(ceil(energy_needed))
	
	# If we can't fully absorb, shields are less effective
	var effective_amount = amount
	if not can_absorb_fully:
		effective_amount = amount * 2  # Double damage if not enough energy
	
	# Apply damage to shields
	var remaining_damage = 0
	if current_shield >= effective_amount:
		current_shield -= effective_amount
	else:
		remaining_damage = effective_amount - current_shield
		current_shield = 0
	
	# Handle damage conversion to shield energy if applicable
	if damage_conversion > 0 and current_shield > 0:
		var converted_energy = amount * damage_conversion
		current_shield = min(current_shield + converted_energy, max_shield)
	
	# Update shield status
	emit_signal("shield_changed", current_shield, max_shield)
	emit_signal("shield_hit", amount, position)
	
	# Show hit effect
	_show_hit_effect(position)
	
	# Check if shields are depleted
	if current_shield <= 0:
		emit_signal("shield_depleted")
		
		# Update shield visibility
		if visual_shield:
			visual_shield.visible = false
	
	return int(remaining_damage)

# Activate shields
func activate() -> bool:
	if capacitor and capacitor.current_energy <= 0:
		return false
		
	is_active = true
	
	# Make shield visible if we have shield points
	if visual_shield:
		visual_shield.visible = current_shield > 0
	
	return true

# Deactivate shields
func deactivate() -> void:
	is_active = false
	
	# Hide shield visual
	if visual_shield:
		visual_shield.visible = false

# Setup shield visual component
func _setup_shield_visual() -> void:
	visual_shield = get_node_or_null("ShieldVisual")
	
	if not visual_shield:
		visual_shield = Node2D.new()
		visual_shield.name = "ShieldVisual"
		add_child(visual_shield)
		
		# Create shield sprite or particles
		# This is a simplification - you'd likely want a more sophisticated visual
		var shield_sprite = Sprite2D.new()
		#shield_sprite.texture = preload("res://icon.png")  # Replace with actual shield texture
		shield_sprite.scale = Vector2(3, 3)  # Adjust based on ship size
		visual_shield.add_child(shield_sprite)
	
	visual_shield.modulate = shield_color
	visual_shield.visible = current_shield > 0

# Show hit effect on shields
func _show_hit_effect(position: Vector2) -> void:
	if visual_shield:
		visual_shield.modulate = hit_flash_color
		hit_flash_timer = hit_flash_duration
		
		# Could spawn additional particles or effects at hit position

# Set shield color
func set_shield_color(color: Color) -> void:
	shield_color = color
	if visual_shield and hit_flash_timer <= 0:
		visual_shield.modulate = shield_color

# Upgrade shields
func upgrade_max_shield(new_max: int, fill: bool = false) -> void:
	max_shield = new_max
	
	if fill:
		current_shield = max_shield
	else:
		current_shield = min(current_shield, max_shield)
	
	emit_signal("shield_changed", current_shield, max_shield)

func upgrade_recharge_rate(new_rate: float) -> void:
	recharge_rate = new_rate
