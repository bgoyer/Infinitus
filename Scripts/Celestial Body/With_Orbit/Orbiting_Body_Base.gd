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
# In a realistic Keplerian ellipse, the star is at one focus.
# We assume here that the star (focus) is at center (0,0) of our coordinate system.
# The parametric equations (with focus at the origin) are:
#   x = A * (cos(angle) - eccentricity)
#   y = B * sin(angle)
var center: Vector2 = Vector2.ZERO  # The star's position (focus)
var angle: float = 0.0              # Current angle along the orbit (in radians)

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
		# Set the initial angle to 0 (periapsis). Then the planet's position is:
		# x = A * (cos(0) - eccentricity) = A * (1 - eccentricity)
		# y = B * sin(0) = 0
		angle = 0.0
		position = center + Vector2(A * (cos(angle) - eccentricity), B * sin(angle))
		print("Initial ellipse parameters: A=", A, " B=", B, " eccentricity=", eccentricity)
	else:
		print("Warning: Distance from center is zero; cannot compute orbit.")
		
	$Area2D.connect("body_entered", Callable(self, "on_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "on_body_exited"))
	gravity_range = $Area2D/CollisionShape2D.shape.radius

func _physics_process(delta: float) -> void:
	# Update the center in case the star moves.
	center = star.position if star != null else Vector2.ZERO
	# Update the orbit angle using the orbit_speed_multiplier (in radians per second)
	angle += orbit_speed_multiplier / 10000 * delta
	# Update the position along the ellipse with the star at the focus:
	# x = A*(cos(angle) - eccentricity), y = B*sin(angle)
	position = center + Vector2(A * (cos(angle) - eccentricity), B * sin(angle))
	print(position.distance_to(center))
	# For compatibility with extra gravity functions, compute r and direction.
	var r: float = position.distance_to(center)
	var direction: Vector2 = (center - position).normalized()
	
	update_speed()
	gravity_tick(delta)
	time_passed += delta

func on_body_entered(body: Node) -> void:
	if body is PhysicsBody2D:
		bodies_in_range.append(body)

func on_body_exited(body: Node) -> void:
	if body is PhysicsBody2D:
		bodies_in_range.erase(body)

func gravity_tick(delta: float) -> void:
	for body in bodies_in_range:
		var body_distance: float = global_position.distance_to(body.global_position)
		if body is Ship:
			if body.locked:
				return
			if body_distance > 400:
				body.velocity += (global_position - body.global_position) * (gravity_strength / 1000) * delta
			else:
				body.velocity = (global_position - body.global_position) * (body_distance / (speed / 6)) * delta

func update_speed() -> void:
	if last_position != Vector2.ZERO:
		speed = ((global_position - last_position).length() + speed) / 2.0
	last_position = global_position
