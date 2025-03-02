# Police Fleet Controller - specialized for patrolling and law enforcement
class_name PoliceFleetController
extends FactionFleetController

# Police behavior variables
var policing_state: String = "patrolling"  # patrolling, responding, pursuing, engaging, returning
var patrol_center: Vector2 = Vector2.ZERO
var patrol_radius: float = 1500.0
var current_patrol_points: Array = []
var current_patrol_index: int = 0
var last_assessment_time: float = 0.0
var assessment_interval: float = 2.0
var response_target: Ship = null
var scan_interval: float = 5.0
var last_scan_time: float = 0.0
var aggressiveness: float = 0.7  # How eagerly police engage
var station: OrbitingBody = null
var has_station: bool = false

func _init(target_fleet: Fleet) -> void:
	# Set appropriate police strategy
	if fleet and fleet.strategy_system:
		fleet.strategy_system.set_strategy(fleet.strategy_system.StrategyType.PATROL)

func _ready() -> void:
	super._ready()
	
	# Initialize police station
	_find_police_station()
	
	# Set initial patrol center
	if has_station and is_instance_valid(station):
		patrol_center = station.global_position
	else:
		# No station, use current position
		patrol_center = fleet.get_average_position()
	
	# Generate initial patrol route
	_generate_patrol_route()

func _process(delta: float) -> void:
	super._process(delta)
	
	# Process police-specific behavior
	if fleet and is_instance_valid(fleet):
		_process_police_behavior(delta)
		
		# Periodically scan for violators
		last_scan_time += delta
		if last_scan_time >= scan_interval:
			_scan_for_violators()
			last_scan_time = 0.0

func update_tactical_assessment(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Only assess periodically
	if current_time - last_assessment_time < assessment_interval:
		return
	
	last_assessment_time = current_time
	
	# Run tactical assessment
	var assessment = fleet.strategy_system.assess_tactical_situation(fleet)
	
	# React to assessment based on police protocols
	if assessment.threats.size() > 0 and policing_state == "patrolling":
		# Evaluate if this is a police matter
		var primary_threat = assessment.threats[0]
		var is_police_business = _is_police_business(primary_threat)
		
		if is_police_business:
			response_target = primary_threat
			policing_state = "responding"
			fleet.execute_command("move_to", response_target.global_position)

func _process_police_behavior(delta: float) -> void:
	# Handle police state
	match policing_state:
		"patrolling":
			_handle_patrol_state(delta)
		"responding":
			_handle_responding_state(delta)
		"pursuing":
			_handle_pursuing_state(delta)
		"engaging":
			_handle_engaging_state(delta)
		"returning":
			_handle_returning_state(delta)

func _handle_patrol_state(delta: float) -> void:
	# Normal patrol behavior
	if current_patrol_points.size() == 0:
		_generate_patrol_route()
		return
	
	# Check if we've reached the current patrol point
	var current_point = current_patrol_points[current_patrol_index]
	var distance_to_point = fleet.get_average_position().distance_to(current_point)
	
	if distance_to_point < 200:
		# Move to next patrol point
		current_patrol_index = (current_patrol_index + 1) % current_patrol_points.size()
		fleet.execute_command("move_to", current_patrol_points[current_patrol_index])
	else:
		# Continue to current point
		if Engine.get_frames_drawn() % 60 == 0:  # Periodically update movement
			fleet.execute_command("move_to", current_patrol_points[current_patrol_index])

func _handle_responding_state(delta: float) -> void:
	if not response_target or not is_instance_valid(response_target):
		# Target lost, go back to patrol
		response_target = null
		policing_state = "patrolling"
		return
	
	# Move toward the target
	var distance_to_target = fleet.get_average_position().distance_to(response_target.global_position)
	
	if distance_to_target < 800:  # Close enough to pursue
		policing_state = "pursuing"
	else:
		# Continue responding
		if Engine.get_frames_drawn() % 30 == 0:  # Frequently update response
			fleet.execute_command("move_to", response_target.global_position)

func _handle_pursuing_state(delta: float) -> void:
	if not response_target or not is_instance_valid(response_target):
		# Target lost, go back to patrol
		response_target = null
		policing_state = "patrolling"
		return
	
	# Calculate distance to target
	var distance_to_target = fleet.get_average_position().distance_to(response_target.global_position)
	
	if distance_to_target < 400:  # Close enough to engage
		policing_state = "engaging"
		fleet.execute_command("attack", response_target)
	else:
		# Continue pursuit
		if Engine.get_frames_drawn() % 30 == 0:  # Frequently update pursuit
			fleet.execute_command("move_to", response_target.global_position)

func _handle_engaging_state(delta: float) -> void:
	if not response_target or not is_instance_valid(response_target):
		# Target neutralized or escaped
		response_target = null
		
		# Return to station or patrol
		if has_station and is_instance_valid(station) and randf() < 0.3:
			policing_state = "returning"
			fleet.execute_command("move_to", station.global_position)
		else:
			policing_state = "patrolling"
		
		return
	
	# Continue engagement
	if Engine.get_frames_drawn() % 60 == 0:  # Periodically update attack
		fleet.execute_command("attack", response_target)

func _handle_returning_state(delta: float) -> void:
	if not has_station or not is_instance_valid(station):
		policing_state = "patrolling"
		return
	
	var distance_to_station = fleet.get_average_position().distance_to(station.global_position)
	
	if distance_to_station < 200:  # At station
		# Briefly dock
		await get_tree().create_timer(3.0).timeout
		
		# Resume patrol
		patrol_center = station.global_position
		_generate_patrol_route()
		policing_state = "patrolling"
	else:
		# Continue returning
		if Engine.get_frames_drawn() % 60 == 0:  # Periodically update movement
			fleet.execute_command("move_to", station.global_position)

func _generate_patrol_route() -> void:
	current_patrol_points.clear()
	
	# Create points in a circuit around patrol center
	var num_points = randi_range(3, 6)
	
	for i in range(num_points):
		var angle = 2 * PI * i / num_points
		var distance = patrol_radius * (0.8 + randf() * 0.4)  # Slight randomness
		var point = patrol_center + Vector2(cos(angle), sin(angle)) * distance
		current_patrol_points.append(point)
	
	current_patrol_index = 0
	
	# Set formation based on threat level in sector
	var threat_level = _assess_sector_threat_level()
	
	if threat_level > 0.7:
		fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.WEDGE)
	elif threat_level > 0.3:
		fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.V_FORMATION)
	else:
		fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.ECHELON)
	
	# Move to first patrol point
	fleet.execute_command("move_to", current_patrol_points[0])

