extends Node
class_name PlayerFleetCommander

# Reference to the player's fleet
var fleet: Fleet
# Input action mappings
var input_mappings = {
	"fleet_attack": "fleet_attack",
	"fleet_defend": "fleet_defend", 
	"fleet_move_to": "fleet_move_to",
	"fleet_scatter": "fleet_scatter",
	"fleet_regroup": "fleet_regroup",
	"fleet_formation_next": "fleet_formation_next",
	"fleet_formation_prev": "fleet_formation_prev"
}
# Formation cycling
var available_formations = [
	FleetFormationManager.FormationType.V_FORMATION,
	FleetFormationManager.FormationType.LINE,
	FleetFormationManager.FormationType.CIRCLE,
	FleetFormationManager.FormationType.WEDGE,
	FleetFormationManager.FormationType.ECHELON
]
var current_formation_index: int = 0

# Fleet HUD reference
var fleet_hud: FleetHUD = null

# Control flags
var is_command_mode_active: bool = false
var current_command: String = ""
var command_target_position: Vector2 = Vector2.ZERO

signal command_issued(command, target)

func _ready() -> void:
	# Attempt to find fleet HUD
	fleet_hud = _find_fleet_hud()
	
	# Set up command mode deactivation timer
	var command_timer = Timer.new()
	command_timer.wait_time = 10.0
	command_timer.one_shot = true
	command_timer.timeout.connect(Callable(self, "_on_command_mode_timeout"))
	add_child(command_timer)

func _process(delta: float) -> void:
	# Process player input for fleet commands
	if fleet and is_instance_valid(fleet):
		_process_fleet_commands()

func _process_fleet_commands() -> void:
	# Check for command mode activation/deactivation
	if Input.is_action_just_pressed("fleet_command_mode"):
		is_command_mode_active = !is_command_mode_active
		if is_command_mode_active:
			_activate_command_mode()
		else:
			_deactivate_command_mode()
	
	# Process commands only in command mode
	if is_command_mode_active:
		# Formation cycling
		if Input.is_action_just_pressed(input_mappings.fleet_formation_next):
			_cycle_formation(1)
		elif Input.is_action_just_pressed(input_mappings.fleet_formation_prev):
			_cycle_formation(-1)
		
		# Direct commands
		if Input.is_action_just_pressed(input_mappings.fleet_attack):
			current_command = "attack"
			_prepare_target_selection()
		elif Input.is_action_just_pressed(input_mappings.fleet_defend):
			current_command = "defend"
			_prepare_target_selection()
		elif Input.is_action_just_pressed(input_mappings.fleet_move_to):
			current_command = "move_to"
			_prepare_target_selection()
		elif Input.is_action_just_pressed(input_mappings.fleet_scatter):
			_execute_command("scatter")
		elif Input.is_action_just_pressed(input_mappings.fleet_regroup):
			_execute_command("form_up")
		
		# Target selection (if applicable)
		if current_command != "":
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("mouse_left"):
				_complete_target_selection()
			elif Input.is_action_just_pressed("ui_cancel"):
				_cancel_command()

func set_fleet(new_fleet: Fleet) -> void:
	fleet = new_fleet
	if fleet and fleet_hud:
		fleet_hud.set_fleet(fleet)

func _activate_command_mode() -> void:
	# Activate command mode UI and functionality
	if fleet_hud:
		fleet_hud.show_command_mode()
	
	# Start timer for automatic deactivation if no command is issued
	$Timer.start()

func _deactivate_command_mode() -> void:
	# Deactivate command mode UI and functionality
	if fleet_hud:
		fleet_hud.hide_command_mode()
	
	# Clear any pending commands
	current_command = ""
	$Timer.stop()

func _prepare_target_selection() -> void:
	# Enable target selection UI based on command type
	if fleet_hud:
		fleet_hud.show_target_selection(current_command)

