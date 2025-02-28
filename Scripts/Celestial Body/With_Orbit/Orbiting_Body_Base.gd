extends Celestial_Body
class_name Orbiting_Body

# Reference to the star Celestial_Body; if not assigned, defaults to (0, 0)
@export var star: Celestial_Body
# Extra gravity strength applied to other bodies (such as ships)
@export var gravity_strength: float
# Elliptical-ness parameter (eccentricity): 0 = circular, values closer to 1 produce more elliptical orbits
@export var eccentricity: float = 0.0

# Multiplier to control the angular (orbit) speed (radians per second)
@export var orbit_speed_multiplier: float = 1.0

@export var rotation_speed: float = 0
# The current velocity (computed via frame-to-frame position difference)
var velocity: Vector2 = Vector2.ZERO
# Range for detecting other bodies affected by gravity
var gravity_range: float

# Ellipse parameters (semi-major and semi-minor axes)
var A: float
var B: float 

# Time accumulator (for orbital period calculations if needed)
var time_passed: float = 0.0

# List of physics bodies in range (for extra gravitational interactions)
var bodies_in_range: Array[PhysicsBody2D] = []

var speed: float = 0.0
var last_position: Vector2 = Vector2.ZERO

# --- Variables for rotation-based orbit ---
var center: Vector2 = Vector2.ZERO  # The star's position (focus)
var angle: float = 0.0              # Current angle along the orbit (in radians)

# Remove debug print statements in production builds
@export var debug_mode: bool = false

func _ready() -> void:
	# Set the focus to the star's position (or (0,0) if none is assigned)
	center = star.position if star != null else Vector2.ZERO
	# Use the current distance (assumed to be periapsis) to compute ellipse parameters.
	var r: float = position.distance_to(center)
	if r != 0:
		eccentricity = clamp(eccentricity, 0.0, 0.99)
		# In an elliptical orbit, periapsis distance r_peri = A * (1 - eccentricity)
		# So, semi-major axis A is:
		A = r / (1.0 - eccentricity)
		# And the semi-minor axis is:
		B = A * sqrt(1.0 - eccentricity * eccentricity)
		# Set the initial angle to 0 (periapsis)
		angle = 0.0
		position = center + Vector2(A * (cos(angle) - eccentricity), B * sin(angle))
		if debug_mode:
			print("Initial ellipse parameters: A=", A, " B=", B, " eccentricity=", eccentricity)
	else:
		push_error("Warning: Distance from center is zero; cannot compute orbit.")
		
	# Connect signals with the newer syntax for Godot 4.x
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	gravity_range = $Area2D/CollisionShape2D.shape.radius

func _physics_process(delta: float) -> void:
	# Update the center in case the star moves.
	if star:
		center = star.position
	
	# Update the orbit angle using the orbit_speed_multiplier (in radians per second)
	angle += orbit_speed_multiplier / 10000 * delta
	# Update the position along the ellipse with the star at the focus
	position = center + Vector2(A * (cos(angle) - eccentricity), B * sin(angle))
	
	if debug_mode:
		print(position.distance_to(center))
	
	update_speed()
	_apply_gravity(delta)
	time_passed += delta
	rotate((rotation_speed / 360) * delta)


func _on_body_entered(body: Node) -> void:
	if body is PhysicsBody2D:
		bodies_in_range.append(body)

func _on_body_exited(body: Node) -> void:
	if body is PhysicsBody2D:
		bodies_in_range.erase(body)

# Renamed for clarity and to follow Godot naming conventions
func _apply_gravity(delta: float) -> void:
	for body in bodies_in_range:
		if body is Ship:
			if body.locked:
				continue
				
			var body_distance: float = global_position.distance_to(body.global_position)
			var direction = (global_position - body.global_position)
			
			if body_distance > 400:
				body.velocity += direction * (gravity_strength / 5000) * sqrt(body_distance) * delta
			else:
				# Avoid potential division by zero with a small epsilon
				var speed_factor = max(speed, 0.001) / 6
				body.velocity = direction * (body_distance / speed_factor) * delta

func update_speed() -> void:
	if last_position != Vector2.ZERO:
		# Using a weighted average for smoother speed calculations
		var current_speed = global_position.distance_to(last_position)
		speed = (current_speed + speed) / 2.0
	last_position = global_position
