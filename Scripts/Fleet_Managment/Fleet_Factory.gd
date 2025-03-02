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
static func create_fleet_with_ships(faction: int, ship_count: int = 3, flagship_scene: PackedScene = null) -> Fleet:
	var fleet = create_fleet(faction)
	
	# Add ships based on faction
	match faction:
		FleetFaction.TRADER:
			_add_trader_ships(fleet, ship_count, flagship_scene)
		FleetFaction.PIRATE:
			_add_pirate_ships(fleet, ship_count, flagship_scene)
		FleetFaction.POLICE:
			_add_police_ships(fleet, ship_count, flagship_scene)
		FleetFaction.PLAYER:
			_add_player_ships(fleet, ship_count, flagship_scene)
	
	return fleet

# Helper methods to add specific ship types
static func _add_trader_ships(fleet: Fleet, count: int, flagship_scene: PackedScene = null) -> void:
	# Add ships to the fleet with trader pilots
	var flagship = _create_ship(flagship_scene, "trader")
	fleet.add_ship(flagship)
	
	# Add additional ships
	for i in range(count - 1):
		var ship = _create_ship(null, "trader")
		fleet.add_ship(ship)

static func _add_pirate_ships(fleet: Fleet, count: int, flagship_scene: PackedScene = null) -> void:
	# Add ships to the fleet with pirate pilots
	var flagship = _create_ship(flagship_scene, "pirate")
	fleet.add_ship(flagship)
	
	# Add additional ships
	for i in range(count - 1):
		var ship = _create_ship(null, "pirate")
		fleet.add_ship(ship)

static func _add_police_ships(fleet: Fleet, count: int, flagship_scene: PackedScene = null) -> void:
	# Add ships to the fleet with police pilots
	var flagship = _create_ship(flagship_scene, "police")
	fleet.add_ship(flagship)
	
	# Add additional ships
	for i in range(count - 1):
		var ship = _create_ship(null, "police")
		fleet.add_ship(ship)

static func _add_player_ships(fleet: Fleet, count: int, flagship_scene: PackedScene = null) -> void:
	# First add player's ship as flagship
	var player_ship = _find_player_ship()
	
	if player_ship:
		fleet.add_ship(player_ship)
	else:
		# No player ship found, create one
		var flagship = _create_ship(flagship_scene, "player")
		fleet.add_ship(flagship)
	
	# Add AI escort ships
	for i in range(count - 1):
		var ship = _create_ship(null, "escort")
		fleet.add_ship(ship)

# Helper to create a single ship
static func _create_ship(ship_scene: PackedScene = null, pilot_type: String = "") -> Ship:
	var ship: Ship
	
	# Use provided scene or default
	if ship_scene:
		ship = ship_scene.instantiate()
	else:
		# Use default (could be expanded to use different types based on faction)
		ship = preload("res://Entities/Ships/Frigates/Sparrow.tscn").instantiate()
	
	# Add appropriate pilot
	match pilot_type:
		"trader":
			var trader_pilot = Trader_Pilot.new()
			ship.add_child(trader_pilot)
		"pirate":
			var pirate_pilot = Pirate_Pilot.new()
			ship.add_child(pirate_pilot)
		"police":
			var police_pilot = Police_Pilot.new()
			ship.add_child(police_pilot)
		"escort":
			var escort_pilot = AI_Pilot.new()
			escort_pilot.aggressiveness = 0.6
			ship.add_child(escort_pilot)
		"player":
			var player = Player.new()
			ship.add_child(player)
	
	# Add basic equipment if needed
	_ensure_ship_has_equipment(ship)
	
	return ship

# Ensure ship has necessary equipment
static func _ensure_ship_has_equipment(ship: Ship) -> void:
	# Check if ship has thruster
	if not ship.is_thruster_installed():
		var thruster = Small_Thruster.new()
		ship.add_child(thruster)
	
	# Check if ship has turning
	if not ship.is_turning_installed():
		var turning = Small_Turning.new()
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
	
	# Add additional ships based on faction
	match faction:
		FleetFaction.TRADER:
			for i in range(additional_ships):
				var escort = _create_ship(null, "trader")
				fleet.add_ship(escort)
		FleetFaction.PIRATE:
			for i in range(additional_ships):
				var escort = _create_ship(null, "pirate")
				fleet.add_ship(escort)
		FleetFaction.POLICE:
			for i in range(additional_ships):
				var escort = _create_ship(null, "police")
				fleet.add_ship(escort)
		FleetFaction.PLAYER:
			for i in range(additional_ships):
				var escort = _create_ship(null, "escort")
				fleet.add_ship(escort)
	
	return fleet
