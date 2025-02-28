extends AI_Pilot
class_name Police_Pilot

# Police-specific variables
var patrol_radius: float = 5000.0  # Radius around center to patrol
var patrol_center: Vector2 = Vector2.ZERO  # Center of patrol area
var patrol_seed: int = 0  # Seed for generating patrol points
var patrol_count: int = 5  # Number of patrol points
var last_scan_time: float = 0.0
var scan_interval: float = 2.0  # Time between scans for threats
var aggro_timer: float = 0.0  # Time tracking for aggression reset
var aggro_timeout: float = 30.0  # How long to stay aggressive toward a target
var protecting: Ship = null  # Ship currently being protected

func _ready() -> void:
	# Setup police-specific parameters
	aggressiveness = 0.7  # Police are quite aggressive 
	flee_health_threshold = 0.3  # Police retreat only when seriously damaged
	detection_range = 2000.0  # Police have good scanners
	
	# Start by warping in or patrolling
	if randf() > 0.5:
		_change_state(State.WARP_IN)
	else:
		_generate_patrol_points()
		_change_state(State.PATROL)
	
	# Call parent _ready
	super._ready()

func _physics_process(delta: float) -> void:
	# Process base AI behaviors
	super._physics_process(delta)
	
	# Police-specific scanning for threats
	if Time.get_ticks_msec() / 1000.0 - last_scan_time > scan_interval:
		_scan_for_threats()
		last_scan_time = Time.get_ticks_msec() / 1000.0
	
	# Decrease aggro timer
	if target and aggro_timer > 0:
		aggro_timer -= delta
		if aggro_timer <= 0:
			# Reset target if aggro timeout
			target = null

# Override state machine update for police-specific behaviors
func _update_state_machine(delta: float) -> void:
	# First apply the base AI transitions
	super._update_state_machine(delta)
	
	# Only process police-specific transitions if enough time has passed
	if Time.get_ticks_msec() / 1000.0 - last_state_change_time < min_state_duration:
		return
	
	# Police-specific transitions
	match current_state:
		State.IDLE:
			# Generate patrol points if none exist
			if patrol_points.size() == 0:
				_generate_patrol_points()
			_change_state(State.PATROL)
		
		State.PATROL:
			# Check if we have a target to chase
			if target and is_instance_valid(target):
				_change_state(State.CHASE)
			
			# Random chance to dock at a planet
			elif randf() < 0.001:  # Very low chance per frame
				_find_nearest_planet()
				if home_planet:
					_change_state(State.LAND)
		
		State.CHASE:
			# If target is gone or aggro timed out, go back to patrol
			if not target or not is_instance_valid(target) or aggro_timer <= 0:
				target = null
				_change_state(State.PATROL)
			
			# If we're close enough to target, attack
			elif target and global_position.distance_to(target.global_position) < 300:
				_change_state(State.ATTACK)
		
		State.ATTACK:
			# If target is gone or aggro timed out, go back to patrol
			if not target or not is_instance_valid(target) or aggro_timer <= 0:
				target = null
				_change_state(State.PATROL)
			
			# If target is too far, chase
			elif target and global_position.distance_to(target.global_position) > 500:
				_change_state(State.CHASE)
		
		State.FLEE:
			# Police are more likely to return to fight after fleeing
			if randf() < 0.05 * aggressiveness and target and ship.velocity.length() > max_speed * 0.8:
				# We've gained some distance and speed, go back on the attack
				_change_state(State.CHASE)
		
		State.LAND:
			# After landing procedure completes, go back to patrol
			if docking_timer > docking_duration:
				_change_state(State.PATROL)

# Police-specific methods

func _generate_patrol_points() -> void:
	# Generate random patrol points around the patrol center
	patrol_points.clear()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = patrol_seed if patrol_seed > 0 else randi()
	
	for i in range(patrol_count):
		var angle = rng.randf_range(0, 2 * PI)
		var distance = rng.randf_range(patrol_radius * 0.2, patrol_radius)
		var point = patrol_center + Vector2(cos(angle), sin(angle)) * distance
		patrol_points.append(point)
	
	current_patrol_index = 0

func _scan_for_threats() -> void:
	# Skip if we already have a target
	if target and is_instance_valid(target) and aggro_timer > 0:
		return
	
	# Check for pirate ships or player attacking traders
	var found_threat = false
	
	for ship_node in visible_ships:
		# Ignore our own ship
		if ship_node == ship:
			continue
		
		# Check if ship is a pirate
		var is_pirate = false
		for child in ship_node.get_children():
			if child is Pirate_Pilot:
				is_pirate = true
				break
		
		if is_pirate:
			target = ship_node
			aggro_timer = aggro_timeout
			found_threat = true
			break
		
		# Check if player is attacking traders
		var is_player = false
		var player_ref = null
		
		for child in ship_node.get_children():
			if child is Player:
				is_player = true
				player_ref = child
				break
		
		if is_player and player_ref:
			# Check if player is attacking traders
			# This would need to be expanded with a proper hostility system
			# For now, random chance for demonstration
			if randf() < 0.1:  # 10% chance to consider player hostile
				target = ship_node
				aggro_timer = aggro_timeout
				found_threat = true
				break
	
	# If we found a threat, we should stop patrolling and chase
	if found_threat and current_state == State.PATROL:
		_change_state(State.CHASE)

func _find_nearest_planet() -> void:
	var nearest_dist = INF
	home_planet = null
	
	# First check visible planets
	for planet in visible_planets:
		var dist = global_position.distance_to(planet.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			home_planet = planet
	
	# If no planet found, search in the scene (simplified)
	if not home_planet:
		# This would be replaced with a more efficient planet registry system
		var planets = get_tree().get_nodes_in_group("planets")
		for planet in planets:
			if planet is Orbiting_Body:
				var dist = global_position.distance_to(planet.global_position)
				if dist < nearest_dist:
					nearest_dist = dist
					home_planet = planet

# Track docking timer for police ships that land
var docking_timer: float = 0.0
var docking_duration: float = 5.0  # Police stay docked briefly

# Override landing state for police
func _process_land_state(delta: float) -> void:
	if not home_planet or not is_instance_valid(home_planet):
		_change_state(State.PATROL)
		return
	
	_navigate_to_position(home_planet.global_position, delta)
	
	# Check if we've reached the planet
	if global_position.distance_to(home_planet.global_position) < 100:
		# "Dock" at the planet - would be replaced with actual docking animation
		ship.locked = true
		ship.velocity = Vector2.ZERO
		docking_timer += delta
		
		# If docked long enough, return to patrol
		if docking_timer >= docking_duration:
			ship.locked = false
			_change_state(State.PATROL)
			docking_timer = 0.0

# Signal handling specific to police
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)
	
	# Police-specific handling
	if body is Ship:
		# Immediately scan new ships that enter detection range
		_scan_for_threats()
