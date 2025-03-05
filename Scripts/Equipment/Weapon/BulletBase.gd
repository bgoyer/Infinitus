extends Projectile
class_name Bullet

# Bullet-specific properties
var bullet_color: Color = Color.WHITE
var trail_length: float = 10.0

func _init() -> void:
	speed = 1000.0  # Bullets are fast
	damage = 10
	max_range = 1500.0
	penetrates = false

func _ready() -> void:
	super._ready()
	
	# Set bullet color if we have a sprite
	if sprite:
		sprite.modulate = bullet_color
		
	# Set up trail if we have particles
	if particles:
		var material = particles.process_material
		if material:
			material.color = bullet_color
			material.emission_box_extents.z = trail_length

# Visual effects when hitting something
func _on_body_entered(body: Node) -> void:
	# Create hit effect
	#var hit_effect = preload("res://Scenes/Effects/BulletHitEffect.tscn").instantiate()
	#get_tree().root.add_child(hit_effect)
	#hit_effect.global_position = global_position
	#hit_effect.rotation = global_rotation
	
	# Handle standard hit behavior
	super._on_body_entered(body)
