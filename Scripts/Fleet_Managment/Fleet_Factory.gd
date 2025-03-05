extends Node
class_name FleetFactory

# Faction identifiers
enum FleetFaction {
	PLAYER,
	TRADER,
	PIRATE,
	POLICE
}

# Fleet Factory for creating different types of fleets
static func create_fleet(faction: int) -> Fleet:
	# Create base fleet
	var fleet = Fleet.new()
	
	# Add controller based on faction
	match faction:
		FleetFaction.TRADER:
			var controller = TraderFleetController.new(fleet)
			fleet.add_child(controller)
		FleetFaction.PIRATE:
			var controller = PirateFleetController.new(fleet)
			fleet.add_child(controller)
		FleetFaction.POLICE:
			var controller = PoliceFleetController.new(fleet)
			fleet.add_child(controller)
		FleetFaction.PLAYER:
			var controller = PlayerFleetCommander.new()
			fleet.add_child(controller)
			controller.set_fleet(fleet)
	
	return fleet

# Create a fleet with ships
static func create_fleet_with_ships(faction: int, ship_count: int = 3, flagship_id: String = "") -> Fleet:
	var fleet = create_fleet(faction)
	
	# Add ships based on faction
	match faction:
		FleetFaction.TRADER:
			_add_trader_ships(fleet, ship_count, flagship_id)
		FleetFaction.PIRATE:
			_add_pirate_ships(fleet, ship_count, flagship_id)
		FleetFaction.POLICE:
			_add_police_ships(fleet, ship_count, flagship_id)
		FleetFaction.PLAYER:
			_add_player_ships(fleet, ship_count, flagship_id)
	
	return fleet

# Helper methods to add specific ship types
static func _add_trader_ships(fleet: Fleet, count: int, flagship_id: String = "") -> void:
	# Add ships to the fleet with trader pilots
	var flagship = _create_ship(flagship_id, "trader")
	fleet.add_ship(flagship)
	
	# Add additional ships
	for i in range(count - 1):
		var ship = _create_ship("", "trader")
		fleet.add_ship(ship)

static func _add_pirate_ships(fleet: Fleet, count: int, flagship_id: String = "") -> void:
	# Add ships to the fleet with pirate pilots
	var flagship = _create_ship(flagship_id, "pirate")
	fleet.add_ship(flagship)
	
	# Add additional ships
	for i in range(count - 1):
		var ship = _create_ship("", "pirate")
		fleet.add_ship(ship)

static func _add_police_ships(fleet: Fleet, count: int, flagship_id: String = "") -> void:
	# Add ships to the fleet with police pilots
	var flagship = _create_ship(flagship_id, "police")
	fleet.add_ship(flagship)
	
	# Add additional ships
	for i in range(count - 1):
		var ship = _create_ship("", "police")
		fleet.add_ship(ship)

static func _add_player_ships(fleet: Fleet, count: int, flagship_id: String = "") -> void:
	# First add player's ship as flagship
	var player_ship = _find_player_ship()
	
	if player_ship:
		fleet.add_ship(player_ship)
	else:
		# No player ship found, create one
		var flagship = _create_ship(flagship_id, "player")
		fleet.add_ship(flagship)
	
	# Add AI escort ships
	for i in range(count - 1):
		var ship = _create_ship("", "escort")
		fleet.add_ship(ship)

