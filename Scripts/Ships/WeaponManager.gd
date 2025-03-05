extends Node
class_name WeaponManager

# References
var ship: Ship
var weapons: Array[Weapon] = []
var weapon_hardpoints: Array[Node2D] = []
var current_weapon_index: int = 0

# Weapon groups for easier control
var weapon_groups = {
	"primary": [],
	"secondary": [],
	"tertiary": []
}

# Signals
signal weapon_added(weapon, hardpoint)
signal weapon_removed(weapon)
signal weapon_fired(weapon, projectile)
signal weapon_group_switched(group_name)

func _ready() -> void:
	ship = get_parent() if get_parent() is Ship else null
	
	# Find hardpoints
	_find_hardpoints()
	
	# Load any weapons already in the scene
	_load_existing_weapons()

func _process(delta: float) -> void:
	# Update any logic needed for all weapons
	pass

# Find all hardpoints in the ship
func _find_hardpoints() -> void:
	weapon_hardpoints.clear()
	
	# Look for nodes named HardpointX
	for child in get_parent().get_children():
		if child is Node2D and child.name.begins_with("Hardpoint"):
			weapon_hardpoints.append(child)

# Load weapons that might already be children of hardpoints
func _load_existing_weapons() -> void:
	for hardpoint in weapon_hardpoints:
		for child in hardpoint.get_children():
			if child is Weapon:
				_register_weapon(child, hardpoint)

# Add a weapon to the ship at specified hardpoint
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

# Remove a weapon from the ship
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

# Register a weapon in our tracking arrays
func _register_weapon(weapon: Weapon, hardpoint: Node2D) -> void:
	weapons.append(weapon)
	weapon.equip(ship)
	
	# Connect signals
	weapon.connect("weapon_fired", Callable(self, "_on_weapon_fired"))
	
	# Determine weapon group based on type
	if weapon is Gun:
		weapon_groups["primary"].append(weapon)
	elif weapon is Turret:
		weapon_groups["secondary"].append(weapon)
	elif weapon is MissileLauncher:
		weapon_groups["tertiary"].append(weapon)
	
	emit_signal("weapon_added", weapon, hardpoint)

# Fire the current weapon or weapon group
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

# Switch to next weapon in a group
func switch_weapon(group_name: String = "primary") -> void:
	if not weapon_groups.has(group_name) or weapon_groups[group_name].size() <= 1:
		return
		
	current_weapon_index = (current_weapon_index + 1) % weapon_groups[group_name].size()
	emit_signal("weapon_group_switched", group_name)

# Set target for all weapons that can auto-target
func set_target(target: Node2D) -> void:
	for weapon in weapons:
		if weapon.auto_target:
			weapon.set_target(target)

# Clear targets for all weapons
func clear_targets() -> void:
	for weapon in weapons:
		weapon.lose_target()

# Reload all weapons
func reload_all() -> void:
	for weapon in weapons:
		weapon.reload()

# Signal handler for weapon fired
func _on_weapon_fired(weapon: Weapon, projectile) -> void:
	emit_signal("weapon_fired", weapon, projectile)
