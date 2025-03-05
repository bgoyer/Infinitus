# Pirate Fleet Controller - specialized for raiding and ambush behavior
class_name PirateFleetController
extends FactionFleetController

# Pirate behavior variables
var hunting_state: String = "scouting"  # scouting, ambushing, pursuing, raiding, retreating
var ambush_position: Vector2 = Vector2.ZERO
var ambush_timer: float = 0.0
var max_ambush_time: float = 60.0
var current_target: Ship = null
var last_assessment_time: float = 0.0
var assessment_interval: float = 2.0  # How often to make decisions
var loot_value: int = 0  # Accumulated loot
var max_loot_capacity: int = 3000  # When to return to base
var pirate_base: Planet = null
var has_base: bool = false
var boldness: float = 0.5  # Affects willingness to engage larger targets
var patience: float = 0.5  # Affects ambush behavior

func _init(target_fleet: Fleet) -> void:
	# Set appropriate pirate strategy
	if fleet and fleet.strategy_system:
		fleet.strategy_system.set_strategy(fleet.strategy_system.StrategyType.AGGRESSIVE)
	
	# Randomize pirate personality
	boldness = randf_range(0.3, 0.9)
	patience = randf_range(0.1, 0.8)

func _ready() -> void:
	super._ready()
	
	# Initialize pirate base
	_find_pirate_base()
	
	# Set initial hunting state based on personality
	if patience > 0.6:
		hunting_state = "ambushing"
		_set_ambush_position()
	else:
		hunting_state = "scouting"
		_generate_scouting_route()

func _process(delta: float) -> void:
	super._process(delta)
	
	# Process pirate-specific behavior
	if fleet and is_instance_valid(fleet):
		_process_pirate_behavior(delta)

