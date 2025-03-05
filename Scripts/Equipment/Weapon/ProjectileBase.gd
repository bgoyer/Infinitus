extends Node2D
class_name Projectile

# Base projectile properties
var speed: float = 800.0
var damage: int = 10
var direction: Vector2 = Vector2.UP
var max_range: float = 1000.0
var distance_traveled: float = 0.0
var source_weapon: Weapon
var source_ship: Ship
var penetrates: bool = false
var hit_objects: Array = []


# Visual nodes
var sprite: Sprite2D
var particles: GPUParticles2D


# Signals
signal hit(object, position, normal)
signal expired

func _ready() -> void:
	# Connect signal for collision detection
	$CollisionArea.body_entered.connect(_on_body_entered)
	
	# Get component references
	sprite = $Sprite2D
	if has_node("Particles"):
		particles = $Particles
	
	# Add to projectiles group for potential optimizations
	add_to_group("Projectiles")

func _physics_process(delta: float) -> void:
	# Move projectile
	position += direction * speed * delta
	
	# Update distance traveled
	distance_traveled += speed * delta
	
	# Check if we've exceeded max range
	if distance_traveled >= max_range:
		expire()

# Called when the projectile hits something
func _on_body_entered(body: Node) -> void:
	# Skip if already hit this object (for penetrating projectiles)
	if penetrates and body in hit_objects:
		return
	
	# Skip collisions with source ship
	if body == source_ship:
		return
	
	# Add to hit objects list
	hit_objects.append(body)
	
	# Calculate hit position and normal
	var hit_position = global_position
	var hit_normal = -direction
	
	# Apply damage if the body has health
	apply_damage(body)
	
	# Emit hit signal
	emit_signal("hit", body, hit_position, hit_normal)
	
	# If not penetrating, expire on first hit
	if not penetrates:
		expire()

# Apply damage to the hit object
func apply_damage(body: Node) -> void:
	# Check if body has health component or method
	if body.has_method("take_damage"):
		body.take_damage(damage, source_ship)
	elif body is Ship:
		# If it's a ship but doesn't have take_damage method,
		# try to find a health component
		var health = body.get_node_or_null("Health")
		if health and health.has_method("take_damage"):
			health.take_damage(damage, source_ship)

# Called when the projectile expires (out of range or hit something)
func expire() -> void:
	emit_signal("expired")
	queue_free()
