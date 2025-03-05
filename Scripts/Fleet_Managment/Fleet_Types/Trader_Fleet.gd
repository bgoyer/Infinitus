# Trader Fleet Controller - specialized for trade routes and evasive behavior
extends FactionFleetController
class_name TraderFleetController

# Trade route information
var trade_route: Array[Planet] = []
var current_route_index: int = 0
var trade_state: String = "traveling"  # traveling, docking, trading, undocking
var docking_timer: float = 0.0
var docking_duration: float = 15.0  # Time spent at a dock
var last_assessment_time: float = 0.0
var assessment_interval: float = 3.0  # How often to make decisions

func _init(target_fleet: Fleet) -> void:
	# Set appropriate trade strategy
	if fleet and fleet.strategy_system:
		fleet.strategy_system.set_strategy(fleet.strategy_system.StrategyType.TRADE)

func _ready() -> void:
	super._ready()
	
	# Initialize trade route if not already set
	if trade_route.size() == 0:
		_generate_trade_route()

func _process(delta: float) -> void:
	super._process(delta)
	
	# Process trade-specific behavior
	if fleet and is_instance_valid(fleet):
		_process_trade_behavior(delta)

func update_tactical_assessment(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Only assess periodically
	if current_time - last_assessment_time < assessment_interval:
		return
	
	last_assessment_time = current_time
	
	# Run tactical assessment
	var assessment = fleet.strategy_system.assess_tactical_situation(fleet)
	
	# React to assessment
	if assessment.threats.size() > 0:
		# There are threats - handle based on advantage
		if assessment.advantage_level < -0.3:  # Significant disadvantage
			fleet.execute_command("retreat")
		elif assessment.advantage_level < 0:  # Minor disadvantage
			# Try to evade rather than direct retreat
			fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.LINE)
			fleet.execute_command("move_to", _find_safe_route(assessment.threats[0].global_position))
		else:  # Slight advantage or neutral
			# Continue current route but be cautious
			fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.WEDGE)
	else:
		# No threats - normal trade behavior
		trade_state = "traveling"
		fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.V_FORMATION)

func _process_trade_behavior(delta: float) -> void:
	# Skip if no trade route
	if trade_route.size() == 0:
		return
	
	# Handle trade state
	match trade_state:
		"traveling":
			_handle_travel_state(delta)
		"docking":
			_handle_docking_state(delta)
		"trading":
			_handle_trading_state(delta)
		"undocking":
			_handle_undocking_state(delta)

func _handle_travel_state(delta: float) -> void:
	# Check if we've reached the destination
	var target_planet = trade_route[current_route_index]
	
	if not is_instance_valid(target_planet):
		# Planet no longer exists, move to next destination
		_advance_trade_route()
		return
	
	var distance_to_target = fleet.get_average_position().distance_to(target_planet.global_position)
	
	if distance_to_target < 500:  # Within docking range
		trade_state = "docking"
		fleet.execute_command("move_to", target_planet.global_position)
	else:
		# Continue traveling to destination
		if Engine.get_frames_drawn() % 60 == 0:  # Periodically update movement
			fleet.execute_command("move_to", target_planet.global_position)

func _handle_docking_state(delta: float) -> void:
	# Simulate docking procedure
	var target_planet = trade_route[current_route_index]
	
	if not is_instance_valid(target_planet):
		# Planet no longer exists, move to next destination
		trade_state = "traveling"
		_advance_trade_route()
		return
	
	var distance_to_target = fleet.get_average_position().distance_to(target_planet.global_position)
	
	if distance_to_target < 200:  # Docked
		trade_state = "trading"
		docking_timer = 0.0
		
		# Lock all ships
		for ship in fleet.member_ships:
			ship.locked = true
			ship.velocity = Vector2.ZERO

func _handle_trading_state(delta: float) -> void:
	# Simulate trading process
	docking_timer += delta
	
	if docking_timer >= docking_duration:
		trade_state = "undocking"
		
		# Unlock all ships
		for ship in fleet.member_ships:
			ship.locked = false

func _handle_undocking_state(delta: float) -> void:
	# Move away from planet before resuming travel
	var target_planet = trade_route[current_route_index]
	
	if is_instance_valid(target_planet):
		var away_direction = (fleet.get_average_position() - target_planet.global_position).normalized()
		var departure_point = target_planet.global_position + away_direction * 800
		
		fleet.execute_command("move_to", departure_point)
		
		var distance_from_planet = fleet.get_average_position().distance_to(target_planet.global_position)
		
		if distance_from_planet > 600:  # Successfully undocked
			_advance_trade_route()
	else:
		# Planet no longer exists, just move to next destination
		_advance_trade_route()

func _advance_trade_route() -> void:
	# Move to next destination in trade route
	current_route_index = (current_route_index + 1) % trade_route.size()
	trade_state = "traveling"
	
	# Inform fleet of new destination
	if trade_route.size() > 0 and is_instance_valid(trade_route[current_route_index]):
		fleet.execute_command("move_to", trade_route[current_route_index].global_position)

func _generate_trade_route() -> void:
	# Find planets to trade with
	var planets = get_tree().get_nodes_in_group("planets")
	
	# Filter for appropriate planets (could add more logic here)
	var valid_planets: Array[Planet] = []
	for planet in planets:
		if planet is Planet:
			valid_planets.append(planet)
	
	# Create a route with 2-4 planets
	var route_size = min(randi_range(2, 4), valid_planets.size())
	
	# Shuffle planets
	valid_planets.shuffle()
	
	# Take the first few planets for the route
	for i in range(route_size):
		if i < valid_planets.size():
			trade_route.append(valid_planets[i])

func _find_safe_route(threat_position: Vector2) -> Vector2:
	# Find a position that avoids the threat while moving toward destination
	var current_position = fleet.get_average_position()
	var target_planet = trade_route[current_route_index]
	
	if not is_instance_valid(target_planet):
		# If target planet is invalid, just avoid threat
		var away_vector = (current_position - threat_position).normalized()
		return current_position + away_vector * 1000
	
	# Get direction to destination
	var dest_direction = (target_planet.global_position - current_position).normalized()
	
	# Get direction away from threat
	var threat_direction = (current_position - threat_position).normalized()
	
	# Blend the two directions, favoring threat avoidance
	var blended_direction = (threat_direction * 0.7 + dest_direction * 0.3).normalized()
	
	# Return a position in that direction
	return current_position + blended_direction * 1000
