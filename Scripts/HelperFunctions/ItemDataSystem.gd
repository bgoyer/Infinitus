extends Node
class_name ItemDataSystem

# Singleton instance
static var instance: ItemDataSystem

# Constants for file paths
const DATA_FOLDER = "res://data/"
const CAPACITOR_FILE = "capacitor.json"
const GENERATOR_FILE = "generator.json"
const SHIELD_FILE = "shield.json"
const ARMOR_FILE = "armor.json"
const THRUSTER_FILE = "thruster.json"
const TURNING_FILE = "turning.json"
const WEAPON_FILE = "weapon.json"
const SHIP_FILE = "ship.json"  # New file for ship definitions

# Item databases
var capacitors: Dictionary = {}
var generators: Dictionary = {}
var shields: Dictionary = {}
var armors: Dictionary = {}
var thrusters: Dictionary = {}
var turnings: Dictionary = {}
var weapons: Dictionary = {}
var ships: Dictionary = {}  # New dictionary for ships

# Class scripts
var capacitor_script = preload("res://Scripts/Equipment/CapacitorBase.gd")
var generator_script = preload("res://Scripts/Equipment/GeneratorBase.gd")
var shield_script = preload("res://Scripts/Equipment/ShieldBase.gd")
var armor_script = preload("res://Scripts/Equipment/ArmorBase.gd")
var thruster_script = preload("res://Scripts/Equipment/ThrusterBase.gd")
var turning_script = preload("res://Scripts/Equipment/TurningBase.gd")

# Weapon subtype scripts
var gun_script = preload("res://Scripts/Equipment/GunBase.gd")
var turret_script = preload("res://Scripts/Equipment/TurretBase.gd")
var missile_launcher_script = preload("res://Scripts/Equipment/MissileLauncherBase.gd")

# Ship script
var ship_script = preload("res://Scripts/Ships/Ship_Base.gd")

# Signals
signal database_loaded
signal item_created(item_type, item_id, item_instance)

func _init() -> void:
	if instance == null:
		instance = self
	else:
		push_error("Multiple ItemDataSystem instances created!")

func _ready() -> void:
	# Load all item databases
	load_all_databases()

# Load all item databases
func load_all_databases() -> void:
	capacitors = load_database(CAPACITOR_FILE)
	generators = load_database(GENERATOR_FILE)
	shields = load_database(SHIELD_FILE)
	armors = load_database(ARMOR_FILE)
	thrusters = load_database(THRUSTER_FILE)
	turnings = load_database(TURNING_FILE)
	weapons = load_database(WEAPON_FILE)
	ships = load_database(SHIP_FILE)  # Load ship database
	
	emit_signal("database_loaded")

# Load a specific database file
func load_database(filename: String) -> Dictionary:
	var file_path = DATA_FOLDER + filename
	var database = {}
	
	if not FileAccess.file_exists(file_path):
		printerr("Database file not found: " + file_path)
		return database
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("Failed to open database file: " + file_path)
		return database
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		printerr("JSON Parse Error: ", json.get_error_message(), " in ", filename, " at line ", json.get_error_line())
		return database
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		printerr("Unexpected data format in file: " + filename)
		return database
	
	return data

# Create a ship from database
func create_ship(ship_id: String) -> Ship:
	if not ships.has(ship_id):
		printerr("Ship ID not found: " + ship_id)
		return null
	
	var data = ships[ship_id]
	var ship_instance: Ship
	
	# Check if a scene path is provided
	if data.has("scene_path") and ResourceLoader.exists(data.get("scene_path")):
		var ship_scene = load(data.get("scene_path"))
		ship_instance = ship_scene.instantiate()
	else:
		# Create a new ship instance
		ship_instance = Ship.new()
	
	# Configure ship properties
	ship_instance.name = data.get("name", ship_id)
	ship_instance.max_velocity = data.get("max_velocity", 1000)
	ship_instance.max_hull_health = data.get("max_hull_health", 100)
	ship_instance.current_hull_health = ship_instance.max_hull_health
	ship_instance.faction = data.get("faction", "neutral")
	
	# Add equipment if specified
	if data.has("equipment"):
		_add_equipment_to_ship(ship_instance, data["equipment"])
	
	emit_signal("item_created", "ship", ship_id, ship_instance)
	return ship_instance