func update_tactical_assessment(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Only assess periodically
	if current_time - last_assessment_time < assessment_interval:
		return
	
	last_assessment_time = current_time
	
	# Run tactical assessment
	var assessment = fleet.strategy_system.assess_tactical_situation(fleet)
	
	# Pirates handle threats differently - they look for targets, not threats
	if hunting_state != "retreating":
		_evaluate_potential_targets()

func _process_pirate_behavior(delta: float) -> void:
	# Handle pirate state
	match hunting_state:
		"scouting":
			_handle_scouting_state(delta)
		"ambushing":
			_handle_ambushing_state(delta)
		"pursuing":
			_handle_pursuing_state(delta)
		"raiding":
			_handle_raiding_state(delta)
		"retreating":
			_handle_retreating_state(delta)
	
	# Check if we should return to base because of loot
	if has_base and loot_value >= max_loot_capacity and hunting_state != "retreating":
		_return_to_base()

func _handle_scouting_state(delta: float) -> void:
	# Actively patrol and look for targets
	if Engine.get_frames_drawn() % 120 == 0:  # Periodically evaluate targets
		_evaluate_potential_targets()
	
	# Chance to set up ambush if no target found
	if not current_target or not is_instance_valid(current_target):
		if randf() < patience * 0.01:  # Greater patience increases ambush chance
			hunting_state = "ambushing"
			_set_ambush_position()
			fleet.execute_command("move_to", ambush_position)

func _handle_ambushing_state(delta: float) -> void:
	# Wait at ambush point for potential targets
	var distance_to_ambush = fleet.get_average_position().distance_to(ambush_position)
	
	if distance_to_ambush < 300:  # At ambush position
		# Wait in ambush
		ambush_timer += delta
		
		# Evaluate potential targets
		_evaluate_potential_targets()
		
		# If we've waited too long, go back to scouting
		if ambush_timer > max_ambush_time * patience:
			hunting_state = "scouting"
			_generate_scouting_route()
	else:
		# Still moving to ambush position
		if Engine.get_frames_drawn() % 60 == 0:  # Periodically update movement
			fleet.execute_command("move_to", ambush_position)

func _handle_pursuing_state(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		# Target lost, go back to scouting
		current_target = null
		hunting_state = "scouting"
		_generate_scouting_route()
		return
	
	# Calculate distance to target
	var distance_to_target = fleet.get_average_position().distance_to(current_target.global_position)
	
	if distance_to_target < 400:  # Close enough to raid
		hunting_state = "raiding"
		fleet.execute_command("attack", current_target)
	else:
		# Continue pursuit
		if Engine.get_frames_drawn() % 30 == 0:  # Frequently update pursuit
			fleet.execute_command("move_to", current_target.global_position)

func _handle_raiding_state(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		# Target destroyed or lost
		hunting_state = "scouting"
		_generate_scouting_route()
		
		# Collect loot if target was destroyed
		loot_value += randi_range(200, 500)  # Random loot value
		return
	
	# Continue attack
	if Engine.get_frames_drawn() % 60 == 0:  # Periodically update attack
		fleet.execute_command("attack", current_target)
	
	# Check if we're taking heavy damage
	var fleet_health = _estimate_fleet_health()
	if fleet_health < 0.3:  # Heavily damaged
		# Retreat if we're not bold or extremely disadvantaged
		if boldness < 0.7 or fleet_health < 0.15:
			hunting_state = "retreating"
			_find_retreat_position()

func _handle_retreating_state(delta: float) -> void:
	# If we're returning to base with loot
	if has_base and is_instance_valid(pirate_base) and loot_value > 0:
		var distance_to_base = fleet.get_average_position().distance_to(pirate_base.global_position)
		
		if distance_to_base < 300:  # At base
			# "Sell" loot
			loot_value = 0
			
			# Rest a bit
			await get_tree().create_timer(5.0).timeout
			
			# Resume hunting
			hunting_state = "scouting"
			_generate_scouting_route()
		else:
			# Still heading to base
			if Engine.get_frames_drawn() % 60 == 0:  # Periodically update movement
				fleet.execute_command("move_to", pirate_base.global_position)
	else:
		# Regular retreat from danger
		# Check if coast is clear
		var threats = _find_nearby_threats()
		if threats.size() == 0:
			# Safe now, resume hunting
			hunting_state = "scouting"
			_generate_scouting_route()

func _evaluate_potential_targets() -> void:
	var best_target = null
	var best_score = 0.0
	
	# Look for potential targets
	var ships = get_tree().get_nodes_in_group("Ships")
	var fleet_position = fleet.get_average_position()
	
	for potential_target in ships:
		# Skip our own fleet members
		if potential_target in fleet.member_ships:
			continue
		
		# Skip other pirate ships
		var is_pirate = false
		for child in potential_target.get_children():
			if child is PiratePilot:
				is_pirate = true
				break
		
		if is_pirate:
			continue
		
		# Calculate target score based on:
		# 1. Distance (closer is better)
		# 2. Perceived value (higher is better)
		# 3. Perceived strength (weaker is better, affected by boldness)
		
		var distance = fleet_position.distance_to(potential_target.global_position)
		var max_detection = 2000.0
		
		# Skip if too far away
		if distance > max_detection:
			continue
		
		var distance_score = 1.0 - clamp(distance / max_detection, 0.0, 1.0)
		
		# Estimate value (would be replaced with cargo system)
		var value_score = 0.5  # Default
		
		# Trader ships are valued higher
		for child in potential_target.get_children():
			if child is TraderPilot:
				value_score = 0.8
				break
		
		# Estimate strength (would be replaced with ship class/weapons system)
		var strength_score = 0.5  # Default
		
		# Police ships are stronger
		for child in potential_target.get_children():
			if child is PolicePilot:
				strength_score = 0.8
				break
		
		# Player is special case
		var is_player = false
		for child in potential_target.get_children():
			if child is Player:
				is_player = true
				strength_score = 0.7  # Player considered strong
				value_score = 0.9  # But high value
				break
		
		# Final score calculation
		var target_score = (
			distance_score * 0.3 +
			value_score * 0.4 +
			(1.0 - strength_score) * 0.3 * boldness  # Boldness affects willingness to attack strong targets
		)
		
		# Adjust for player - pirates might be more interested in player ships
		if is_player:
			target_score *= 1.2
		
		# Check if this is the best target so far
		if target_score > best_score:
			best_score = target_score
			best_target = potential_target
	
	# Need minimum score to be worth pursuing
	if best_score > 0.4 and best_target != null:
		current_target = best_target
		hunting_state = "pursuing"
		fleet.execute_command("move_to", current_target.global_position)

func _set_ambush_position() -> void:
	# Set up an ambush near likely trade routes
	# For now, near a planet
	var planets = get_tree().get_nodes_in_group("planets")
	if planets.size() > 0:
		var planet = planets[randi() % planets.size()]
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		ambush_position = planet.global_position + direction * randf_range(800, 1500)
	else:
		# No planets, pick random position
		ambush_position = Vector2(
			randf_range(-3000, 3000),
			randf_range(-3000, 3000)
		)
	
	ambush_timer = 0.0
	fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.CIRCLE)

func _generate_scouting_route() -> void:
	# Generate patrol points for scouting
	var patrol_points = []
	
	# Use planets as points of interest
	var planets = get_tree().get_nodes_in_group("planets")
	if planets.size() > 0:
		planets.shuffle()
		var count = min(3, planets.size())
		
		for i in range(count):
			var planet = planets[i]
			var offset = Vector2(randf_range(-500, 500), randf_range(-500, 500))
			patrol_points.append(planet.global_position + offset)
	
	# Add some random points
	for i in range(2):
		patrol_points.append(Vector2(
			randf_range(-3000, 3000),
			randf_range(-3000, 3000)
		))
	
	# Set up patrol
	fleet.formation_manager.set_formation(fleet.formation_manager.FormationType.WEDGE)
	
	# Command fleet to patrol
	if patrol_points.size() > 0:
		fleet.execute_command("patrol", patrol_points)

func _find_pirate_base() -> void:
	# 50% chance to have a pirate base
	has_base = randf() < 0.5
	
	if has_base:
		# Find a planet to use as base
		var planets = get_tree().get_nodes_in_group("planets")
		if planets.size() > 0:
			pirate_base = planets[randi() % planets.size()]

func _return_to_base() -> void:
	if has_base and is_instance_valid(pirate_base):
		hunting_state = "retreating"
		fleet.execute_command("move_to", pirate_base.global_position)

func _find_retreat_position() -> Vector2:
	var retreat_pos = Vector2.ZERO
	var threats = _find_nearby_threats()
	
	if threats.size() > 0:
		# Retreat away from threats
		var threat_center = Vector2.ZERO
		for threat in threats:
			threat_center += threat.global_position
		threat_center /= threats.size()
		
		# Move opposite direction
		var retreat_dir = (fleet.get_average_position() - threat_center).normalized()
		retreat_pos = fleet.get_average_position() + retreat_dir * 2000
	else:
		# No specific threats, random retreat direction
		var retreat_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		retreat_pos = fleet.get_average_position() + retreat_dir * 2000
	
	return retreat_pos

func _find_nearby_threats() -> Array:
	var threats = []
	var max_distance = 1500.0
	var fleet_position = fleet.get_average_position()
	
	# Look for potential threats
	var ships = get_tree().get_nodes_in_group("Ships")
	
	for ship in ships:
		# Skip our own fleet members
		if ship in fleet.member_ships:
			continue
		
		var distance = fleet_position.distance_to(ship.global_position)
		if distance > max_distance:
			continue
		
		# Check if ship is a threat (police or player)
		for child in ship.get_children():
			if child is PolicePilot or child is Player:
				threats.append(ship)
				break
	
	return threats

func _estimate_fleet_health() -> float:
	# In a real implementation, this would use actual ship health
	# For now, we'll just return a fixed value
	return 1.0
