extends Node
class_name SceneBuilder

# Constants for file paths
const DATA_FOLDER = "res://data/"
const SHIP_FILE = "ships.json"
const WEAPON_FILE = "weapons.json"
const COMPONENT_FILE = "components.json"

# Cache for loaded data
var ships_data: Dictionary = {}
var weapons_data: Dictionary = {}
var components_data: Dictionary = {}

# Reference to the resource manager for loading textures
var resource_manager: ResourceManager

# Default resources as fallbacks
var default_texture: Texture2D

# Signals
signal scene_built(scene_instance, scene_type, data_id)
signal build_failed(scene_type, data_id, error)

func _ready() -> void:
	# Try to find ResourceManager
	var resource_managers = get_tree().get_nodes_in_group("ResourceManager")
	if resource_managers.size() > 0:
		resource_manager = resource_managers[0]
	
	# Load default resources
	default_texture = load("res://assets/textures/default.png")
	
	# Load all data files
	load_all_data()

# Load all JSON data files
func load_all_data() -> void:
	ships_data = load_json_file(SHIP_FILE)
	weapons_data = load_json_file(WEAPON_FILE)
	components_data = load_json_file(COMPONENT_FILE)

# Load a specific JSON file
func load_json_file(filename: String) -> Dictionary:
	var file_path = DATA_FOLDER + filename
	var data = {}
	
	if not FileAccess.file_exists(file_path):
		push_error("Data file not found: " + file_path)
		return data
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open data file: " + file_path)
		return data
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("JSON Parse Error: " + json.get_error_message() + " in " + filename + " at line " + str(json.get_error_line()))
		return data
	
	var parsed_data = json.data
	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("Unexpected data format in file: " + filename)
		return data
	
	return parsed_data

