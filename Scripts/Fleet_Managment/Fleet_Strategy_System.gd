extends Node
class_name FleetStrategySystem

# Strategy types
enum StrategyType {
	DEFENSIVE,
	AGGRESSIVE,
	EVASIVE,
	PATROL,
	ESCORT,
	TRADE
}

# Current strategy
var current_strategy: int = StrategyType.DEFENSIVE
# Target priority weights
var priority_weights = {
	"distance": 0.4,      # Closer targets prioritized
	"threat": 0.3,        # Higher threat level prioritized
	"value": 0.2,         # Higher value targets prioritized
	"vulnerability": 0.1  # More vulnerable targets prioritized
}
# Tactical assessment cache
var tactical_assessment = {
	"last_update_time": 0.0,
	"threats": [],
	"advantage_level": 0.0,
	"recommended_action": ""
}
# Tactical assessment update interval (seconds)
var assessment_interval: float = 2.0

func _process(delta: float) -> void:
	# Periodically update tactical assessment
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - tactical_assessment.last_update_time >= assessment_interval:
		# We would update the assessment here, but it requires the fleet reference
		# This will be triggered by fleet commands instead
		pass

func execute_command(fleet: Fleet, command: String, target = null) -> void:
	# Update tactical assessment first
	assess_tactical_situation(fleet)
	
	match command:
		"attack":
			_execute_attack_command(fleet, target)
		"defend":
			_execute_defend_command(fleet, target)
		"move_to":
			_execute_move_to_command(fleet, target)
		"scatter":
			_execute_scatter_command(fleet)
		"retreat":
			_execute_retreat_command(fleet, target) # target is retreat position
		"protect_flagship":
			_execute_protect_flagship_command(fleet)
		"coordinate_attack":
			_execute_coordinate_attack_command(fleet, target)
		"form_up":
			_execute_form_up_command(fleet)
		"patrol":
			_execute_patrol_command(fleet, target) # target is patrol path/area

func handle_enemy_spotted(fleet: Fleet, spotter: Ship, enemy: Ship) -> void:
	# Determine how to respond based on current strategy and enemy threat
	match current_strategy:
		StrategyType.DEFENSIVE:
			# Defensive fleets protect themselves but don't seek conflict
			if _is_imminent_threat(fleet, enemy):
				_execute_defend_command(fleet, enemy)
		
		StrategyType.AGGRESSIVE:
			# Aggressive fleets engage enemies directly
			_execute_attack_command(fleet, enemy)
		
		StrategyType.EVASIVE:
			# Evasive fleets run away
			if _is_imminent_threat(fleet, enemy):
				_execute_retreat_command(fleet, _find_retreat_position(fleet, enemy))
		
		StrategyType.PATROL:
			# Patrol fleets engage if the enemy is within their patrol area
			if _is_imminent_threat(fleet, enemy):
				_execute_attack_command(fleet, enemy)
		
		StrategyType.ESCORT:
			# Escort fleets protect their charge
			_execute_protect_flagship_command(fleet)
			
			# If the enemy is too close to charge, engage
			if enemy.global_position.distance_to(fleet.flagship.global_position) < 500:
				_execute_attack_command(fleet, enemy)
		
		StrategyType.TRADE:
			# Trade fleets prioritize escape
			_execute_retreat_command(fleet, _find_retreat_position(fleet, enemy))

func handle_member_taking_damage(fleet: Fleet, damaged_ship: Ship, damage_data) -> void:
	# Respond to a fleet member taking damage
	
	# If flagship is taking damage, prioritize its protection
	if damaged_ship == fleet.flagship:
		_execute_protect_flagship_command(fleet)
		
		# If serious damage and attacker known, retaliate
		if damage_data.has("attacker") and is_instance_valid(damage_data.attacker):
			if current_strategy != StrategyType.EVASIVE:
				_execute_attack_command(fleet, damage_data.attacker)
			else:
				_execute_retreat_command(fleet, _find_retreat_position(fleet, damage_data.attacker))
	else:
		# Regular member taking damage
		if damage_data.has("attacker") and is_instance_valid(damage_data.attacker):
			# Send nearest ships to help if appropriate for strategy
			if current_strategy in [StrategyType.AGGRESSIVE, StrategyType.DEFENSIVE, StrategyType.PATROL]:
				_send_assistance(fleet, damaged_ship, damage_data.attacker)