# Helper to create a single ship
static func _create_ship(ship_id: String = "", pilot_type: String = "") -> Ship:
	var ship: Ship
	
	# Get reference to the ItemDataSystem instance
	var item_system = ItemDataSystem.instance
	
	# If specific ship ID is provided, use it
	if ship_id != "":
		ship = item_system.create_ship(ship_id)
		if not ship:
			# Fall back to default method if ID not found
			ship = _create_default_ship()
	else:
		# Select ship based on faction/type
		var faction_filter = ""
		match pilot_type:
			"trader":
				faction_filter = "trader"
			"pirate":
				faction_filter = "pirate"
			"police":
				faction_filter = "police"
			_:
				faction_filter = "neutral"  # Default for player/escort
		
		# Try to find appropriate ship by faction
		var ship_ids = []
		
		# First try exact faction match
		ship_ids = item_system.get_filtered_items("ship", "faction", faction_filter)
		
		# If no ships found, try neutral ships as fallback
		if ship_ids.size() == 0 and faction_filter != "neutral":
			ship_ids = item_system.get_filtered_items("ship", "faction", "neutral")
		
		# If still no ships found, get any available ship
		if ship_ids.size() == 0:
			ship_ids = item_system.get_item_ids("ship")
		
		# Create ship from a random ID in the filtered list
		if ship_ids.size() > 0:
			var random_id = ship_ids[randi() % ship_ids.size()]
			ship = item_system.create_ship(random_id)
		else:
			# Fall back to default if no ship definitions found
			ship = _create_default_ship()
	
	# Add appropriate pilot
	match pilot_type:
		"trader":
			var trader_pilot = TraderPilot.new()
			ship.add_child(trader_pilot)
		"pirate":
			var pirate_pilot = PiratePilot.new()
			ship.add_child(pirate_pilot)
		"police":
			var police_pilot = PolicePilot.new()
			ship.add_child(police_pilot)
		"escort":
			var escort_pilot = AIPilot.new()
			escort_pilot.aggressiveness = 0.6
			ship.add_child(escort_pilot)
		"player":
			var player = Player.new()
			ship.add_child(player)
	
	# Ensure ship has necessary equipment
	_ensure_ship_has_equipment(ship)
	
	return ship

# Create a default ship if database fails
static func _create_default_ship() -> Ship:
	var ship = Ship.new()
	ship.name = "Generic Ship"
	ship.max_velocity = 1000
	ship.max_hull_health = 100
	ship.current_hull_health = 100
	ship.faction = "neutral"
	return ship

# Ensure ship has necessary equipment
static func _ensure_ship_has_equipment(ship: Ship) -> void:
	var item_system = ItemDataSystem.instance
	
	# Check if ship has thruster
	if not ship.is_thruster_installed():
		var thruster_ids = item_system.get_item_ids("thruster")
		if thruster_ids.size() > 0:
			var thruster = item_system.create_thruster(thruster_ids[0])
			ship.add_child(thruster)
		else:
			# Fallback
			var thruster = Thruster.new()
			thruster.thrust = 25
			ship.add_child(thruster)
	
	# Check if ship has turning
	if not ship.is_turning_installed():
		var turning_ids = item_system.get_item_ids("turning")
		if turning_ids.size() > 0:
			var turning = item_system.create_turning(turning_ids[0])
			ship.add_child(turning)
		else:
			# Fallback
			var turning = Turning.new()
			turning.thrust = 4
			ship.add_child(turning)

# Find the player ship in the scene
static func _find_player_ship() -> Ship:
	# Try to find the player first
	var players = Engine.get_main_loop().get_nodes_in_group("Player")
	
	for player_node in players:
		if player_node is Player and player_node.ship:
			return player_node.ship
	
	return null

# Create a fleet for an existing ship
static func create_fleet_for_ship(ship: Ship, faction: int, additional_ships: int = 2) -> Fleet:
	var fleet = create_fleet(faction)
	
	# Add the existing ship as flagship
	fleet.add_ship(ship)
	
	# Determine pilot type based on faction
	var pilot_type = ""
	match faction:
		FleetFaction.TRADER:
			pilot_type = "trader"
		FleetFaction.PIRATE:
			pilot_type = "pirate"
		FleetFaction.POLICE:
			pilot_type = "police"
		FleetFaction.PLAYER:
			pilot_type = "escort"
	
	# Add additional ships based on faction
	for i in range(additional_ships):
		var escort = _create_ship("", pilot_type)
		fleet.add_ship(escort)
	
	return fleet