func _complete_target_selection() -> void:
	# Get target based on input (mouse position, selected enemy, etc.)
	var target = null
	
	match current_command:
		"attack":
			# For attack, target should be an enemy ship
			target = _get_targeted_enemy()
		"defend":
			# For defend, target could be a position or ally
			target = _get_targeted_ally() if _is_ally_targeted() else get_viewport().get_mouse_position()
		"move_to":
			# For move to, target is a position
			target = get_viewport().get_mouse_position()
	
	# Execute the command with the selected target
	_execute_command(current_command, target)
	
	# Reset command mode
	current_command = ""
	if fleet_hud:
		fleet_hud.hide_target_selection()

func _cancel_command() -> void:
	# Cancel the current command
	current_command = ""
	if fleet_hud:
		fleet_hud.hide_target_selection()

func _execute_command(command: String, target = null) -> void:
	# Execute the command on the fleet
	if fleet and is_instance_valid(fleet):
		fleet.execute_command(command, target)
		emit_signal("command_issued", command, target)
	
	# Reset command mode
	current_command = ""
	if fleet_hud:
		fleet_hud.hide_target_selection()

func _cycle_formation(direction: int) -> void:
	# Cycle through available formations
	current_formation_index = (current_formation_index + direction) % available_formations.size()
	if current_formation_index < 0:
		current_formation_index = available_formations.size() - 1
	
	var new_formation = available_formations[current_formation_index]
	
	# Apply the new formation
	if fleet and is_instance_valid(fleet):
		fleet.formation_manager.set_formation(new_formation)
		
		# Update UI
		if fleet_hud:
			fleet_hud.update_formation_display(new_formation)

func _get_targeted_enemy() -> Ship:
	# Find enemy ship under cursor or nearest to cursor
	var mouse_pos = get_viewport().get_mouse_position()
	var closest_enemy = null
	var min_distance = 100.0  # Minimal selection distance
	
	# Get all potential target ships in scene
	var ships = get_tree().get_nodes_in_group("Ships")
	
	for ship in ships:
		if ship not in fleet.member_ships:  # Not in our fleet
			var distance = ship.global_position.distance_to(mouse_pos)
			if distance < min_distance:
				closest_enemy = ship
				min_distance = distance
	
	return closest_enemy

func _get_targeted_ally() -> Ship:
	# Find ally ship under cursor or nearest to cursor
	var mouse_pos = get_viewport().get_mouse_position()
	var closest_ally = null
	var min_distance = 100.0  # Minimal selection distance
	
	for ship in fleet.member_ships:
		var distance = ship.global_position.distance_to(mouse_pos)
		if distance < min_distance:
			closest_ally = ship
			min_distance = distance
	
	return closest_ally

func _is_ally_targeted() -> bool:
	# Check if an ally is being targeted
	return _get_targeted_ally() != null

func _find_fleet_hud() -> FleetHUD:
	# Try to find a fleet HUD in the scene
	var huds = get_tree().get_nodes_in_group("FleetHUD")
	if huds.size() > 0:
		return huds[0]
	return null

func _on_command_mode_timeout() -> void:
	# Automatically deactivate command mode if no command is issued
	if is_command_mode_active:
		is_command_mode_active = false
		_deactivate_command_mode()

# Utility functions for direct command issuance (can be called from scripts)
func issue_attack_command(target: Ship) -> void:
	_execute_command("attack", target)

func issue_move_command(position: Vector2) -> void:
	_execute_command("move_to", position)

func issue_protect_command(ship: Ship = null) -> void:
	if ship == null:
		_execute_command("protect_flagship")
	else:
		_execute_command("defend", ship)

func issue_scatter_command() -> void:
	_execute_command("scatter")

func issue_regroup_command() -> void:
	_execute_command("form_up")

func set_fleet_formation(formation_type: int) -> void:
	if fleet and is_instance_valid(fleet):
		fleet.formation_manager.set_formation(formation_type)
		
		# Update formation index for UI consistency
		for i in range(available_formations.size()):
			if available_formations[i] == formation_type:
				current_formation_index = i
				break
		
		# Update UI
		if fleet_hud:
			fleet_hud.update_formation_display(formation_type)