func handle_member_low_health(fleet: Fleet, damaged_ship: Ship, health_data) -> void:
	# Respond to a fleet member having low health
	
	# If flagship has low health, consider retreat
	if damaged_ship == fleet.flagship:
		if health_data.health_percentage < 0.3:  # Critical health
			if current_strategy != StrategyType.AGGRESSIVE:
				_execute_retreat_command(fleet)
			else:
				# Even aggressive fleets retreat at very low health
				if health_data.health_percentage < 0.15:
					_execute_retreat_command(fleet)
	else:
		# Regular member with low health
		# Allow it to retreat individually
		if damaged_ship.pilot and damaged_ship.pilot is AI_Pilot:
			damaged_ship.pilot._change_state(AI_Pilot.State.FLEE)

func handle_target_acquired(fleet: Fleet, ship: Ship, target_data) -> void:
	# Fleet member has acquired a target
	
	# If flagship acquires target, consider coordinating attack
	if ship == fleet.flagship and current_strategy in [StrategyType.AGGRESSIVE, StrategyType.PATROL]:
		_execute_coordinate_attack_command(fleet, target_data.target)

func handle_assistance_request(fleet: Fleet, ship: Ship, assistance_data) -> void:
	# Fleet member needs assistance
	
	# If flagship needs help, prioritize
	if ship == fleet.flagship:
		_execute_protect_flagship_command(fleet)
	else:
		# Regular member needs help
		_send_assistance(fleet, ship, null)

func handle_member_retreat(fleet: Fleet, ship: Ship, retreat_data) -> void:
	# Fleet member is retreating
	
	# If flagship is retreating, whole fleet should follow
	if ship == fleet.flagship:
		_execute_retreat_command(fleet, retreat_data.retreat_point if retreat_data.has("retreat_point") else null)

func should_coordinate_attack(target) -> bool:
	# Determine if a coordinated attack is appropriate
	if not target or not is_instance_valid(target):
		return false
	
	# Base decision on current strategy
	match current_strategy:
		StrategyType.AGGRESSIVE:
			return true
		StrategyType.DEFENSIVE:
			return tactical_assessment.advantage_level > 0.3
		StrategyType.PATROL:
			return tactical_assessment.advantage_level > 0.2
		StrategyType.ESCORT:
			return tactical_assessment.advantage_level > 0.5
		_:
			return false

func assess_tactical_situation(fleet: Fleet) -> Dictionary:
	# Update the tactical assessment based on current situation
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Get fleet information
	var fleet_strength = fleet.get_strength()
	var fleet_position = fleet.get_average_position()
	
	# Scan for threats
	var threats = _find_threats(fleet)
	tactical_assessment.threats = threats
	
	# Calculate total threat strength
	var total_threat_strength = 0.0
	for threat in threats:
		if is_instance_valid(threat):
			# Estimate threat strength
			var threat_strength = 1.0  # Default
			
			# If threat is in a fleet, use fleet strength
			var threat_fleet = null
			if threat.has_meta("fleet") and is_instance_valid(threat.get_meta("fleet")):
				threat_fleet = threat.get_meta("fleet")
				threat_strength = threat_fleet.get_strength()
			
			total_threat_strength += threat_strength
	
	# Calculate advantage level (-1.0 to 1.0, positive means advantage)
	var advantage_level = 0.0
	if threats.size() > 0 and total_threat_strength > 0:
		advantage_level = (fleet_strength - total_threat_strength) / max(fleet_strength, total_threat_strength)
	else:
		advantage_level = 1.0  # No threats means full advantage
	
	tactical_assessment.advantage_level = advantage_level
	
	# Recommend action based on advantage and strategy
	var recommended_action = ""
	match current_strategy:
		StrategyType.AGGRESSIVE:
			if advantage_level > -0.3:  # Even at slight disadvantage, attack
				recommended_action = "attack"
			else:
				recommended_action = "retreat"
		
		StrategyType.DEFENSIVE:
			if advantage_level > 0.3:
				recommended_action = "attack"
			elif advantage_level > -0.3:
				recommended_action = "defend"
			else:
				recommended_action = "retreat"
		
		StrategyType.EVASIVE:
			if advantage_level > 0.5:  # Major advantage needed to consider attack
				recommended_action = "attack"
			else:
				recommended_action = "retreat"
		
		StrategyType.PATROL:
			if advantage_level > 0.1:
				recommended_action = "attack"
			elif advantage_level > -0.2:
				recommended_action = "defend"
			else:
				recommended_action = "retreat"
		
		StrategyType.ESCORT:
			recommended_action = "defend"  # Default to defense
			
			# If major advantage and threats are close to escort target
			if advantage_level > 0.4 and threats.size() > 0:
				var threat_close_to_flagship = false
				for threat in threats:
					if is_instance_valid(threat) and is_instance_valid(fleet.flagship):
						if threat.global_position.distance_to(fleet.flagship.global_position) < 800:
							threat_close_to_flagship = true
							break
				
				if threat_close_to_flagship:
					recommended_action = "attack"
		
		StrategyType.TRADE:
			if threats.size() > 0:
				recommended_action = "retreat"
			else:
				recommended_action = "trade_route"
	
	tactical_assessment.recommended_action = recommended_action
	tactical_assessment.last_update_time = current_time
	
	return tactical_assessment

