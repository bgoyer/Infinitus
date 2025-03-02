extends Node
class_name FleetCommunicationSystem

# Message types
enum MessageType {
	ENEMY_SPOTTED,
	TAKING_DAMAGE,
	LOW_HEALTH,
	TARGET_ACQUIRED,
	FORMATION_CHANGE,
	COMMAND_RECEIVED,
	RESOURCE_FOUND,
	ASSISTANCE_NEEDED,
	RETREAT_INITIATED
}

# Signal for message broadcast
signal message_broadcast(sender, message_type, data)

# History of recent messages (for debugging and AI decision making)
var message_history: Array = []
# Maximum history size
var max_history_size: int = 20

func _init() -> void:
	# Connect to our own broadcast signal
	connect("message_broadcast", Callable(self, "_on_message_broadcast"))

func broadcast_message(sender: Ship, message_type: int, data = null) -> void:
	# Add timestamp to the message data
	var message_data = {
		"content": data,
		"timestamp": Time.get_ticks_msec() / 1000.0
	}
	
	# Broadcast the message
	emit_signal("message_broadcast", sender, message_type, message_data)

func _on_message_broadcast(sender: Ship, message_type: int, message_data) -> void:
	# Store in history
	var history_entry = {
		"sender": sender,
		"type": message_type,
		"data": message_data,
		"time": Time.get_ticks_msec() / 1000.0
	}
	
	message_history.append(history_entry)
	
	# Limit history size
	if message_history.size() > max_history_size:
		message_history.pop_front()
	
	# Process the message
	var fleet = sender.get_meta("fleet") if sender.has_meta("fleet") else null
	if fleet:
		process_message(fleet, sender, message_type, message_data.content)

func process_message(fleet: Fleet, sender: Ship, message_type: int, data = null) -> void:
	match message_type:
		MessageType.ENEMY_SPOTTED:
			_handle_enemy_spotted(fleet, sender, data)
		MessageType.TAKING_DAMAGE:
			_handle_taking_damage(fleet, sender, data)
		MessageType.LOW_HEALTH:
			_handle_low_health(fleet, sender, data)
		MessageType.TARGET_ACQUIRED:
			_handle_target_acquired(fleet, sender, data)
		MessageType.ASSISTANCE_NEEDED:
			_handle_assistance_needed(fleet, sender, data)
		MessageType.RETREAT_INITIATED:
			_handle_retreat_initiated(fleet, sender, data)

func _handle_enemy_spotted(fleet: Fleet, sender: Ship, enemy: Ship) -> void:
	# Validate that enemy still exists
	if not is_instance_valid(enemy):
		return
	
	# Notify fleet strategy about the enemy
	fleet.strategy_system.handle_enemy_spotted(fleet, sender, enemy)
	
	# Determine if we should alert the other fleet members
	# This depends on the fleet's strategy and the sender's role
	var is_flagship = sender == fleet.flagship
	var is_imminent_threat = enemy.global_position.distance_to(sender.global_position) < 500
	
	if is_flagship or is_imminent_threat:
		# Alert other fleet members
		_alert_fleet_members(fleet, enemy, sender)

func _handle_taking_damage(fleet: Fleet, sender: Ship, damage_data) -> void:
	# Inform strategy system about damage
	fleet.strategy_system.handle_member_taking_damage(fleet, sender, damage_data)
	
	# If flagship is taking damage, prioritize protection
	if sender == fleet.flagship:
		_alert_fleet_members(fleet, damage_data.attacker if damage_data.has("attacker") else null, sender)

func _handle_low_health(fleet: Fleet, sender: Ship, health_data) -> void:
	# Ship reporting low health - might need protection or to retreat
	fleet.strategy_system.handle_member_low_health(fleet, sender, health_data)
	
	# If it's the flagship, the whole fleet might need to protect it or retreat
	if sender == fleet.flagship:
		if health_data.health_percentage < 0.3:  # Critical health
			fleet.execute_command("protect_flagship")
			
			if health_data.health_percentage < 0.15:  # Emergency retreat
				fleet.execute_command("retreat")

func _handle_target_acquired(fleet: Fleet, sender: Ship, target_data) -> void:
	# Ship has acquired a target - inform strategy system
	fleet.strategy_system.handle_target_acquired(fleet, sender, target_data)
	
	# If flagship acquires target, might want to coordinate attack
	if sender == fleet.flagship and fleet.strategy_system.should_coordinate_attack(target_data.target):
		fleet.execute_command("coordinate_attack", target_data.target)

func _handle_assistance_needed(fleet: Fleet, sender: Ship, assistance_data) -> void:
	# Ship needs assistance - could be under attack, stuck, etc.
	fleet.strategy_system.handle_assistance_request(fleet, sender, assistance_data)
	
	# If high priority assistance needed, redirect nearest ships
	if assistance_data.has("priority") and assistance_data.priority > 0.7:
		_dispatch_assistance(fleet, sender, assistance_data)

