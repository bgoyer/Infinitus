extends Node2D
class_name AI_Manager

# Preload ship and pilot scenes/scripts
@export var frigate_scene: PackedScene
@export var trader_pilot_scene: PackedScene
@export var police_pilot_scene: PackedScene
@export var pirate_pilot_scene: PackedScene
var instance = GameManagerInstance
# Spawn points and limits
var spawn_radius: float = 5000.0
var max_traders: int = 5
var max_police: int = 3
var max_pirates: int = 4
var current_traders: int = 0
var current_police: int = 0
var current_pirates: int = 0

# Tracking active ships for management
var active_ships: Array[Ship] = []

# References
var map: Map
var star: CelestialBody
var planets: Array[Planet] = []

func _ready() -> void:
	# Find references to important nodes
	map = get_parent() if get_parent() is Map else null
	_find_celestial_bodies()
	
	# Set up timers for spawning
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 10.0  # Check every 10 seconds
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(spawn_timer)
	spawn_timer.start()
	
	# Initial spawn
	_spawn_initial_ships()

func _physics_process(delta: float) -> void:
	# Clean up destroyed or invalid ships
	_clean_ship_list()
	
	# Update counts
	_update_ship_counts()

func _find_celestial_bodies() -> void:
	# Find star and planets in the scene
	var celestial_bodies = get_tree().get_nodes_in_group("celestial_bodies")
	
	for body in celestial_bodies:
		if body is CelestialBody and not body is Planet:
			star = body
		elif body is Planet:
			planets.append(body)

func _spawn_initial_ships() -> void:
	# Spawn initial set of ships
	for i in range(max_traders / 2):
		_spawn_trader()
	
	for i in range(max_police / 2):
		_spawn_police()
	
	for i in range(max_pirates / 2):
		_spawn_pirate()

func _on_spawn_timer_timeout() -> void:
	# Periodically check if we need to spawn more ships
	_update_ship_counts()
	
	# Spawn ships as needed
	if current_traders < max_traders:
		_spawn_trader()
	
	if current_police < max_police:
		_spawn_police()
	
	if current_pirates < max_pirates:
		_spawn_pirate()

func _spawn_trader() -> void:
	var ship = frigate_scene.instantiate()
	var pilot = trader_pilot_scene.instantiate()
	
	# Configure the ship and pilot
	ship.add_child(pilot)
	
	ship.add_child(instance.item_data_system.create_thruster("small_thruster"))
	ship.add_child(instance.item_data_system.create_turning("small_turning"))
	
	# Set spawn position at edge of system
	var spawn_angle = randf() * 2 * PI
	var spawn_pos = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_radius
	ship.global_position = spawn_pos
	
	# Set trade route if planets available
	if pilot is TraderPilot and planets.size() > 0:
		var route_size = 2 + randi() % 3  # 2-4 planets in route
		var trade_route = []
		
		for i in range(min(route_size, planets.size())):
			# Pick a random planet
			var planet_index = randi() % planets.size()
			trade_route.append(planets[planet_index])
		
		pilot.trade_route = trade_route
	
	# Add to scene
	if map:
		map.add_child(ship)
	else:
		get_parent().add_child.call_deferred(ship)
	
	active_ships.append(ship)
	current_traders += 1

func _spawn_police() -> void:
	var ship = frigate_scene.instantiate()
	var pilot = police_pilot_scene.instantiate()
	
	# Configure the ship and pilot
	ship.add_child(pilot)
	
	# Add equipment (example)
	ship.add_child(instance.item_data_system.create_thruster("small_thruster"))
	ship.add_child(instance.item_data_system.create_turning("small_turning"))
	
	# Set patrol center to system center
	if pilot is PolicePilot:
		pilot.patrol_center = Vector2.ZERO
		pilot.patrol_radius = spawn_radius * 0.6
		pilot.patrol_seed = randi()  # Random seed for patrol pattern
	
	# Set spawn position within system
	var spawn_angle = randf() * 2 * PI
	var spawn_dist = randf_range(spawn_radius * 0.3, spawn_radius * 0.7)
	var spawn_pos = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_dist
	ship.global_position = spawn_pos
	
	# Add to scene
	if map:
		map.add_child(ship)
	else:
		get_parent().add_child.call_deferred(ship)
	
	active_ships.append(ship)
	current_police += 1

func _spawn_pirate() -> void:
	var ship = frigate_scene.instantiate()
	var pilot = pirate_pilot_scene.instantiate()
	
	# Configure the ship and pilot
	ship.add_child(pilot)
	
	# Add equipment (example)
	ship.add_child(instance.item_data_system.create_thruster("small_thruster"))
	ship.add_child(instance.item_data_system.create_turning("small_turning"))
	
	# Potentially set up pirate base
	if pilot is PiratePilot and planets.size() > 0 and randf() < 0.3:
		pilot.has_pirate_base = true
		pilot.pirate_base = planets[randi() % planets.size()]
	
	# Set spawn position at edge of system
	var spawn_angle = randf() * 2 * PI
	var spawn_pos = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_radius
	ship.global_position = spawn_pos
	
	# Add to scene
	if map:
		map.add_child(ship)
	else:
		get_parent().add_child.call_deferred(ship)
	
	active_ships.append(ship)
	current_pirates += 1

func _clean_ship_list() -> void:
	# Remove any ships that no longer exist
	for i in range(active_ships.size() - 1, -1, -1):
		if !is_instance_valid(active_ships[i]):
			active_ships.remove_at(i)

func _update_ship_counts() -> void:
	current_traders = 0
	current_police = 0
	current_pirates = 0
	
	for ship in active_ships:
		if !is_instance_valid(ship):
			continue
			
		# Check for pilot types
		for child in ship.get_children():
			if child is TraderPilot:
				current_traders += 1
			elif child is PolicePilot:
				current_police += 1
			elif child is PiratePilot:
				current_pirates += 1