# Command implementation methods
func _execute_attack_command(fleet: Fleet, target) -> void:
	if not target or not is_instance_valid(target):
		return
	
	# Assign target to all ships in fleet
	for ship in fleet.member_ships:
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			pilot.target = target
			pilot._change_state(AI_Pilot.State.CHASE)

func _execute_defend_command(fleet: Fleet, target = null) -> void:
	# If no specific target, defend the flagship
	if not target or not is_instance_valid(target):
		target = fleet.flagship
	
	# Form a defensive perimeter around the target
	var ships = fleet.member_ships
	var ship_count = ships.size()
	
	# Position ships in a circle around the target
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == target:  # Skip the target itself
			continue
		
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			# Calculate position in the circle
			var angle = 2 * PI * i / ship_count
			var defend_radius = 300.0
			var defend_pos = Vector2(cos(angle), sin(angle)) * defend_radius
			
			# Set defensive position
			ship.set_meta("defend_position", target.global_position + defend_pos)
			
			# Set the ship to patrol around this position
			pilot.patrol_points = [target.global_position + defend_pos]
			pilot.current_patrol_index = 0
			pilot._change_state(AI_Pilot.State.PATROL)

func _execute_move_to_command(fleet: Fleet, position: Vector2) -> void:
	# Move the entire fleet to a position
	
	# First, have the flagship move to the position
	if fleet.flagship and fleet.flagship.pilot and fleet.flagship.pilot is AI_Pilot:
		fleet.flagship.pilot.patrol_points = [position]
		fleet.flagship.pilot.current_patrol_index = 0
		fleet.flagship.pilot._change_state(AI_Pilot.State.PATROL)
	
	# The rest of the fleet will follow in formation automatically

func _execute_scatter_command(fleet: Fleet) -> void:
	# Each ship scatters in a different direction
	var center = fleet.get_average_position()
	
	for ship in fleet.member_ships:
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			# Calculate a random direction away from center
			var scatter_angle = randf_range(0, 2 * PI)
			var scatter_distance = randf_range(800, 1500)
			var scatter_pos = center + Vector2(cos(scatter_angle), sin(scatter_angle)) * scatter_distance
			
			# Set the ship to move to this position
			pilot.patrol_points = [scatter_pos]
			pilot.current_patrol_index = 0
			pilot._change_state(AI_Pilot.State.PATROL)

func _execute_retreat_command(fleet: Fleet, retreat_position = null) -> void:
	# Retreat the entire fleet
	
	# If no retreat position specified, find one
	if retreat_position == null:
		# Get average position of threats
		var threats_center = Vector2.ZERO
		var threat_count = 0
		
		for threat in tactical_assessment.threats:
			if is_instance_valid(threat):
				threats_center += threat.global_position
				threat_count += 1
		
		if threat_count > 0:
			threats_center /= threat_count
			
			# Retreat in opposite direction from threats
			var fleet_position = fleet.get_average_position()
			var retreat_direction = (fleet_position - threats_center).normalized()
			retreat_position = fleet_position + retreat_direction * 2000  # Retreat 2000 units away
		else:
			# No threats, just pick a point away from current position
			var retreat_angle = randf_range(0, 2 * PI)
			retreat_position = fleet.get_average_position() + Vector2(cos(retreat_angle), sin(retreat_angle)) * 2000
	
	# Set all ships to flee to the retreat position
	for ship in fleet.member_ships:
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			pilot.patrol_points = [retreat_position]
			pilot.current_patrol_index = 0
			pilot._change_state(AI_Pilot.State.FLEE)

