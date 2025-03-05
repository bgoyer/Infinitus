extends Weapon
class_name Gun

# Gun-specific properties
var spread_angle: float = 0.0  # Cone of fire in degrees

func _init() -> void:
	weapon_name = "Fixed Gun"
	auto_target = false  # Guns don't auto-target


func _spawn_projectile() -> void:
	# Get the weapon's forward direction (adjusted for ship rotation)
	var forward_direction = -global_transform.y.normalized()
	
	# Apply spread/inaccuracy if configured
	if spread_angle > 0 and accuracy < 1.0:
		var max_deviation = deg_to_rad(spread_angle) * (1.0 - accuracy)
		var random_angle = randf_range(-max_deviation, max_deviation)
		forward_direction = forward_direction.rotated(random_angle)
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Set projectile properties
	projectile.global_position = muzzle_position.global_position
	projectile.global_rotation = global_rotation
	projectile.direction = forward_direction
	projectile.speed = projectile_speed
	projectile.damage = damage
	projectile.source_weapon = self
	projectile.source_ship = equipped_ship
	projectile.max_range = range_distance
	
	emit_signal("weapon_fired", projectile)
	
	# If ship has energy system, consume energy
	if equipped_ship and equipped_ship.has_method("consume_energy"):
		equipped_ship.consume_energy(energy_cost)

# Gun only fires forward, so no special targeting needed
func fire() -> bool:
	return super.fire()
