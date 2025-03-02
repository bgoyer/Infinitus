extends AIPilot
class_name PiratePilot

# Pirate-specific variables
var loot_value: int = 0  # Value of accumulated loot
var max_loot_capacity: int = 1000  # Maximum loot before returning to base
var has_pirate_base: bool = false  # Whether this pirate has a base to return to
var pirate_base: OrbitingBody = null  # Planet serving as pirate base
var ambush_position: Vector2 = Vector2.ZERO  # Position to set up ambush
var is_setting_ambush: bool = false
var ambush_timer: float = 0.0
var max_ambush_time: float = 30.0  # Maximum time to wait in ambush
var last_target_evaluation: float = 0.0
var target_eval_interval: float = 1.0  # How often to reevaluate targets

# Pirate personality
var boldness: float = 0.5  # 0.0 to 1.0, affects willingness to attack larger ships
var greediness: float = 0.5  # 0.0 to 1.0, affects prioritization of high-value targets
var patience: float = 0.5  # 0.0 to 1.0, affects ambush behavior

func _ready() -> void:
	# Setup pirate-specific parameters based on personality
	aggressiveness = randf_range(0.3, 0.9)  # Pirates vary in aggressiveness
	boldness = randf_range(0.1, 1.0)
	greediness = randf_range(0.3, 1.0)
	patience = randf_range(0.1, 0.8)
	
	# Derived parameters
	flee_health_threshold = 0.2 + (1.0 - aggressiveness) * 0.3  # More aggressive pirates flee later
	detection_range = 1000.0 + patience * 500.0  # Patient pirates scan farther
	
	# Ambush and patrol settings
	is_setting_ambush = randf() < patience  # Patient pirates more likely to ambush
	
	# Start by warping in or setting up ambush
	if is_setting_ambush:
		_set_ambush_position()
		_change_state(State.PATROL)  # Will patrol to ambush position
	else:
		_change_state(State.WARP_IN)
	
	# Call parent _ready
	super._ready()

func _physics_process(delta: float) -> void:
	# Process base AI behaviors
	super._physics_process(delta)
	
	# Pirate-specific behaviors
	if is_setting_ambush and current_state == State.IDLE:
		ambush_timer += delta
		
		# Evaluate potential targets while in ambush
		if Time.get_ticks_msec() / 1000.0 - last_target_evaluation > target_eval_interval:
			_evaluate_potential_targets()
			last_target_evaluation = Time.get_ticks_msec() / 1000.0
		
		# End ambush if waited too long
		if ambush_timer > max_ambush_time * (0.5 + patience * 0.5):
			is_setting_ambush = false
			_generate_patrol_points()
			_change_state(State.PATROL)
	
	# Check if we should return to base because of loot
	if has_pirate_base and loot_value >= max_loot_capacity * greediness:
		if current_state != State.LAND and current_state != State.FLEE:
			home_planet = pirate_base
			_change_state(State.LAND)

# Override state machine update for pirate-specific behaviors
func _update_state_machine(delta: float) -> void:
	# First apply the base AI transitions
	super._update_state_machine(delta)
	
	# Only process pirate-specific transitions if enough time has passed
	if Time.get_ticks_msec() / 1000.0 - last_state_change_time < min_state_duration:
		return
	
	# Pirate-specific transitions
	match current_state:
		State.IDLE:
			# If in ambush, stay idle until we find a target or timeout
			if is_setting_ambush:
				# Just wait for target evaluation to trigger a state change
				pass
			else:
				# Normal behavior - patrol until we find a target
				_generate_patrol_points()
				_change_state(State.PATROL)
		
		State.PATROL:
			# If heading to ambush position
			if is_setting_ambush:
				# Check if we've reached the ambush position
				if global_position.distance_to(ambush_position) < arrive_distance:
					ambush_timer = 0.0
					_change_state(State.IDLE)  # Wait in ambush
				return
			
			# Normal patrol - check for potential targets
			_evaluate_potential_targets()
			
			# Small chance to set up a new ambush
			if not target and randf() < 0.001 * patience:
				is_setting_ambush = true
				_set_ambush_position()
				_change_state(State.PATROL)  # Will patrol to ambush position
		
		State.CHASE:
			# If target is gone, go back to patrol
			if not target or not is_instance_valid(target):
				target = null
				_change_state(State.PATROL)
			
			# If we're close enough to target, attack
			elif target and global_position.distance_to(target.global_position) < 300:
				_change_state(State.ATTACK)
			
			# Evaluate if we should continue chasing based on target value and distance
			elif target and _should_abandon_chase():
				target = null
				_change_state(State.PATROL)
		
		State.ATTACK:
			# If target is gone, go back to patrol
			if not target or not is_instance_valid(target):
				target = null
				_change_state(State.PATROL)
			
			# If target is too far, chase
			elif target and global_position.distance_to(target.global_position) > 500:
				_change_state(State.CHASE)
		
		State.FLEE:
			# If we've fled far enough and health is ok, maybe go back on the attack
			if target and global_position.distance_to(target.global_position) > detection_range * 0.8:
				# Health check would go here
				var health_percentage = 1.0  # Placeholder
				
				if health_percentage > flee_health_threshold + 0.2 and randf() < boldness * 0.5:
					# Bold pirates might return to the fight
					_change_state(State.CHASE)
			
			# If no target or fled very far, go back to patrol
			if not target or not is_instance_valid(target) or global_position.distance_to(target.global_position) > detection_range * 1.2:
				target = null
				_change_state(State.PATROL)
		
		State.LAND:
			# After landing procedure completes and unloading loot, go back to patrol
			if loot_value == 0:  # Reset in _process_land_state when docked
				_change_state(State.PATROL)