# Helper method to add equipment to a ship
func _add_equipment_to_ship(ship: Ship, equipment_data: Dictionary) -> void:
	# Add thruster
	if equipment_data.has("thruster"):
		var thruster = create_thruster(equipment_data["thruster"])
		if thruster:
			ship.add_child(thruster)
	
	# Add turning
	if equipment_data.has("turning"):
		var turning = create_turning(equipment_data["turning"])
		if turning:
			ship.add_child(turning)
	
	# Add capacitor
	if equipment_data.has("capacitor"):
		var capacitor = create_capacitor(equipment_data["capacitor"])
		if capacitor:
			ship.add_child(capacitor)
	
	# Add generator
	if equipment_data.has("generator"):
		var generator = create_generator(equipment_data["generator"])
		if generator:
			ship.add_child(generator)
	
	# Add shield
	if equipment_data.has("shield"):
		var shield = create_shield(equipment_data["shield"])
		if shield:
			ship.add_child(shield)
	
	# Add armor
	if equipment_data.has("armor"):
		var armor = create_armor(equipment_data["armor"])
		if armor:
			ship.add_child(armor)
	
	# Add weapons
	if equipment_data.has("weapons") and equipment_data["weapons"] is Array:
		# Make sure weapon manager exists
		var weapon_manager = ship.get_node_or_null("WeaponManager")
		if not weapon_manager:
			weapon_manager = WeaponManager.new()
			weapon_manager.name = "WeaponManager"
			ship.add_child(weapon_manager)
		
		for weapon_data in equipment_data["weapons"]:
			if weapon_data is Dictionary and weapon_data.has("id") and weapon_data.has("hardpoint"):
				var weapon = create_weapon(weapon_data["id"])
				if weapon:
					# Get or create hardpoint
					var hardpoint_name = "Hardpoint" + str(weapon_data["hardpoint"])
					var hardpoint = ship.get_node_or_null(hardpoint_name)
					
					if not hardpoint:
						hardpoint = Node2D.new()
						hardpoint.name = hardpoint_name
						ship.add_child(hardpoint)
					
					hardpoint.add_child(weapon)

# Create a capacitor from database
func create_capacitor(capacitor_id: String) -> CapacitorBase:
	if not capacitors.has(capacitor_id):
		printerr("Capacitor ID not found: " + capacitor_id)
		return null
	
	var data = capacitors[capacitor_id]
	var capacitor = capacitor_script.new()
	
	# Set basic properties
	capacitor.name = data.get("name", capacitor_id)
	
	# Set capacitor-specific properties
	capacitor.max_capacity = data.get("max_capacity", 100)
	capacitor.current_energy = data.get("current_energy", capacitor.max_capacity)
	capacitor.discharge_efficiency = data.get("discharge_efficiency", 1.0)
	capacitor.recharge_efficiency = data.get("recharge_efficiency", 1.0)
	capacitor.discharge_rate_limit = data.get("discharge_rate_limit", 50.0)
	
	# Common equipment properties
	if data.has("description"):
		capacitor.description = data.get("description")
	if data.has("mass"):
		capacitor.mass = data.get("mass")
	if data.has("value"):
		capacitor.value = data.get("value")
	if data.has("volume"):
		capacitor.volume = data.get("volume")
	
	emit_signal("item_created", "capacitor", capacitor_id, capacitor)
	return capacitor