func _scan_for_violators() -> void:
	# Skip if already responding to something
	if policing_state != "patrolling":
		return
	
	var pirates_detected = []
	var fleet_position = fleet.get_average_position()
	var scan_range = 1500.0
	
	# Look for pirates or suspicious ships
	var ships = get_tree().get_nodes_in_group("Ships")
	
	for ship in ships:
		# Skip our own fleet members
		if ship in fleet.member_ships:
			continue
		
		var distance = fleet_position.distance_to(ship.global_position)
		if distance > scan_range:
			continue
		
		# Check if ship is a pirate
		for child in ship.get_children():
			if child is PiratePilot:
				pirates_detected.append(ship)
				break
	
	# Respond to pirates if found
	if pirates_detected.size() > 0:
		# Pick the closest pirate
		var closest_pirate = null
		var closest_distance = INF
		
		for pirate in pirates_detected:
			var distance = fleet_position.distance_to(pirate.global_position)
			if distance < closest_distance:
				closest_pirate = pirate
				closest_distance = distance
		
		response_target = closest_pirate
		policing_state = "responding"
		fleet.execute_command("move_to", response_target.global_position)

func _find_police_station() -> void:
	# 80% chance to have a police station
	has_station = randf() < 0.8
	
	if has_station:
		# Find a planet to use as station
		var planets = get_tree().get_nodes_in_group("planets")
		if planets.size() > 0:
			# Pick a random planet, but prefer planets with less association to pirates
			var candidates = []
			for planet in planets:
				candidates.append(planet)
			
			candidates.shuffle()
			station = candidates[0]

func _is_police_business(ship: Ship) -> bool:
	if not is_instance_valid(ship):
		return false
	
	# Check if ship is a pirate
	for child in ship.get_children():
		if child is PiratePilot:
			return true
	
	# Other criteria could be added here
	
	return false

func _assess_sector_threat_level() -> float:
	# Estimate threat level in current patrol sector
	var threat_level = 0.0
	
	# Count pirates in range
	var pirates_in_range = 0
	var fleet_position = fleet.get_average_position()
	var scan_range = 2000.0
	
	var ships = get_tree().get_nodes_in_group("Ships")
	
	for ship in ships:
		if ship in fleet.member_ships:
			continue
		
		var distance = fleet_position.distance_to(ship.global_position)
		if distance > scan_range:
			continue
		
		for child in ship.get_children():
			if child is PiratePilot:
				pirates_in_range += 1
				break
	
	# Calculate threat level (0.0 to 1.0)
	threat_level = min(pirates_in_range * 0.2, 1.0)
	
	return threat_level