func _execute_protect_flagship_command(fleet: Fleet) -> void:
	# Similar to defend, but specifically for protecting the flagship
	if not fleet.flagship:
		return
	
	# Form a tight protective formation around the flagship
	var ships = fleet.member_ships
	var protect_radius = 200.0  # Tighter than defend
	
	for i in range(ships.size()):
		var ship = ships[i]
		if ship == fleet.flagship:
			continue
		
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			# Calculate position around flagship
			var angle = 2 * PI * i / ships.size()
			var protect_pos = Vector2(cos(angle), sin(angle)) * protect_radius
			
			# Set protective position
			ship.set_meta("protect_position", fleet.flagship.global_position + protect_pos)
			
			# If there are threats, have some ships engage them
			if tactical_assessment.threats.size() > 0 and i % 2 == 0:  # Every other ship
				pilot.target = tactical_assessment.threats[0]
				pilot._change_state(AI_Pilot.State.ATTACK)
			else:
				# Others stay in protective formation
				pilot.patrol_points = [fleet.flagship.global_position + protect_pos]
				pilot.current_patrol_index = 0
				pilot._change_state(AI_Pilot.State.PATROL)

func _execute_coordinate_attack_command(fleet: Fleet, target) -> void:
	if not target or not is_instance_valid(target):
		return
	
	# Use the communication system to coordinate the attack
	fleet.communication_system.coordinate_attack(fleet, target)

func _execute_form_up_command(fleet: Fleet) -> void:
	# Have all ships return to formation
	fleet.formation_manager.calculate_formation_positions(fleet)
	
	# Flagship stays put, others return to formation
	for ship in fleet.member_ships:
		if ship != fleet.flagship:
			var pilot = ship.pilot
			if pilot and pilot is AI_Pilot:
				pilot._change_state(AI_Pilot.State.IDLE)  # Temporarily idle to reform

func _execute_patrol_command(fleet: Fleet, patrol_points) -> void:
	# Set the fleet to patrol along the given points
	if not patrol_points or patrol_points.size() == 0:
		return
	
	# Set flagship to patrol these points
	if fleet.flagship and fleet.flagship.pilot and fleet.flagship.pilot is AI_Pilot:
		fleet.flagship.pilot.patrol_points = patrol_points
		fleet.flagship.pilot.current_patrol_index = 0
		fleet.flagship.pilot._change_state(AI_Pilot.State.PATROL)
	
	# The rest of the fleet will follow in formation

# Helper methods
func _find_threats(fleet: Fleet) -> Array:
	# Find potential threats to the fleet
	# This is a simplified implementation - would be expanded with better threat detection
	var threats = []
	var detect_range = 1500.0  # Base detection range
	
	# Get the fleet's average position
	var fleet_position = fleet.get_average_position()
	
	# For each ship in the fleet, check for visible enemies
	for ship in fleet.member_ships:
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			# Use the pilot's detection range if available
			var ship_detect_range = pilot.detection_range if pilot.has("detection_range") else detect_range
			
			# Check visible ships
			if pilot.has("visible_ships"):
				for visible_ship in pilot.visible_ships:
					if is_instance_valid(visible_ship) and visible_ship not in fleet.member_ships:
						# Determine if this ship is a threat
						var is_threat = false
						
						# Check pilot type to determine threat
						for child in visible_ship.get_children():
							if (current_strategy in [StrategyType.AGGRESSIVE, StrategyType.DEFENSIVE, StrategyType.PATROL] and child is Pirate_Pilot) or \
							   (current_strategy == StrategyType.AGGRESSIVE and child is Police_Pilot) or \
							   child is Player:  # Player is always considered a potential threat
								is_threat = true
								break
						
						if is_threat and visible_ship not in threats:
							threats.append(visible_ship)
	
	# Sort threats by priority
	if threats.size() > 0:
		threats.sort_custom(Callable(self, "_sort_threats_by_priority").call(fleet))
	
	return threats

