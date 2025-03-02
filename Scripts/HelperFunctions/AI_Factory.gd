extends Node
class_name AIFactory

# Enums for AI types
enum AI_Type {TRADER, POLICE, PIRATE}

# Scene references - would be set in the inspector
var trader_pilot_scene: PackedScene = preload("res://Entities/NPCs/Pirate_Pilot.tscn")
var police_pilot_scene: PackedScene = preload("res://Entities/NPCs/Police_Pilot.tscn")
var pirate_pilot_scene: PackedScene = preload("res://Entities/NPCs/Trader_Pilot.tscn")
var small_thruster_scene: PackedScene = preload("res://Entities/Equipment/Small/SmallThruster.tscn")
var small_turning_scene: PackedScene = preload("res://Entities/Equipment/Small/SmallTurning.tscn")

# Ship scene references
@export var frigates: Array[PackedScene]

# Spawn rate settings
@export var spawn_interval: float = 60.0  # Seconds between spawn attempts
@export var max_ai_ships: int = 15  # Max number of AI ships in the system
@export var faction_ratios: Dictionary = {
	AI_Type.TRADER: 0.5,
	AI_Type.POLICE: 0.3,
	AI_Type.PIRATE: 0.2
}

# Spawn locations
@export var spawn_points: Array[Node2D]  # Points where ships can spawn
@export var planets: Array[Orbiting_Body]  # Planets for trade routes and police patrols

# Reference to the current map
var current_map: Map

# Timers
var spawn_timer: float = 0.0

# Tracking
var spawned_ships: Array[Ship] = []

func _ready() -> void:
	# Find the map if not set
	if not current_map:
		var maps = get_tree().get_nodes_in_group("map")
		if maps.size() > 0:
			current_map = maps[0]

func _process(delta: float) -> void:
	# Update spawn timer
	spawn_timer += delta
	
	# Check if it's time to attempt a spawn
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_attempt_spawn()
	
	# Clean up invalid ships from tracking
	_cleanup_spawned_ships()

func _attempt_spawn() -> void:
	# Check if we're at max ships
	if spawned_ships.size() >= max_ai_ships:
		return
	
	# Determine what type of ship to spawn based on faction ratios
	var ai_type = _select_ai_type()
	
	# Only spawn if we have a map
	if current_map:
		var new_ship = _spawn_ship(ai_type)
		if new_ship:
			current_map.add_child(new_ship)
			spawned_ships.append(new_ship)

func _select_ai_type() -> int:
	# Choose AI type based on faction ratios
	var roll = randf()
	var cumulative = 0.0
	
	for type in faction_ratios:
		cumulative += faction_ratios[type]
		if roll <= cumulative:
			return type
	
	# Default to trader if something goes wrong
	return AI_Type.TRADER

func _spawn_ship(ai_type: int) -> Ship:
	# Choose a random frigate type
	var frigate_scene = frigates[randi() % frigates.size()]
	var ship_instance = frigate_scene.instantiate()
	
	# Choose spawn location
	var spawn_point = _select_spawn_point()
	ship_instance.global_position = spawn_point
	
	# Add equipment
	_add_basic_equipment(ship_instance)
	
	# Add appropriate pilot
	var pilot = _create_pilot(ai_type)
	if pilot:
		ship_instance.add_child(pilot)
	
	return ship_instance

func _select_spawn_point() -> Vector2:
	# Choose a random spawn point
	if spawn_points.size() > 0:
		var spawn_node = spawn_points[randi() % spawn_points.size()]
		return spawn_node.global_position
	
	# Fallback to random position if no spawn points defined
	return Vector2(
		randf_range(-5000, 5000),
		randf_range(-5000, 5000)
	)

func _create_pilot(ai_type: int) -> Pilot:
	match ai_type:
		AI_Type.TRADER:
			if trader_pilot_scene:
				var pilot = trader_pilot_scene.instantiate()
				_setup_trader_pilot(pilot)
				return pilot
		
		AI_Type.POLICE:
			if police_pilot_scene:
				var pilot = police_pilot_scene.instantiate()
				_setup_police_pilot(pilot)
				return pilot
		
		AI_Type.PIRATE:
			if pirate_pilot_scene:
				var pilot = pirate_pilot_scene.instantiate()
				_setup_pirate_pilot(pilot)
				return pilot
	
	return null

func _setup_trader_pilot(pilot: TraderPilot) -> void:
	# Set up trade route with random planets
	if planets.size() > 0:
		var route_length = randi_range(2, min(4, planets.size()))
		var shuffled_planets = planets.duplicate()
		shuffled_planets.shuffle()
		
		for i in range(route_length):
			pilot.trade_route.append(shuffled_planets[i])
		
		# Set initial target planet
		pilot.target_planet = pilot.trade_route[0]
		pilot.patrol_points = [pilot.target_planet.global_position]

func _setup_police_pilot(pilot: PolicePilot) -> void:
	# Set patrol center to a random planet if available
	if planets.size() > 0:
		var center_planet = planets[randi() % planets.size()]
		pilot.patrol_center = center_planet.global_position
		pilot.patrol_radius = 2000.0 + randf() * 3000.0
		pilot.home_planet = center_planet
	
	# Generate random patrol points
	pilot.patrol_seed = randi()
	pilot._generate_patrol_points()

func _setup_pirate_pilot(pilot: PiratePilot) -> void:
	# 50% chance to have a pirate base
	pilot.has_pirate_base = randf() < 0.5
	
	if pilot.has_pirate_base and planets.size() > 0:
		# Select a random planet as pirate base
		pilot.pirate_base = planets[randi() % planets.size()]
		pilot.home_planet = pilot.pirate_base
	
	# Set up initial patrol or ambush
	if pilot.is_setting_ambush:
		pilot._set_ambush_position()
	else:
		pilot._generate_patrol_points()

func _add_basic_equipment(ship_instance: Ship) -> void:
	# Add thruster
	if small_thruster_scene:
		var thruster = small_thruster_scene.instantiate()
		ship_instance.add_child(thruster)
	
	# Add turning
	if small_turning_scene:
		var turning = small_turning_scene.instantiate()
		ship_instance.add_child(turning)

func _cleanup_spawned_ships() -> void:
	var valid_ships = []
	
	for ship in spawned_ships:
		if is_instance_valid(ship) and not ship.is_queued_for_deletion():
			valid_ships.append(ship)
	
	spawned_ships = valid_ships

# Public functions for manual spawning
func spawn_trader() -> Ship:
	return _spawn_and_add_to_map(AI_Type.TRADER)

func spawn_police() -> Ship:
	return _spawn_and_add_to_map(AI_Type.POLICE)

func spawn_pirate() -> Ship:
	return _spawn_and_add_to_map(AI_Type.PIRATE)

func _spawn_and_add_to_map(ai_type: int) -> Ship:
	var ship = _spawn_ship(ai_type)
	if ship and current_map:
		current_map.add_child(ship)
		spawned_ships.append(ship)
	return ship