# Create a generator from database
func create_generator(generator_id: String) -> GeneratorBase:
	if not generators.has(generator_id):
		printerr("Generator ID not found: " + generator_id)
		return null
	
	var data = generators[generator_id]
	var generator = generator_script.new()
	
	# Set basic properties
	generator.name = data.get("name", generator_id)
	
	# Set generator-specific properties
	generator.generation_rate = data.get("generation_rate", 10.0)
	generator.efficiency = data.get("efficiency", 1.0)
	generator.is_active = data.get("is_active", true)
	generator.power_up_time = data.get("power_up_time", 0.5)
	generator.heat_generation = data.get("heat_generation", 1.0)
	generator.overload_threshold = data.get("overload_threshold", 1.5)
	
	# Common equipment properties
	if data.has("description"):
		generator.description = data.get("description")
	if data.has("mass"):
		generator.mass = data.get("mass")
	if data.has("value"):
		generator.value = data.get("value")
	if data.has("volume"):
		generator.volume = data.get("volume")
	
	emit_signal("item_created", "generator", generator_id, generator)
	return generator

# Create a shield from database
func create_shield(shield_id: String) -> ShieldBase:
	if not shields.has(shield_id):
		printerr("Shield ID not found: " + shield_id)
		return null
	
	var data = shields[shield_id]
	var shield = shield_script.new()
	
	# Set basic properties
	shield.name = data.get("name", shield_id)
	
	# Set shield-specific properties
	shield.max_shield = data.get("max_shield", 50)
	shield.current_shield = data.get("current_shield", shield.max_shield)
	shield.recharge_rate = data.get("recharge_rate", 5.0)
	shield.recharge_delay = data.get("recharge_delay", 3.0)
	shield.energy_drain = data.get("energy_drain", 1.0)
	shield.hit_energy_cost = data.get("hit_energy_cost", 2.0)
	
	# Advanced shield properties
	shield.projectile_reflection_chance = data.get("projectile_reflection_chance", 0.0)
	shield.damage_conversion = data.get("damage_conversion", 0.0)
	
	# Visual properties
	if data.has("shield_color"):
		var color_data = data["shield_color"]
		if color_data is Dictionary and color_data.has("r") and color_data.has("g") and color_data.has("b"):
			shield.shield_color = Color(color_data.r, color_data.g, color_data.b, color_data.get("a", 0.7))
	
	# Common equipment properties
	if data.has("description"):
		shield.description = data.get("description")
	if data.has("mass"):
		shield.mass = data.get("mass")
	if data.has("value"):
		shield.value = data.get("value")
	if data.has("volume"):
		shield.volume = data.get("volume")
	
	emit_signal("item_created", "shield", shield_id, shield)
	return shield

# Create an armor from database
func create_armor(armor_id: String) -> ArmorBase:
	if not armors.has(armor_id):
		printerr("Armor ID not found: " + armor_id)
		return null
	
	var data = armors[armor_id]
	var armor = armor_script.new()
	
	# Set basic properties
	armor.name = data.get("name", armor_id)
	
	# Set armor-specific properties
	armor.armor_rating = data.get("armor_rating", 10)
	armor.current_integrity = data.get("current_integrity", 100.0)
	armor.damage_threshold = data.get("damage_threshold", 5)
	armor.max_absorption = data.get("max_absorption", 0.8)
	
	# Resistance properties
	armor.kinetic_resistance = data.get("kinetic_resistance", 1.0)
	armor.energy_resistance = data.get("energy_resistance", 1.0)
	armor.explosive_resistance = data.get("explosive_resistance", 1.0)
	armor.thermal_resistance = data.get("thermal_resistance", 1.0)
	
	# Common equipment properties
	if data.has("description"):
		armor.description = data.get("description")
	if data.has("mass"):
		armor.mass = data.get("mass")
	if data.has("value"):
		armor.value = data.get("value")
	if data.has("volume"):
		armor.volume = data.get("volume")
	
	emit_signal("item_created", "armor", armor_id, armor)
	return armor

# Create a thruster from database
func create_thruster(thruster_id: String) -> Thruster:
	if not thrusters.has(thruster_id):
		printerr("Thruster ID not found: " + thruster_id)
		return null
	
	var data = thrusters[thruster_id]
	var thruster = thruster_script.new()
	
	# Set basic properties
	thruster.name = data.get("name", thruster_id)
	
	# Set thruster-specific properties
	thruster.thrust = data.get("thrust", 25)
	thruster.drain = data.get("drain", 1)
	thruster.capacitor_need = data.get("capacitor_need", 1)
	
	# Common equipment properties
	thruster.description = data.get("description", "Standard Thruster")
	thruster.mass = data.get("mass", 100)
	thruster.equipment_name = data.get("equipment_name", "Thruster")
	thruster.value = data.get("value", 100)
	thruster.volume = data.get("volume", 10)
	
	emit_signal("item_created", "thruster", thruster_id, thruster)
	return thruster

