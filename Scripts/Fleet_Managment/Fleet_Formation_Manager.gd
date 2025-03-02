extends Node
class_name FleetFormationManager

# Available formation types
enum FormationType {
	LINE,
	V_FORMATION,
	CIRCLE,
	SQUARE,
	WEDGE,
	ECHELON,
	CUSTOM
}

# Current formation
var current_formation: int = FormationType.V_FORMATION
# Spacing between ships in formation
var ship_spacing: float = 200.0
# Custom formation points (if using CUSTOM formation)
var custom_formation_points: Array[Vector2] = []
# Smoothing factor for formation movement (0-1, higher = smoother)
var formation_smoothing: float = 0.1
# Current target positions for all ships in the fleet (ship instance -> position)
var target_positions: Dictionary = {}

func update_formation_positions(fleet: Fleet, delta: float) -> void:
	# Skip if no flagship
	if not fleet.flagship:
		return
	
	# Calculate target positions based on current formation
	calculate_formation_positions(fleet)
	
	# Update ship movement towards formation positions
	for ship in fleet.member_ships:
		if ship == fleet.flagship:
			continue
		
		if target_positions.has(ship):
			# Get the target position for this ship
			var target_pos = target_positions[ship]
			
			# Move ship towards its formation position
			move_ship_to_formation_position(ship, target_pos, delta)

func calculate_formation_positions(fleet: Fleet) -> void:
	var flagship = fleet.flagship
	if not flagship:
		return
	
	var ships = fleet.member_ships
	
	# Clear current target positions
	target_positions.clear()
	
	# Apply the current formation
	match current_formation:
		FormationType.LINE:
			_apply_line_formation(fleet, flagship, ships)
		FormationType.V_FORMATION:
			_apply_v_formation(fleet, flagship, ships)
		FormationType.CIRCLE:
			_apply_circle_formation(fleet, flagship, ships)
		FormationType.SQUARE:
			_apply_square_formation(fleet, flagship, ships)
		FormationType.WEDGE:
			_apply_wedge_formation(fleet, flagship, ships)
		FormationType.ECHELON:
			_apply_echelon_formation(fleet, flagship, ships)
		FormationType.CUSTOM:
			_apply_custom_formation(fleet, flagship, ships)

func move_ship_to_formation_position(ship: Ship, target_pos: Vector2, delta: float) -> void:
	# Calculate the needed rotation to face the target position
	var direction = target_pos - ship.global_position
	var target_angle = direction.angle() + PI/2  # Adjust based on ship's forward direction
	
	# Calculate the smallest angle difference
	var angle_diff = wrapf(target_angle - ship.rotation, -PI, PI)
	
	# Get ship's pilot (if any)
	var pilot = ship.pilot
	if not pilot:
		return
	
	# Get distance to target position
	var distance = ship.global_position.distance_to(target_pos)
	
	# Allow slight position variance (prevents jitter)
	var position_tolerance = 20.0
	
	# If we're far from position, turn and move towards it
	if distance > position_tolerance:
		# Rotate towards target
		if abs(angle_diff) > 0.1:  # Rotation tolerance
			if angle_diff > 0:
				ship.turn_right(delta)
			else:
				ship.turn_left(delta)
		else:
			# We're facing approximately the right direction, accelerate
			ship.accelerate(delta)
	else:
		# Match flagship's rotation once in position
		var flagship_angle = ship.get_meta("fleet").flagship.rotation
		angle_diff = wrapf(flagship_angle - ship.rotation, -PI, PI)
		
		if abs(angle_diff) > 0.1:
			if angle_diff > 0:
				ship.turn_right(delta * 0.5)  # Slower rotation when in position
			else:
				ship.turn_left(delta * 0.5)
		else:
			# We've reached our position, stop accelerating
			ship.accelerate_done()

# Formation implementation methods
func _apply_line_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	var direction = -flagship.transform.y  # Forward direction
	var right = flagship.transform.x       # Right direction
	
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		var position_offset = Vector2.ZERO
		if i % 2 == 0:  # Even index - position on right
			position_offset = right * ship_spacing * (i / 2 + 1)
		else:  # Odd index - position on left
			position_offset = -right * ship_spacing * ((i + 1) / 2)
		
		# Store target position for this ship
		target_positions[ship] = flagship.global_position + position_offset

func _apply_v_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	var forward = -flagship.transform.y  # Forward direction
	var right = flagship.transform.x     # Right direction
	
	# Flagship is at the point of the V
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		var position_offset = Vector2.ZERO
		var ship_index = 0
		
		# Find index excluding flagship
		for j in range(ships.size()):
			if ships[j] != flagship:
				if ships[j] == ship:
					break
				ship_index += 1
		
		if ship_index % 2 == 0:  # Right wing
			position_offset = (right * ship_spacing + forward * ship_spacing) * (ship_index / 2 + 1)
		else:  # Left wing
			position_offset = (-right * ship_spacing + forward * ship_spacing) * ((ship_index + 1) / 2)
		
		# Store target position for this ship
		target_positions[ship] = flagship.global_position + position_offset