func _handle_retreat_initiated(fleet: Fleet, sender: Ship, retreat_data) -> void:
	# Ship is retreating - might need cover or the whole fleet might need to retreat
	if sender == fleet.flagship:
		# Flagship is retreating - whole fleet should follow
		fleet.execute_command("retreat", retreat_data.retreat_point if retreat_data.has("retreat_point") else null)
	else:
		# Individual ship retreating - might need cover
		fleet.strategy_system.handle_member_retreat(fleet, sender, retreat_data)

func _alert_fleet_members(fleet: Fleet, target: Ship, alerting_ship: Ship) -> void:
	# Alert all fleet members about a threat or target
	for ship in fleet.member_ships:
		if ship != alerting_ship and ship.pilot:
			# Set the target for all ship pilots
			if ship.pilot is AI_Pilot:
				# Different pilots might respond differently based on their type
				if target != null and is_instance_valid(target):
					# Determine response based on pilot type and distance
					var distance = ship.global_position.distance_to(target.global_position)
					
					if ship.pilot is Police_Pilot:
						if distance < 1500:  # Within reasonable response range
							ship.pilot.target = target
							ship.pilot._change_state(AI_Pilot.State.CHASE)
					elif ship.pilot is Pirate_Pilot:
						if distance < 1200:  # Pirates slightly less coordinated
							ship.pilot.target = target
							ship.pilot._change_state(AI_Pilot.State.CHASE)
					elif ship.pilot is Trader_Pilot:
						# Traders will only respond if really close or if it's the flagship calling
						if distance < 800 or alerting_ship == fleet.flagship:
							ship.pilot.target = target
							# Traders prefer to flee rather than engage
							ship.pilot._change_state(AI_Pilot.State.FLEE)

func _dispatch_assistance(fleet: Fleet, ship_in_need: Ship, assistance_data) -> void:
	# Find nearby ships that can help
	var nearby_ships = []
	var max_assist_distance = 1500.0
	
	for ship in fleet.member_ships:
		if ship != ship_in_need:
			var distance = ship.global_position.distance_to(ship_in_need.global_position)
			if distance < max_assist_distance:
				nearby_ships.append({"ship": ship, "distance": distance})
	
	# Sort by distance
	nearby_ships.sort_custom(Callable(self, "_sort_by_distance"))
	
	# Dispatch up to 2 ships for assistance
	var ships_to_dispatch = min(2, nearby_ships.size())
	for i in range(ships_to_dispatch):
		var ship = nearby_ships[i].ship
		if ship.pilot and ship.pilot is AI_Pilot:
			# Set ship to assist
			ship.pilot.set_meta("assisting", ship_in_need)
			
			# If there's an attacker, target it
			if assistance_data.has("attacker") and is_instance_valid(assistance_data.attacker):
				ship.pilot.target = assistance_data.attacker
				ship.pilot._change_state(AI_Pilot.State.CHASE)
			else:
				# Just move to the ship's position
				var approach_position = ship_in_need.global_position
				ship.set_meta("approach_position", approach_position)
				ship.pilot._change_state(AI_Pilot.State.PATROL)  # Will patrol to position

static func _sort_by_distance(a, b) -> bool:
	return a.distance < b.distance

func get_recent_messages(message_type = null, limit = 5) -> Array:
	# Get recent messages, optionally filtered by type
	var filtered = []
	var count = 0
	
	for i in range(message_history.size() - 1, -1, -1):
		var msg = message_history[i]
		if message_type == null or msg.type == message_type:
			filtered.append(msg)
			count += 1
			if count >= limit:
				break
	
	return filtered

func coordinate_attack(fleet: Fleet, target: Ship) -> void:
	# Assign different ships to different attack vectors
	var ships = fleet.member_ships
	var ship_count = ships.size()
	
	# Create attack vectors
	var vectors = []
	for i in range(min(4, ship_count)):
		var angle = 2 * PI * i / 4  # 4 primary attack vectors
		var attack_vector = Vector2(cos(angle), sin(angle)).normalized()
		vectors.append(attack_vector)
	
	# Assign ships to vectors
	for i in range(ships.size()):
		var ship = ships[i]
		var vector_idx = i % vectors.size()
		var vector = vectors[vector_idx]
		
		# Set attack position offset from target
		var attack_distance = 300.0  # Base attack distance
		var attack_position = target.global_position + vector * attack_distance
		
		# Assign to ship
		ship.set_meta("attack_position", attack_position)
		
		# Tell ship to attack
		var pilot = ship.pilot
		if pilot and pilot is AI_Pilot:
			pilot.target = target
			pilot._change_state(AI_Pilot.State.ATTACK)