# Create a turning system from database
func create_turning(turning_id: String) -> Turning:
	if not turnings.has(turning_id):
		printerr("Turning ID not found: " + turning_id)
		return null
	
	var data = turnings[turning_id]
	var turning = turning_script.new()
	
	# Set basic properties
	turning.name = data.get("name", turning_id)
	
	# Set turning-specific properties
	turning.thrust = data.get("thrust", 4)
	turning.drain = data.get("drain", 1)
	turning.capacitor_need = data.get("capacitor_need", 1)
	
	# Common equipment properties
	turning.description = data.get("description", "Standard Turning System")
	turning.mass = data.get("mass", 1)
	turning.equipment_name = data.get("equipment_name", "Turning System")
	turning.value = data.get("value", 100)
	turning.volume = data.get("volume", 10)
	
	emit_signal("item_created", "turning", turning_id, turning)
	return turning

# Create a weapon from database
func create_weapon(weapon_id: String) -> Weapon:
	if not weapons.has(weapon_id):
		printerr("Weapon ID not found: " + weapon_id)
		return null
	
	var data = weapons[weapon_id]
	var weapon_type = data.get("type", "gun")
	var weapon: Weapon
	
	# Create appropriate weapon subtype
	match weapon_type.to_lower():
		"gun":
			weapon = gun_script.new()
		"turret":
			weapon = turret_script.new()
		"missile", "missile_launcher":
			weapon = missile_launcher_script.new()
		_:
			printerr("Unknown weapon type: " + weapon_type)
			return null
	
	# Set basic properties
	weapon.name = data.get("name", weapon_id)
	
	# Set common weapon properties
	weapon.damage = data.get("damage", 10)
	weapon.fire_rate = data.get("fire_rate", 1.0)
	weapon.range_distance = data.get("range_distance", 1000.0)
	weapon.projectile_speed = data.get("projectile_speed", 800.0)
	weapon.energy_cost = data.get("energy_cost", 5)
	weapon.ammo_capacity = data.get("ammo_capacity", -1)
	weapon.ammo_count = data.get("ammo_count", weapon.ammo_capacity)
	weapon.weapon_name = data.get("weapon_name", "Generic Weapon")
	weapon.accuracy = data.get("accuracy", 1.0)
	weapon.auto_target = data.get("auto_target", false)
	
	# Set weapon subtype-specific properties
	if weapon is Gun:
		weapon.spread_angle = data.get("spread_angle", 0.0)
	elif weapon is Turret:
		weapon.rotation_speed = data.get("rotation_speed", 3.0)
		weapon.aim_ahead_factor = data.get("aim_ahead_factor", 1.0)
		weapon.fire_arc = data.get("fire_arc", 180.0)
		weapon.base_inaccuracy = data.get("base_inaccuracy", 0.1)
		weapon.inaccuracy_from_movement = data.get("inaccuracy_from_movement", 0.2)
	elif weapon is MissileLauncher:
		weapon.missile_tracking_time = data.get("missile_tracking_time", 5.0)
		weapon.missile_turning_speed = data.get("missile_turning_speed", 2.0)
		weapon.missile_acceleration = data.get("missile_acceleration", 100.0)
		weapon.missile_max_speed = data.get("missile_max_speed", 500.0)
		weapon.missile_blast_radius = data.get("missile_blast_radius", 50.0)
		weapon.salvo_size = data.get("salvo_size", 1)
		weapon.salvo_delay = data.get("salvo_delay", 0.1)
	
	# Set projectile scene if specified
	if data.has("projectile_scene"):
		var scene_path = data.get("projectile_scene")
		if ResourceLoader.exists(scene_path):
			weapon.projectile_scene = load(scene_path)
	
	# Common equipment properties
	if data.has("description"):
		weapon.description = data.get("description")
	if data.has("mass"):
		weapon.mass = data.get("mass")
	if data.has("value"):
		weapon.value = data.get("value")
	if data.has("volume"):
		weapon.volume = data.get("volume")
	
	emit_signal("item_created", "weapon", weapon_id, weapon)
	return weapon

