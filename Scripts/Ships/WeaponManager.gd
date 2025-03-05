extends Node
class_name WeaponManager

## Manages weapons attached to a ship
## Handles weapon groups, targeting, and firing logic

# References
var ship: Ship

# Weapon management
var weapons: Array[Weapon] = []
var weapon_hardpoints: Array[Node2D] = []
var current_weapon_index: int = 0

# Weapon groups for easier control
var weapon_groups = {
	"primary": [],   # Typically forward-facing guns
	"secondary": [], # Typically turrets
	"tertiary": []   # Typically missiles or special weapons
}

# Current target
var current_target: Node2D = null

# Signals
signal weapon_added(weapon, hardpoint)
signal weapon_removed(weapon)
signal weapon_fired(weapon, projectile)
signal weapon_group_switched(group_name)
signal target_acquired(target)
signal target_lost()

func _ready() -> void:
	# Get ship reference
	ship = get_parent() if get_parent() is Ship else null
	
	# Find hardpoints
	_find_hardpoints()
	
	# Load any weapons already in the scene
	_load_existing_weapons()

func _process(_delta: float) -> void:
	# Update weapon logic if needed
	_update_active_weapons()

## Find all hardpoints in the ship
func _find_hardpoints() -> void:
	weapon_hardpoints.clear()
	
	if not ship:
		return
	
	# Look for nodes named HardpointX
	for child in ship.get_children():
		if child is Node2D and child.name.begins_with("Hardpoint"):
			weapon_hardpoints.append(child)

## Load weapons that might already be children of hardpoints
func _load_existing_weapons() -> void:
	for hardpoint in weapon_hardpoints:
		for child in hardpoint.get_children():
			if child is Weapon:
				_register_weapon(child, hardpoint)

## Update weapon states each frame
func _update_active_weapons() -> void:
	for weapon in weapons:
		# Update auto-targeting for weapons that support it
		if weapon.auto_target and weapon.current_target == null and current_target != null:
			weapon.set_target(current_target)

## Add a weapon to the ship at specified hardpoint
func add_weapon(weapon: Weapon, hardpoint_index: int) -> bool:
	if hardpoint_index < 0 or hardpoint_index >= weapon_hardpoints.size():
		push_error("Invalid hardpoint index: " + str(hardpoint_index))
		return false
		
	var hardpoint = weapon_hardpoints[hardpoint_index]
	
	# Check if hardpoint already has a weapon
	for child in hardpoint.get_children():
		if child is Weapon:
			push_error("Hardpoint already has a weapon: " + hardpoint.name)
			return false
	
	# Add weapon to hardpoint
	hardpoint.add_child(weapon)
	
	# Register the weapon
	_register_weapon(weapon, hardpoint)
	
	return true

## Remove a weapon from the ship
func remove_weapon(weapon: Weapon) -> bool:
	if weapon in weapons:
		# Find which group the weapon is in and remove it
		for group_name in weapon_groups.keys():
			if weapon in weapon_groups[group_name]:
				weapon_groups[group_name].erase(weapon)
		
		# Remove from weapons array
		weapons.erase(weapon)
		
		# Unequip from ship
		weapon.unequip()
		
		# Remove from scene tree
		if weapon.get_parent():
			weapon.get_parent().remove_child(weapon)
		
		emit_signal("weapon_removed", weapon)
		return true
	
	return false

## Register a weapon in our tracking arrays
func _register_weapon(weapon: Weapon, hardpoint: Node2D) -> void:
	weapons.append(weapon)
	weapon.equip(ship)
	
	# Connect signals
	if not weapon.is_connected("weapon_fired", Callable(self, "_on_weapon_fired")):
		weapon.connect("weapon_fired", Callable(self, "_on_weapon_fired"))
	
	# Determine weapon group based on type
	if weapon is Gun:
		weapon_groups["primary"].append(weapon)
	elif weapon is Turret:
		weapon_groups["secondary"].append(weapon)
	elif weapon is MissileLauncher:
		weapon_groups["tertiary"].append(weapon)
	
	emit_signal("weapon_added", weapon, hardpoint)

## Fire the current weapon or weapon group
func fire_weapons(group_name: String = "primary") -> void:
	if not weapon_groups.has(group_name):
		return
		
	var fired_any = false
	
	# Fire all weapons in the group
	for weapon in weapon_groups[group_name]:
		if weapon.fire():
			fired_any = true
	
	if fired_any and ship and ship.has_method("on_weapons_fired"):
		ship.on_weapons_fired(group_name)

## Switch to next weapon in a group
func switch_weapon(group_name: String = "primary") -> void:
	if not weapon_groups.has(group_name) or weapon_groups[group_name].size() <= 1:
		return
		
	current_weapon_index = (current_weapon_index + 1) % weapon_groups[group_name].size()
	emit_signal("weapon_group_switched", group_name)

## Set target for all weapons that can auto-target
func set_target(target: Node2D) -> void:
	if target == current_target:
		return
		
	current_target = target
	
	if current_target != null:
		emit_signal("target_acquired", current_target)
		
		# Set target for auto-targeting weapons
		for weapon in weapons:
			if weapon.auto_target:
				weapon.set_target(target)
	else:
		emit_signal("target_lost")
		clear_targets()

## Clear targets for all weapons
func clear_targets() -> void:
	current_target = null
	
	for weapon in weapons:
		weapon.lose_target()
	
	emit_signal("target_lost")

## Reload all weapons
func reload_all() -> void:
	for weapon in weapons:
		weapon.reload()

## Signal handler for weapon fired
func _on_weapon_fired(weapon: Weapon, projectile) -> void:
	emit_signal("weapon_fired", weapon, projectile)

## Get all weapons of a specific type
func get_weapons_by_type(type: String) -> Array:
	var result = []
	
	match type:
		"Gun":
			for weapon in weapons:
				if weapon is Gun:
					result.append(weapon)
		"Turret":
			for weapon in weapons:
				if weapon is Turret:
					result.append(weapon)
		"MissileLauncher":
			for weapon in weapons:
				if weapon is MissileLauncher:
					result.append(weapon)
		"Primary":
			result = weapon_groups["primary"].duplicate()
		"Secondary":
			result = weapon_groups["secondary"].duplicate()
		"Tertiary":
			result = weapon_groups["tertiary"].duplicate()
	
	return result

## Find the closest potential target within range
func find_closest_target(max_range: float = 2000.0, filter_func: Callable = Callable()) -> Node2D:
	var closest_target = null
	var closest_distance = max_range
	
	if not ship:
		return null
		
	# Get all potential targets in the scene
	var target_nodes = get_tree().get_nodes_in_group("Ships")
	
	for target_node in target_nodes:
		# Skip our own ship
		if target_node == ship:
			continue
			
		# Apply custom filter if provided
		if filter_func.is_valid() and not filter_func.call(target_node):
			continue
			
		var distance = ship.global_position.distance_to(target_node.global_position)
		
		if distance < closest_distance:
			closest_target = target_node
			closest_distance = distance
	
	return closest_target