# Build a ship from JSON data
func build_ship(ship_id: String) -> Ship:
	if not ships_data.has(ship_id):
		push_error("Ship ID not found: " + ship_id)
		emit_signal("build_failed", "ship", ship_id, "Ship ID not found")
		return null
	
	var data = ships_data[ship_id]
	
	# Create the base ship instance
	var ship = Ship.new()
	ship.name = data.get("name", ship_id)
	
	# Set basic ship properties
	ship.max_velocity = data.get("max_velocity", 1000)
	ship.max_hull_health = data.get("max_hull_health", 100)
	ship.current_hull_health = ship.max_hull_health
	ship.faction = data.get("faction", "neutral")
	
	# Add sprite
	if data.has("sprite_texture"):
		var sprite = Sprite2D.new()
		sprite.name = "Sprite"
		
		# Load texture
		var texture_path = data.get("sprite_texture")
		var texture = load_texture(texture_path)
		sprite.texture = texture
		
		# Set sprite properties
		if data.has("sprite_scale"):
			sprite.scale = Vector2(data.get("sprite_scale"), data.get("sprite_scale"))
		
		ship.add_child(sprite)
	
	# Add collision shape
	if data.has("collision_shape"):
		var collision = CollisionShape2D.new()
		collision.name = "Collision"
		
		var shape_data = data.get("collision_shape")
		var shape_type = shape_data.get("type", "rectangle")
		
		var shape
		match shape_type:
			"circle":
				shape = CircleShape2D.new()
				shape.radius = shape_data.get("radius", 50)
			"rectangle", _:
				shape = RectangleShape2D.new()
				var size = shape_data.get("size", {"x": 100, "y": 100})
				shape.size = Vector2(size.x, size.y)
		
		collision.shape = shape
		ship.add_child(collision)
	
	# Add hardpoints
	if data.has("hardpoints") and data.get("hardpoints") is Array:
		for hardpoint_data in data.get("hardpoints"):
			var hardpoint = Node2D.new()
			hardpoint.name = "Hardpoint" + str(hardpoint_data.get("id", 0))
			
			var position = hardpoint_data.get("position", {"x": 0, "y": 0})
			hardpoint.position = Vector2(position.x, position.y)
			
			# Add weapon if specified
			if hardpoint_data.has("weapon_id"):
				var weapon = build_weapon(hardpoint_data.get("weapon_id"))
				if weapon:
					hardpoint.add_child(weapon)
			
			ship.add_child(hardpoint)
	
	# Add engine points for effects
	if data.has("engine_points") and data.get("engine_points") is Array:
		for engine_data in data.get("engine_points"):
			var engine_point = Node2D.new()
			engine_point.name = "EnginePoint" + str(engine_data.get("id", 0))
			
			var position = engine_data.get("position", {"x": 0, "y": 0})
			engine_point.position = Vector2(position.x, position.y)
			
			# Add particles if specified
			if engine_data.has("particles") and engine_data.get("particles"):
				var particles = GPUParticles2D.new()
				particles.name = "EngineParticles"
				
				# Set up particle properties
				var material = ParticleProcessMaterial.new()
				material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
				material.direction = Vector3(0, 1, 0)
				material.spread = 10
				material.initial_velocity_min = 50
				material.initial_velocity_max = 80
				material.scale_min = 1.0
				material.scale_max = 2.0
				particles.process_material = material
				
				engine_point.add_child(particles)
			
			ship.add_child(engine_point)
	
	# Add equipment components
	if data.has("equipment"):
		var equipment = data.get("equipment")
		
		# Add thruster
		if equipment.has("thruster"):
			var thruster = build_component("thruster", equipment.get("thruster"))
			if thruster:
				ship.add_child(thruster)
		
		# Add turning system
		if equipment.has("turning"):
			var turning = build_component("turning", equipment.get("turning"))
			if turning:
				ship.add_child(turning)
		
		# Add shield
		if equipment.has("shield"):
			var shield = build_component("shield", equipment.get("shield"))
			if shield:
				ship.add_child(shield)
		
		# Add armor
		if equipment.has("armor"):
			var armor = build_component("armor", equipment.get("armor"))
			if armor:
				ship.add_child(armor)
		
		# Add capacitor
		if equipment.has("capacitor"):
			var capacitor = build_component("capacitor", equipment.get("capacitor"))
			if capacitor:
				ship.add_child(capacitor)
		
		# Add generator
		if equipment.has("generator"):
			var generator = build_component("generator", equipment.get("generator"))
			if generator:
				ship.add_child(generator)
	
	# Add health component
	if data.has("health_component") and data.get("health_component"):
		var health = ShipHealth.new()
		health.name = "Health"
		health.max_health = data.get("max_hull_health", 100)
		health.current_health = health.max_health
		
		# Set armor value if specified
		if data.has("armor_value"):
			health.armor = data.get("armor_value")
		
		# Set shield values if specified
		if data.has("shield_max"):
			health.shield_max = data.get("shield_max")
			health.shield_current = health.shield_max
			health.shield_recharge_rate = data.get("shield_recharge_rate", 5.0)
		
		ship.add_child(health)
	
	# Add energy component
	if data.has("energy_component") and data.get("energy_component"):
		var energy = ShipEnergy.new()
		energy.name = "Energy"
		energy.max_energy = data.get("max_energy", 100)
		energy.current_energy = energy.max_energy
		energy.recharge_rate = data.get("energy_recharge_rate", 10.0)
		
		ship.add_child(energy)
	
	# Add weapon manager
	var weapon_manager = WeaponManager.new()
	weapon_manager.name = "WeaponManager"
	ship.add_child(weapon_manager)
	
	# Add tracking if needed
	if data.has("tracked") and data.get("tracked"):
		var tracker = TrackedObject.new()
		tracker.name = "Tracker"
		tracker.tracked = true
		
		if data.has("indicator_name"):
			tracker.indicator_name = data.get("indicator_name")
		
		if data.has("indicator_color"):
			var color_data = data.get("indicator_color")
			tracker.indicator_color = Color(color_data.r, color_data.g, color_data.b, color_data.a)
		
		ship.add_child(tracker)
	
	emit_signal("scene_built", ship, "ship", ship_id)
	return ship

