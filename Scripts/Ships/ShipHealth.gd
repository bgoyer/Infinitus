extends Node
class_name ShipHealth

# Health properties
@export var max_health: int = 100
@export var current_health: int = 100
@export var armor: int = 0  # Reduces incoming damage
@export var shield_max: int = 0  # Optional shield system
@export var shield_current: int = 0
@export var shield_recharge_rate: float = 5.0  # Per second
@export var shield_recharge_delay: float = 3.0  # Seconds after damage before recharging
@export var damage_effects: bool = true  # Whether to show damage effects

# References
var ship: Ship
var damage_particles: GPUParticles2D
var shield_visual: Node2D
var last_damage_time: float = 0.0

# Signals
signal health_changed(new_health, max_health)
signal shield_changed(new_shield, max_shield)
signal damage_taken(amount, source, hitpoint)
signal ship_destroyed()

func _ready() -> void:
	ship = get_parent() if get_parent() is Ship else null
	damage_particles = $DamageParticles if has_node("DamageParticles") else null
	shield_visual = $ShieldVisual if has_node("ShieldVisual") else null
	
	# Initialize health
	current_health = max_health
	shield_current = shield_max
	
	# Update visuals
	_update_damage_visuals()

func _process(delta: float) -> void:
	# Handle shield recharging
	if shield_max > 0 and shield_current < shield_max:
		var time_since_damage = Time.get_ticks_msec() / 1000.0 - last_damage_time
		
		if time_since_damage >= shield_recharge_delay:
			shield_current = min(shield_current + shield_recharge_rate * delta, shield_max)
			emit_signal("shield_changed", shield_current, shield_max)
			
			# Update shield visual if available
			if shield_visual:
				shield_visual.visible = shield_current > 0
				shield_visual.modulate.a = shield_current / shield_max

# Take damage from an attack
func take_damage(amount: int, source: Node = null, hit_position: Vector2 = Vector2.ZERO) -> void:
	var actual_damage = amount
	
	# Record time of damage for shield recharge delay
	last_damage_time = Time.get_ticks_msec() / 1000.0
	
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
		if shield_visual:
			shield_visual.visible = shield_current > 0
			shield_visual.modulate.a = shield_current / shield_max
			
			# Optional shield hit effect
			#var shield_hit = preload("res://Scenes/Effects/ShieldHitEffect.tscn").instantiate()
			#get_tree().root.add_child(shield_hit)
			#shield_hit.global_position = hit_position if hit_position != Vector2.ZERO else global_position
	
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
		
		# Spawn hit effect
		#if damage_effects:
			#var hit_effect = preload("res://Scenes/Effects/HullHitEffect.tscn").instantiate()
			#get_tree().root.add_child(hit_effect)
			#hit_effect.global_position = hit_position if hit_position != Vector2.ZERO else global_position
		
		# Check if ship is destroyed
		if current_health <= 0:
			_handle_destruction()

# Update ship appearance based on damage state
func _update_damage_visuals() -> void:
	if not damage_effects:
		return
		
	var damage_ratio = 1.0 - (float(current_health) / max_health)
	
	# Update damage particles if available
	if damage_particles:
		damage_particles.emitting = damage_ratio > 0.5
		var emission_rate = damage_particles.amount * (damage_ratio - 0.5) * 2.0
		
		# Access particle properties - adjust to match your particle system
		if damage_particles.process_material:
			var material = damage_particles.process_material
			if material is ParticleProcessMaterial:
				material.emission_sphere_radius = 10.0 + damage_ratio * 20.0
				
		# Increase particle visibility as damage increases
		damage_particles.modulate.a = min(damage_ratio * 2.0, 1.0)
	
	# Update ship sprite if available
	if ship and ship.has_node("Sprite2D"):
		var sprite = ship.get_node("Sprite2D")
		
		# Optional: Add damage textures based on damage level
		if damage_ratio > 0.75:
			if ResourceLoader.exists("res://Assets/Ships/DamagedHeavy.png"):
				sprite.texture = load("res://Assets/Ships/DamagedHeavy.png")
		elif damage_ratio > 0.4:
			if ResourceLoader.exists("res://Assets/Ships/DamagedMedium.png"):
				sprite.texture = load("res://Assets/Ships/DamagedMedium.png")
		elif damage_ratio > 0.1:
			if ResourceLoader.exists("res://Assets/Ships/DamagedLight.png"):
				sprite.texture = load("res://Assets/Ships/DamagedLight.png")

# Handle ship destruction
func _handle_destruction() -> void:
	emit_signal("ship_destroyed")
	
	# Create explosion effect
	#var explosion = preload("res://Scenes/Effects/ShipExplosion.tscn").instantiate()
	#get_tree().root.add_child(explosion)
	#explosion.global_position = global_position
	#explosion.rotation = global_rotation
	
	# Optionally spawn debris
	#_spawn_debris()
	
	# Remove the ship
	if ship:
		ship.queue_free()

# Spawn ship debris on destruction
#func _spawn_debris() -> void:
	#if not damage_effects:
		#return
		#
	#var debris_count = randi_range(5, 10)
	#var debris_scene = preload("res://Scenes/Effects/ShipDebris.tscn")
	#
	#for i in range(debris_count):
		#var debris = debris_scene.instantiate()
		#get_tree().root.add_child(debris)
		#debris.global_position = global_position
		#
		## Randomize debris velocity and rotation
		#var angle = randf_range(0, 2 * PI)
		#var speed = randf_range(50, 150)
		#debris.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
		#debris.angular_velocity = randf_range(-PI, PI)

# Repair the ship
func repair(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)
	
	# Update visuals
	_update_damage_visuals()

# Recharge shields
func recharge_shield(amount: int) -> void:
	if shield_max > 0:
		shield_current = min(shield_current + amount, shield_max)
		emit_signal("shield_changed", shield_current, shield_max)
		
		# Update shield visual
		if shield_visual:
			shield_visual.visible = shield_current > 0
			shield_visual.modulate.a = shield_current / shield_max

# Full repair and recharge
func restore_full() -> void:
	current_health = max_health
	shield_current = shield_max
	
	emit_signal("health_changed", current_health, max_health)
	emit_signal("shield_changed", shield_current, shield_max)
	
	_update_damage_visuals()
