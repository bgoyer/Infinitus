extends AI_Pilot
class_name Trader_Pilot

# Trader-specific variables
var target_planet: Orbiting_Body = null  # Planet we want to trade with
var trade_route: Array[Orbiting_Body] = []  # List of planets in trade route
var current_route_index: int = 0
var docked: bool = false
var docking_time: float = 0.0
var docking_duration: float = 10.0  # How long to stay docked
var can_be_attacked: bool = true
var cargo_value: int = 0

func _ready() -> void:
	# Setup trader-specific parameters
	aggressiveness = 0.1  # Traders are not aggressive
	flee_health_threshold = 0.7  # Traders flee early
	detection_range = 1500.0  # Traders are cautious and keep an eye out
	
	# Start by warping in
	_change_state(State.WARP_IN)
	
	# Call parent _ready
	super._ready()

func _physics_process(delta: float) -> void:
	# Process base AI behaviors
	super._physics_process(delta)
	
	# Additional trader-specific updates
	_update_cargo_value()

# Override state machine update for trader-specific behaviors
func _update_state_machine(delta: float) -> void:
	# First apply the base AI transitions
	super._update_state_machine(delta)
	
	# Only process trader-specific transitions if enough time has passed
	if Time.get_ticks_msec() / 1000.0 - last_state_change_time < min_state_duration:
		return
	
	# Trader-specific transitions
	match current_state:
		State.IDLE:
			# After warping in or finishing trade, decide what to do next
			if trade_route.size() > 0:
				_select_next_trade_planet()
				_change_state(State.PATROL)
			else:
				# No trade route, look for planets
				_find_nearest_planet()
				if target_planet:
					_change_state(State.PATROL)
				else:
					# No planets found, warp out
					_change_state(State.WARP_OUT)
		
		State.PATROL:
			# Check for threats
			var nearest_threat = _find_nearest_threat()
			if nearest_threat:
				target = nearest_threat
				_change_state(State.FLEE)
				return
			
			# If we're close to our target planet, try to land
			if target_planet and global_position.distance_to(target_planet.global_position) < 500:
				home_planet = target_planet
				_change_state(State.LAND)
		
		State.LAND:
			# After docking for a while, undock and continue route
			if docked and Time.get_ticks_msec() / 1000.0 - docking_time > docking_duration:
				docked = false
				_change_state(State.IDLE)  # Will select next planet on next update
		
		State.FLEE:
			# While fleeing, check if we should warp out
			if randf() < 0.05 * aggressiveness:  # Lower aggressiveness = higher chance to warp out
				_change_state(State.WARP_OUT)

# Override landing state for traders
func _process_land_state(delta: float) -> void:
	if not home_planet or not is_instance_valid(home_planet):
		_change_state(State.IDLE)
		return
	
	_navigate_to_position(home_planet.global_position, delta)
	
	# Check if we've reached the planet
	if global_position.distance_to(home_planet.global_position) < 100:
		# "Dock" at the planet - would be replaced with actual docking animation
		ship.locked = true
		ship.velocity = Vector2.ZERO
		docked = true
		docking_time = Time.get_ticks_msec() / 1000.0
		
		# Trade goods (would be replaced with actual economy system)
		_trade_at_planet()

# Helper methods for trader AI
func _find_nearest_planet() -> void:
	var nearest_dist = INF
	target_planet = null
	
	# First check visible planets
	for planet in visible_planets:
		var dist = global_position.distance_to(planet.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			target_planet = planet
	
	# If no planet found, search in the scene (simplified)
	if not target_planet:
		# This would be replaced with a more efficient planet registry system
		var planets = get_tree().get_nodes_in_group("planets")
		for planet in planets:
			if planet is Orbiting_Body:
				var dist = global_position.distance_to(planet.global_position)
				if dist < nearest_dist:
					nearest_dist = dist
					target_planet = planet

func _select_next_trade_planet() -> void:
	if trade_route.size() == 0:
		target_planet = null
		return
	
	current_route_index = (current_route_index + 1) % trade_route.size()
	target_planet = trade_route[current_route_index]
	
	# Set patrol points to reach this planet
	patrol_points = [target_planet.global_position]
	current_patrol_index = 0

func _trade_at_planet() -> void:
	# Placeholder for trading logic
	# This would be expanded with proper economy simulation
	
	# For now, just update cargo value
	cargo_value = randi_range(500, 2000)

func _find_nearest_threat() -> Ship:
	var nearest_threat = null
	var nearest_dist = detection_range
	
	for ship_node in visible_ships:
		# Check if ship is a threat (has pirate or player pilot)
		# This would need to be expanded with faction system
		var is_threat = false
		
		# Check pilot type (simplified)
		for child in ship_node.get_children():
			if child is Player or child is Pirate_Pilot:
				is_threat = true
				break
		
		if is_threat:
			var dist = global_position.distance_to(ship_node.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_threat = ship_node
	
	return nearest_threat

func _update_cargo_value() -> void:
	# Placeholder for cargo system
	# Would be expanded with actual trade goods
	pass

# Signal handling specific to traders
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)
	
	# Trader-specific handling
	if body is Orbiting_Body:
		# If we have no target planet, consider this one
		if not target_planet:
			target_planet = body
			patrol_points = [target_planet.global_position]
			_change_state(State.PATROL)