# Build a weapon from JSON data
func build_weapon(weapon_id: String) -> Weapon:
	if not weapons_data.has(weapon_id):
		push_error("Weapon ID not found: " + weapon_id)
		emit_signal("build_failed", "weapon", weapon_id, "Weapon ID not found")
		return null
	
	var data = weapons_data[weapon_id]
	var weapon_type = data.get("type", "gun")
	var weapon
	
	# Create weapon based on type
	match weapon_type.to_lower():
		"gun":
			weapon = Gun.new()
		"turret":
			weapon = Turret.new()
		"missile_launcher":
			weapon = MissileLauncher.new()
		_:
			push_error("Unknown weapon type: " + weapon_type)
			return null
	
	weapon.name = data.get("name", weapon_id)
	
	# Set common properties
	weapon.damage = data.get("damage", 10)
	weapon.fire_rate = data.get("fire_rate", 1.0)
	weapon.range_distance = data.get("range_distance", 1000.0)
	weapon.projectile_speed = data.get("projectile_speed", 800.0)
	weapon.energy_cost = data.get("energy_cost", 5)
	
	# Set ammo properties
	if data.has("ammo_capacity"):
		weapon.ammo_capacity = data.get("ammo_capacity")
		weapon.ammo_count = weapon.ammo_capacity
	
	# Set targeting properties
	weapon.accuracy = data.get("accuracy", 1.0)
	weapon.auto_target = data.get("auto_target", false)
	
	# Add specific properties for weapon types
	if weapon is Gun:
		weapon.spread_angle = data.get("spread_angle", 0.0)
	elif weapon is Turret:
		weapon.rotation_speed = data.get("rotation_speed", 3.0)
		weapon.aim_ahead_factor = data.get("aim_ahead_factor", 1.0)
		weapon.fire_arc = data.get("fire_arc", 180.0)
		
		# Add turret parts (base and barrel)
		var turret_base = Node2D.new()
		turret_base.name = "TurretBase"
		weapon.add_child(turret_base)
		
		var turret_barrel = Node2D.new()
		turret_barrel.name = "TurretBarrel"
		turret_base.add_child(turret_barrel)
		
		# Add sprite for turret base if specified
		if data.has("base_sprite"):
			var base_sprite = Sprite2D.new()
			var texture_path = data.get("base_sprite")
			base_sprite.texture = load_texture(texture_path)
			turret_base.add_child(base_sprite)
		
		# Add sprite for turret barrel if specified
		if data.has("barrel_sprite"):
			var barrel_sprite = Sprite2D.new()
			var texture_path = data.get("barrel_sprite")
			barrel_sprite.texture = load_texture(texture_path)
			turret_barrel.add_child(barrel_sprite)
	elif weapon is MissileLauncher:
		weapon.missile_tracking_time = data.get("missile_tracking_time", 5.0)
		weapon.missile_turning_speed = data.get("missile_turning_speed", 2.0)
		weapon.missile_acceleration = data.get("missile_acceleration", 100.0)
		weapon.missile_max_speed = data.get("missile_max_speed", 500.0)
		weapon.missile_blast_radius = data.get("missile_blast_radius", 50.0)
		weapon.salvo_size = data.get("salvo_size", 1)
		weapon.salvo_delay = data.get("salvo_delay", 0.1)
	
	# Add muzzle position
	var muzzle = Marker2D.new()
	muzzle.name = "MuzzlePosition"
	
	if data.has("muzzle_position"):
		var pos = data.get("muzzle_position")
		muzzle.position = Vector2(pos.x, pos.y)
	else:
		muzzle.position = Vector2(0, -30)  # Default position
	
	if weapon is Turret:
		weapon.get_node("TurretBase/TurretBarrel").add_child(muzzle)
	else:
		weapon.add_child(muzzle)
	
	# Add visual model
	var visual = Node2D.new()
	visual.name = "VisualModel"
	
	if data.has("sprite"):
		var sprite = Sprite2D.new()
		var texture_path = data.get("sprite")
		sprite.texture = load_texture(texture_path)
		visual.add_child(sprite)
	
	weapon.add_child(visual)
	
	# Set projectile scene if specified
	if data.has("projectile_scene"):
		var scene_path = data.get("projectile_scene")
		if ResourceLoader.exists(scene_path):
			weapon.projectile_scene = load(scene_path)
	
	emit_signal("scene_built", weapon, "weapon", weapon_id)
	return weapon