# Pirate-specific methods

func _generate_patrol_points() -> void:
	# Generate random patrol points focused on shipping lanes or trade routes
	patrol_points.clear()
	
	# This would be expanded with proper knowledge of shipping lanes
	# For now, generate some random points
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	
	for i in range(5):
		var point = Vector2(
			rng.randf_range(-5000, 5000),
			rng.randf_range(-5000, 5000)
		)
		patrol_points.append(point)
	
	current_patrol_index = 0

func _set_ambush_position() -> void:
	# Set up an ambush position near a common trade route
	# This would be expanded with proper knowledge of shipping lanes
	
	# For now, choose a random position or near a planet if one is visible
	if visible_planets.size() > 0:
		var planet = visible_planets[randi() % visible_planets.size()]
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		ambush_position = planet.global_position + direction * randf_range(1000, 2000)
	else:
		ambush_position = Vector2(
			randf_range(-5000, 5000),
			randf_range(-5000, 5000)
		)
	
	# Set patrol point to the ambush position
	patrol_points = [ambush_position]
	current_patrol_index = 0

func _evaluate_potential_targets() -> void:
	var best_target = null
	var best_score = 0.0
	
	for ship_node in visible_ships:
		# Skip our own ship
		if ship_node == ship:
			continue
		
		# Skip pirate ships
		var is_pirate = false
		for child in ship_node.get_children():
			if child is PiratePilot:
				is_pirate = true
				break
		
		if is_pirate:
			continue
		
		# Calculate target score based on:
		# 1. Distance (closer is better)
		# 2. Perceived value (higher is better, affected by greediness)
		# 3. Perceived strength (weaker is better, affected by boldness)
		
		var distance = global_position.distance_to(ship_node.global_position)
		var distance_score = 1.0 - clamp(distance / detection_range, 0.0, 1.0)
		
		# Estimate value (would be replaced with cargo system)
		var value_score = 0.5  # Default
		
		# Trader ships are valued higher
		for child in ship_node.get_children():
			if child is TraderPilot:
				value_score = 0.8
				break
		
		# Estimate strength (would be replaced with ship class/weapons system)
		var strength_score = 0.5  # Default
		
		# Police ships are stronger
		for child in ship_node.get_children():
			if child is PolicePilot:
				strength_score = 0.8
				break
		
		# Final score calculation
		var target_score = (
			distance_score * 0.3 +
			value_score * 0.4 * greediness +
			(1.0 - strength_score) * 0.3 * boldness
		)
		
		# Adjust for player - pirates might be more interested in player ships
		for child in ship_node.get_children():
			if child is Player:
				target_score *= 1.2
				break
		
		# Check if this is the best target so far
		if target_score > best_score:
			best_score = target_score
			best_target = ship_node
	
	# Require minimum score based on aggressiveness
	if best_score > 0.4 - aggressiveness * 0.2:
		target = best_target
		if current_state == State.PATROL or current_state == State.IDLE:
			_change_state(State.CHASE)

func _should_abandon_chase() -> bool:
	# Decide if target is not worth chasing anymore
	if not target:
		return true
	
	var distance = global_position.distance_to(target.global_position)
	
	# Too far away?
	if distance > detection_range * 1.2:
		return true
	
	# Target value check (would be replaced with proper value system)
	var target_value = 0.5
	
	# Distance vs. value calculation
	var persistence = aggressiveness * 0.5 + boldness * 0.3 + greediness * 0.2
	var chase_threshold = detection_range * (0.5 + persistence * 0.5)
	
	return distance > chase_threshold

func _collect_loot(value: int) -> void:
	# Called when destroying a target
	loot_value += value

# Override landing state for pirates
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
		
		# Unload loot (would be expanded with proper inventory system)
		loot_value = 0
		
		# Stay docked briefly
		await get_tree().create_timer(2.0).timeout
		
		# Undock and return to patrol
		ship.locked = false
		_change_state(State.PATROL)

# Override attack state to collect loot when target is destroyed
func _process_attack_state(delta: float) -> void:
	super._process_attack_state(delta)
	
	# Check if target was destroyed (would be replaced with proper health system)
	if target and is_instance_valid(target) and randf() < 0.001:  # Placeholder for target destruction
		# Collect loot based on target type
		var loot = 100  # Default loot value
		
		# More loot from traders
		for child in target.get_children():
			if child is TraderPilot:
				loot = 500
				break
		
		_collect_loot(loot)
		target = null
		_change_state(State.PATROL)

# Signal handling specific to pirates
func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)
	
	# Pirate-specific handling
	if body is Ship:
		# Immediately evaluate new ships that enter detection range
		_evaluate_potential_targets()