func _apply_circle_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	var center = flagship.global_position
	var ship_count = ships.size()
	
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		# Calculate angle for this ship (distribute evenly around the circle)
		var angle = 2 * PI * i / ship_count
		
		# Calculate position offset from center
		var offset = Vector2(cos(angle), sin(angle)) * ship_spacing
		
		# Store target position for this ship
		target_positions[ship] = center + offset

func _apply_square_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	var center = flagship.global_position
	var forward = -flagship.transform.y
	var right = flagship.transform.x
	
	# Flagship at center of square
	var positions = [
		center + right * ship_spacing + forward * ship_spacing,    # Top-right
		center - right * ship_spacing + forward * ship_spacing,    # Top-left
		center - right * ship_spacing - forward * ship_spacing,    # Bottom-left
		center + right * ship_spacing - forward * ship_spacing     # Bottom-right
	]
	
	# Add more positions if needed by expanding the square
	var current_ring = 1
	while positions.size() < ships.size() - 1:  # -1 for flagship
		current_ring += 1
		var ring_spacing = ship_spacing * current_ring
		
		# Add top and bottom rows
		for x in range(-current_ring, current_ring + 1):
			positions.append(center + right * (x * ship_spacing) + forward * ring_spacing)
			positions.append(center + right * (x * ship_spacing) - forward * ring_spacing)
		
		# Add left and right columns (excluding corners already added)
		for y in range(-current_ring + 1, current_ring):
			positions.append(center + right * ring_spacing + forward * (y * ship_spacing))
			positions.append(center - right * ring_spacing + forward * (y * ship_spacing))
	
	# Assign positions to ships
	var pos_index = 0
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		if pos_index < positions.size():
			target_positions[ship] = positions[pos_index]
			pos_index += 1

func _apply_wedge_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	var forward = -flagship.transform.y
	var right = flagship.transform.x
	
	# Flagship at front of wedge
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		var position_offset = Vector2.ZERO
		var ship_index = 0
		
		# Find index excluding flagship
		for j in range(ships.size()):
			if ships[j] != flagship:
				if ships[j] == ship:
					break
				ship_index += 1
		
		var row = ship_index / 2
		var col = ship_index % 2
		
		# Each row moves back and expands outward
		if col == 0:  # Right side
			position_offset = right * ship_spacing * (row + 1) + forward * ship_spacing * (row + 1)
		else:  # Left side
			position_offset = -right * ship_spacing * (row + 1) + forward * ship_spacing * (row + 1)
		
		# Store target position for this ship
		target_positions[ship] = flagship.global_position + position_offset

func _apply_echelon_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	var forward = -flagship.transform.y
	var right = flagship.transform.x
	
	# Flagship at front-right of formation
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		# Calculate position - each ship is behind and to the left of the one in front
		var ship_index = 0
		for j in range(ships.size()):
			if ships[j] != flagship:
				if ships[j] == ship:
					break
				ship_index += 1
		
		var position_offset = (-right * ship_spacing - forward * ship_spacing) * (ship_index + 1)
		
		# Store target position for this ship
		target_positions[ship] = flagship.global_position + position_offset

func _apply_custom_formation(fleet: Fleet, flagship: Ship, ships: Array) -> void:
	# Use custom formation points if available
	if custom_formation_points.size() == 0:
		# Fallback to V formation if no custom points
		_apply_v_formation(fleet, flagship, ships)
		return
	
	var flagship_pos = flagship.global_position
	var flagship_forward = -flagship.transform.y
	var flagship_right = flagship.transform.x
	
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == flagship:
			continue
		
		var point_index = i - 1  # -1 to skip flagship
		if point_index < custom_formation_points.size():
			var local_offset = custom_formation_points[point_index]
			
			# Transform local offset to global position based on flagship orientation
			var global_offset = flagship_forward * local_offset.y + flagship_right * local_offset.x
			
			# Store target position for this ship
			target_positions[ship] = flagship_pos + global_offset
		else:
			# If we run out of custom points, position in a circle
			var angle = 2 * PI * i / ships.size()
			var offset = Vector2(cos(angle), sin(angle)) * ship_spacing
			target_positions[ship] = flagship_pos + offset

func set_formation(formation_type: int) -> void:
	current_formation = formation_type

func set_spacing(spacing: float) -> void:
	ship_spacing = max(50.0, spacing)  # Enforce minimum spacing

func set_custom_formation(points: Array[Vector2]) -> void:
	custom_formation_points = points
	current_formation = FormationType.CUSTOM