# Build a component (thruster, shield, etc.) from JSON data
func build_component(component_type: String, component_id: String) -> Node:
	if not components_data.has(component_id):
		push_error("Component ID not found: " + component_id)
		emit_signal("build_failed", "component", component_id, "Component ID not found")
		return null
	
	var data = components_data[component_id]
	var expected_type = data.get("type", "")
	
	if expected_type != component_type:
		push_error("Component type mismatch: Expected " + component_type + ", got " + expected_type)
		emit_signal("build_failed", "component", component_id, "Component type mismatch")
		return null
	
	var component
	
	# Create component based on type
	match component_type.to_lower():
		"thruster":
			component = Thruster.new()
			component.thrust = data.get("thrust", 10)
			component.drain = data.get("drain", 1)
			component.capacitor_need = data.get("capacitor_need", 1)
		"turning":
			component = Turning.new()
			component.thrust = data.get("thrust", 4)
			component.drain = data.get("drain", 1)
			component.capacitor_need = data.get("capacitor_need", 1)
		"shield":
			component = ShieldBase.new()
			component.max_shield = data.get("max_shield", 50)
			component.current_shield = component.max_shield
			component.recharge_rate = data.get("recharge_rate", 5.0)
			component.recharge_delay = data.get("recharge_delay", 3.0)
			component.energy_drain = data.get("energy_drain", 1.0)
			
			# Set shield color if specified
			if data.has("shield_color"):
				var color_data = data.get("shield_color")
				component.shield_color = Color(color_data.r, color_data.g, color_data.b, color_data.a)
			
			# Set up shield visual
			_setup_shield_visual(component, data)
		"armor":
			component = ArmorBase.new()
			component.armor_rating = data.get("armor_rating", 10)
			component.damage_threshold = data.get("damage_threshold", 5)
			component.max_absorption = data.get("max_absorption", 0.8)
			
			# Set resistances if specified
			if data.has("resistances"):
				var resistances = data.get("resistances")
				component.kinetic_resistance = resistances.get("kinetic", 1.0)
				component.energy_resistance = resistances.get("energy", 1.0)
				component.explosive_resistance = resistances.get("explosive", 1.0)
				component.thermal_resistance = resistances.get("thermal", 1.0)
		"capacitor":
			component = CapacitorBase.new()
			component.max_capacity = data.get("max_capacity", 100)
			component.current_energy = component.max_capacity
			component.discharge_efficiency = data.get("discharge_efficiency", 1.0)
			component.recharge_efficiency = data.get("recharge_efficiency", 1.0)
			component.discharge_rate_limit = data.get("discharge_rate_limit", 50.0)
		"generator":
			component = GeneratorBase.new()
			component.generation_rate = data.get("generation_rate", 10.0)
			component.efficiency = data.get("efficiency", 1.0)
			component.power_up_time = data.get("power_up_time", 0.5)
			component.heat_generation = data.get("heat_generation", 1.0)
		_:
			push_error("Unknown component type: " + component_type)
			return null
	
	component.name = data.get("name", component_id)
	
	# Set common equipment properties
	component.description = data.get("description", "")
	component.mass = data.get("mass", 1)
	component.equipment_name = data.get("equipment_name", component.name)
	component.value = data.get("value", 100)
	component.volume = data.get("volume", 1)
	
	emit_signal("scene_built", component, "component", component_id)
	return component

# Setup shield visual component
func _setup_shield_visual(shield: ShieldBase, data: Dictionary) -> void:
	var shield_visual = Node2D.new()
	shield_visual.name = "ShieldVisual"
	
	# Add shield sprite
	var sprite = Sprite2D.new()
	
	# Use shield texture if specified, otherwise use default
	if data.has("shield_texture"):
		var texture_path = data.get("shield_texture")
		sprite.texture = load_texture(texture_path)
	else:
		sprite.texture = default_texture
	
	# Set shield visual properties
	var scale = data.get("shield_scale", 1.2)
	sprite.scale = Vector2(scale, scale)
	
	shield_visual.add_child(sprite)
	shield_visual.modulate = shield.shield_color
	
	shield.add_child(shield_visual)

# Helper function to load a texture with resource manager if available
func load_texture(path: String) -> Texture2D:
	if resource_manager and resource_manager.has_method("load_resource"):
		var texture = resource_manager.load_resource(path)
		if texture:
			return texture
	
	# Fallback to direct loading
	if ResourceLoader.exists(path):
		return load(path)
	
	# Return default texture if loading fails
	return default_texture

# Reload all data files
func reload_data() -> void:
	load_all_data()

# Get ship data without creating an instance
func get_ship_data(ship_id: String) -> Dictionary:
	return ships_data.get(ship_id, {})

# Get weapon data without creating an instance
func get_weapon_data(weapon_id: String) -> Dictionary:
	return weapons_data.get(weapon_id, {})

# Get component data without creating an instance
func get_component_data(component_id: String) -> Dictionary:
	return components_data.get(component_id, {})

# Get all ship IDs
func get_all_ship_ids() -> Array:
	return ships_data.keys()

# Get all weapon IDs
func get_all_weapon_ids() -> Array:
	return weapons_data.keys()

# Get all component IDs
func get_all_component_ids() -> Array:
	return components_data.keys()

# Get filtered ship IDs by faction
func get_ships_by_faction(faction: String) -> Array:
	var result = []
	for ship_id in ships_data:
		var ship_data = ships_data[ship_id]
		if ship_data.has("faction") and ship_data.get("faction") == faction:
			result.append(ship_id)
	return result