# Generic create function that determines the right type
func create_item(item_type: String, item_id: String) -> Node:
	match item_type.to_lower():
		"capacitor":
			return create_capacitor(item_id)
		"generator":
			return create_generator(item_id)
		"shield":
			return create_shield(item_id)
		"armor":
			return create_armor(item_id)
		"thruster":
			return create_thruster(item_id)
		"turning":
			return create_turning(item_id)
		"weapon":
			return create_weapon(item_id)
		"ship":
			return create_ship(item_id)
		_:
			printerr("Unknown item type: " + item_type)
			return null

# Helper methods for database management
func reload_database(database_type: String) -> bool:
	match database_type.to_lower():
		"capacitor", "capacitors":
			capacitors = load_database(CAPACITOR_FILE)
		"generator", "generators":
			generators = load_database(GENERATOR_FILE)
		"shield", "shields":
			shields = load_database(SHIELD_FILE)
		"armor", "armors":
			armors = load_database(ARMOR_FILE)
		"thruster", "thrusters":
			thrusters = load_database(THRUSTER_FILE)
		"turning", "turnings":
			turnings = load_database(TURNING_FILE)
		"weapon", "weapons":
			weapons = load_database(WEAPON_FILE)
		"ship", "ships":
			ships = load_database(SHIP_FILE)
		"all":
			load_all_databases()
		_:
			printerr("Unknown database type: " + database_type)
			return false
	
	return true

# Get all item IDs for a specific type
func get_item_ids(item_type: String) -> Array:
	match item_type.to_lower():
		"capacitor", "capacitors":
			return capacitors.keys()
		"generator", "generators":
			return generators.keys()
		"shield", "shields":
			return shields.keys()
		"armor", "armors":
			return armors.keys()
		"thruster", "thrusters":
			return thrusters.keys()
		"turning", "turnings":
			return turnings.keys()
		"weapon", "weapons":
			return weapons.keys()
		"ship", "ships":
			return ships.keys()
		_:
			printerr("Unknown item type: " + item_type)
			return []

# Get filtered item IDs for a specific type based on properties
func get_filtered_items(item_type: String, filter_property: String, filter_value) -> Array:
	var filtered_ids = []
	var all_items = {}
	
	# Get the appropriate database
	match item_type.to_lower():
		"capacitor", "capacitors":
			all_items = capacitors
		"generator", "generators":
			all_items = generators
		"shield", "shields":
			all_items = shields
		"armor", "armors":
			all_items = armors
		"thruster", "thrusters":
			all_items = thrusters
		"turning", "turnings":
			all_items = turnings
		"weapon", "weapons":
			all_items = weapons
		"ship", "ships":
			all_items = ships
		_:
			printerr("Unknown item type: " + item_type)
			return []
	
	# Filter items based on property
	for id in all_items.keys():
		var item_data = all_items[id]
		if item_data.has(filter_property) and item_data[filter_property] == filter_value:
			filtered_ids.append(id)
	
	return filtered_ids

# Get item data without creating an instance
func get_item_data(item_type: String, item_id: String) -> Dictionary:
	match item_type.to_lower():
		"capacitor", "capacitors":
			return capacitors.get(item_id, {})
		"generator", "generators":
			return generators.get(item_id, {})
		"shield", "shields":
			return shields.get(item_id, {})
		"armor", "armors":
			return armors.get(item_id, {})
		"thruster", "thrusters":
			return thrusters.get(item_id, {})
		"turning", "turnings":
			return turnings.get(item_id, {})
		"weapon", "weapons":
			return weapons.get(item_id, {})
		"ship", "ships":
			return ships.get(item_id, {})
		_:
			printerr("Unknown item type: " + item_type)
			return {}