func _is_imminent_threat(fleet: Fleet, enemy: Ship) -> bool:
	# Check if the enemy is close enough to be considered an imminent threat
	var threat_distance = 800.0  # Base imminent threat distance
	
	# Calculate distance to fleet center
	var fleet_position = fleet.get_average_position()
	var distance = fleet_position.distance_to(enemy.global_position)
	
	# Calculate distance to flagship (more important)
	var flagship_distance = INF
	if fleet.flagship:
		flagship_distance = fleet.flagship.global_position.distance_to(enemy.global_position)
	
	# Check if enemy is an imminent threat based on distance
	return distance < threat_distance or flagship_distance < threat_distance * 1.5

func _find_retreat_position(fleet: Fleet, threat: Ship = null) -> Vector2:
	# Find a good position to retreat to
	var fleet_position = fleet.get_average_position()
	
	if threat and is_instance_valid(threat):
		# Retreat away from the threat
		var retreat_direction = (fleet_position - threat.global_position).normalized()
		return fleet_position + retreat_direction * 2000  # Retreat 2000 units away
	else:
		# No specific threat, retreat in a random direction
		var retreat_angle = randf_range(0, 2 * PI)
		return fleet_position + Vector2(cos(retreat_angle), sin(retreat_angle)) * 2000

func _send_assistance(fleet: Fleet, ship_in_need: Ship, attacker: Ship = null) -> void:
	# Send nearby fleet members to assist
	var max_assist_distance = 1200.0
	var ships_to_send = 2  # Number of ships to send
	
	var available_ships = []
	for fleet_ship in fleet.member_ships:
		if fleet_ship != ship_in_need and fleet_ship != fleet.flagship:
			var distance = fleet_ship.global_position.distance_to(ship_in_need.global_position)
			if distance < max_assist_distance:
				available_ships.append({"ship": fleet_ship, "distance": distance})
	
	# Sort by distance
	available_ships.sort_custom(Callable(self, "_sort_by_distance"))
	
	# Send the closest ships
	var ships_sent = 0
	for ship_data in available_ships:
		if ships_sent >= ships_to_send:
			break
		
		var ship = ship_data.ship
		var pilot = ship.pilot
		
		if pilot and pilot is AI_Pilot:
			if attacker and is_instance_valid(attacker):
				# If there's an attacker, target it
				pilot.target = attacker
				pilot._change_state(AI_Pilot.State.CHASE)
			else:
				# Otherwise, move to assist position
				pilot.patrol_points = [ship_in_need.global_position]
				pilot.current_patrol_index = 0
				pilot._change_state(AI_Pilot.State.PATROL)
			
			ships_sent += 1

static func _sort_by_distance(a, b) -> bool:
	return a.distance < b.distance

static func _sort_threats_by_priority(a, b, fleet) -> bool:
	# Calculate priority scores for threats
	var a_score = _calculate_threat_priority(a, fleet)
	var b_score = _calculate_threat_priority(b, fleet)
	
	return a_score > b_score

static func _calculate_threat_priority(threat: Ship, fleet: Fleet) -> float:
	# Calculate priority score for a threat
	var priority = 0.0
	
	# Distance factor (closer = higher priority)
	var fleet_position = fleet.get_average_position()
	var distance = fleet_position.distance_to(threat.global_position)
	var max_distance = 2000.0
	var distance_factor = 1.0 - min(distance / max_distance, 1.0)
	
	# Threat type factor
	var threat_type_factor = 0.5  # Default
	
	# Check pilot type to determine threat factor
	for child in threat.get_children():
		if child is Pirate_Pilot:
			threat_type_factor = 0.8  # Pirates are high threat
			break
		elif child is Police_Pilot:
			threat_type_factor = 0.6  # Police are medium threat
			break
		elif child is Player:
			threat_type_factor = 1.0  # Player is highest threat
			break
	
	# Combine factors
	priority = distance_factor * 0.6 + threat_type_factor * 0.4
	
	return priority

func set_strategy(strategy_type: int) -> void:
	current_strategy = strategy_type
