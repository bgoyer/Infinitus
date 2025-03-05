extends Node
class_name ShipHealth

## Health management system for ships
## Handles damage, shields, and destruction

# Health properties
@export var max_health: int = 100
@export var current_health: int = 100
@export var armor: int = 0  # Reduces incoming damage

# Shield properties
@export var shield_max: int = 0  # Optional shield system
@export var shield_current: int = 0
@export var shield_recharge_rate: float = 5.0  # Per second
@export var shield_recharge_delay: float = 3.0  # Seconds after damage before recharging

# Visual settings
@export var damage_effects: bool = true  # Whether to show damage effects

# State tracking
var last_damage_time: float = 0.0
var is_invulnerable: bool = false

# Node references
@onready var ship: Ship = get_parent() if get_parent() is Ship else null
@onready var damage_particles: GPUParticles2D = $DamageParticles if has_node("DamageParticles") else null
@onready var shield_visual: Node2D = $ShieldVisual if has_node("ShieldVisual") else null

# Signals
signal health_changed(new_health, max_health)
signal shield_changed(new_shield, max_shield)
signal damage_taken(amount, source, hitpoint)
signal ship_destroyed()

func _ready() -> void:
	# Initialize health
	current_health = max_health
	shield_current = shield_max
	
	# Update visuals
	_update_damage_visuals()
	
	# Show shield if active
	if shield_visual != null:
		shield_visual.visible = shield_current > 0

func _process(delta: float) -> void:
	# Handle shield recharging
	if shield_max > 0 and shield_current < shield_max:
		var time_since_damage = Time.get_ticks_msec() / 1000.0 - last_damage_time
		
		if time_since_damage >= shield_recharge_delay:
			var new_shield = min(shield_current + shield_recharge_rate * delta, shield_max)
			
			if new_shield != shield_current:
				shield_current = new_shield
				emit_signal("shield_changed", shield_current, shield_max)
				
				# Update shield visual if available
				if shield_visual != null:
					shield_visual.visible = shield_current > 0
					shield_visual.modulate.a = shield_current / float(shield_max)

## Take damage from an attack
func take_damage(amount: int, source: Node = null, hit_position: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable:
		return
		
	# Record time of damage for shield recharge delay
	last_damage_time = Time.get_ticks_msec() / 1000.0
	
	var actual_damage = amount
	
	# Apply to shields first if available
	if shield_current > 0:
		if shield_current >= actual_damage:
			shield_current -= actual_damage
			actual_damage = 0
		else:
			actual_damage -= shield_current
			shield_current = 0
			
		emit_signal("shield_changed", shield_current, shield_max)
		
		# Update shield visual
		if shield_visual != null:
			shield_visual.visible = shield_current > 0
			shield_visual.modulate.a = shield_current / float(shield_max)
			
			# Shield hit effect would go here
	
	# If there's still damage to apply
	if actual_damage > 0:
		# Apply armor reduction
		actual_damage = max(actual_damage - armor, 1)
		
		# Apply to health
		current_health = max(current_health - actual_damage, 0)
		emit_signal("health_changed", current_health, max_health)
		emit_signal("damage_taken", actual_damage, source, hit_position)
		
		# Update damage visuals
		_update_damage_visuals()
		
		# Check if ship is destroyed
		if current_health <= 0:
			_handle_destruction()

## Update ship appearance based on damage state
func _update_damage_visuals() -> void:
	if not damage_effects:
		return
		
	var damage_ratio = 1.0 - (float(current_health) / max_health)
	
	# Update damage particles if available
	if damage_particles != null:
		damage_particles.emitting = damage_ratio > 0.5
		
		# Update particle properties based on damage
		if damage_particles.emitting:
			# Increase particle visibility as damage increases
			damage_particles.modulate.a = min(damage_ratio * 2.0, 1.0)
	
	# Update ship sprite if available
	if ship != null and ship.has_node("Sprite2D"):
		var sprite = ship.get_node("Sprite2D")
		
		# Change sprite appearance based on damage
		if damage_ratio > 0.75:
			# Heavy damage visual
			sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
		elif damage_ratio > 0.4:
			# Medium damage visual
			sprite.modulate = Color(1.0, 0.7, 0.7, 1.0)
		else:
			# Normal or light damage
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

## Handle ship destruction
func _handle_destruction() -> void:
	emit_signal("ship_destroyed")
	
	# Create explosion effect
	_spawn_explosion()
	
	# Remove the ship (with a small delay to allow effects to play)
	if ship != null:
		# Prevent further damage
		is_invulnerable = true
		
		# Make ship non-interactive
		if ship.get("collision_layer") != null:
			ship.collision_layer = 0
			ship.collision_mask = 0
		
		# Queue for deletion after a short delay
		await get_tree().create_timer(0.2).timeout
		ship.queue_free()

## Spawn explosion effect
func _spawn_explosion() -> void:
	if not ship or not damage_effects:
		return
		
	# Placeholder - actual implementation would spawn an explosion scene
	print("Ship destroyed: ", ship.name)
	
	# Simple visual feedback
	if ship.has_node("Sprite2D"):
		var sprite = ship.get_node("Sprite2D")
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0, 0, 0), 0.5)

## Repair the ship
func repair(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)
	
	# Update visuals
	_update_damage_visuals()

## Recharge shields
func recharge_shield(amount: int) -> void:
	if shield_max > 0:
		shield_current = min(shield_current + amount, shield_max)
		emit_signal("shield_changed", shield_current, shield_max)
		
		# Update shield visual
		if shield_visual != null:
			shield_visual.visible = shield_current > 0
			shield_visual.modulate.a = shield_current / float(shield_max)

## Full repair and recharge
func restore_full() -> void:
	current_health = max_health
	shield_current = shield_max
	
	emit_signal("health_changed", current_health, max_health)
	emit_signal("shield_changed", shield_current, shield_max)
	
	_update_damage_visuals()
	
	# Update shield visual
	if shield_visual != null:
		shield_visual.visible = shield_current > 0
		shield_visual.modulate.a = 1.0

## Set invulnerability state
func set_invulnerable(invulnerable: bool) -> void:
	is_invulnerable = invulnerable
