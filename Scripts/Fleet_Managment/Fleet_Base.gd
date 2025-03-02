extends Node2D
class_name Fleet

# Member ships in this fleet
var member_ships: Array[Ship] = []
# The flagship or leader of the fleet
var flagship: Ship
# The commander of this fleet (Player or AI_Pilot)
var commander = null
# Reference to specialized systems
var formation_manager: FleetFormationManager
var communication_system: FleetCommunicationSystem
var strategy_system: FleetStrategySystem

# Signals
signal ship_added(ship)
signal ship_removed(ship)
signal flagship_changed(ship)
signal fleet_command_issued(command, target)

func _init() -> void:
	formation_manager = FleetFormationManager.new()
	communication_system = FleetCommunicationSystem.new()
	strategy_system = FleetStrategySystem.new()
	add_child(formation_manager)
	add_child(communication_system)
	add_child(strategy_system)

func _process(delta: float) -> void:
	# Update formation positions if needed
	if member_ships.size() > 1 and flagship:
		formation_manager.update_formation_positions(self, delta)

func add_ship(ship: Ship) -> void:
	if ship not in member_ships:
		member_ships.append(ship)
		# If this is the first ship, make it the flagship
		if member_ships.size() == 1:
			set_flagship(ship)
		# Assign ship to this fleet
		ship.set_meta("fleet", self)
		# Signal that ship was added
		emit_signal("ship_added", ship)
		
		# If the ship has a pilot, inform it of the fleet
		var pilot = ship.pilot
		if pilot:
			pilot.set_meta("fleet", self)

func remove_ship(ship: Ship) -> void:
	if ship in member_ships:
		member_ships.erase(ship)
		ship.set_meta("fleet", null)
		
		# Remove fleet reference from pilot
		var pilot = ship.pilot
		if pilot and pilot.has_meta("fleet"):
			pilot.remove_meta("fleet")
			
		# If removing the flagship, assign a new one if possible
		if ship == flagship and member_ships.size() > 0:
			set_flagship(member_ships[0])
		# Signal that ship was removed
		emit_signal("ship_removed", ship)

func set_flagship(ship: Ship) -> void:
	if ship in member_ships:
		flagship = ship
		# Set flagship meta on the ship
		ship.set_meta("is_flagship", true)
		# Signal that flagship changed
		emit_signal("flagship_changed", ship)

func get_strength() -> float:
	# Calculate total fleet strength based on ships and equipment
	var total_strength = 0.0
	for ship in member_ships:
		# Basic strength calculation - could be expanded
		var ship_strength = 1.0
		
		# Factor in equipment
		if ship.is_thruster_installed():
			ship_strength += ship.get_thruster().thrust / 10.0
		
		if ship.is_turning_installed():
			ship_strength += ship.get_turning().thrust / 10.0
			
		# Factor in ship type (could be expanded with more ship classes)
		if ship is Sparrow:
			ship_strength *= 1.2
			
		total_strength += ship_strength
	
	return total_strength

func execute_command(command: String, target = null) -> void:
	# Emit signal for logging/UI
	emit_signal("fleet_command_issued", command, target)
	
	# Delegate to the strategy system
	strategy_system.execute_command(self, command, target)

func get_average_position() -> Vector2:
	if member_ships.size() == 0:
		return Vector2.ZERO
		
	var total_pos = Vector2.ZERO
	for ship in member_ships:
		total_pos += ship.global_position
	
	return total_pos / member_ships.size()

func get_fleet_radius() -> float:
	# Calculate the radius of the fleet (distance from center to furthest ship)
	var center = get_average_position()
	var max_distance = 0.0
	
	for ship in member_ships:
		var distance = center.distance_to(ship.global_position)
		max_distance = max(max_distance, distance)
	
	return max_distance
