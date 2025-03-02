extends CanvasLayer
class_name FleetHUD

# References to UI elements
@onready var fleet_panel = $FleetPanel
@onready var ships_container = $FleetPanel/ShipsContainer
@onready var formation_label = $FleetPanel/FormationLabel
@onready var command_panel = $CommandPanel
@onready var target_selection_panel = $TargetSelectionPanel

# Fleet reference
var fleet: Fleet

# UI elements for each ship in the fleet
var ship_ui_elements = {}

# Formation names for display
var formation_names = {
	FleetFormationManager.FormationType.LINE: "Line Formation",
	FleetFormationManager.FormationType.V_FORMATION: "V Formation",
	FleetFormationManager.FormationType.CIRCLE: "Circle Formation",
	FleetFormationManager.FormationType.SQUARE: "Square Formation",
	FleetFormationManager.FormationType.WEDGE: "Wedge Formation",
	FleetFormationManager.FormationType.ECHELON: "Echelon Formation",
	FleetFormationManager.FormationType.CUSTOM: "Custom Formation"
}

func _ready() -> void:
	# Initial state - command mode inactive
	command_panel.visible = false
	target_selection_panel.visible = false
	
	# Ensure we're in the FleetHUD group for easy access
	add_to_group("FleetHUD")
	
	# Connect button signals
	_connect_command_buttons()

func set_fleet(new_fleet: Fleet) -> void:
	# Clean up any existing connections
	if fleet:
		_disconnect_fleet_signals()
	
	# Set new fleet
	fleet = new_fleet
	
	if fleet:
		# Connect to fleet signals
		_connect_fleet_signals()
		
		# Refresh the fleet display
		refresh_fleet_display()

func refresh_fleet_display() -> void:
	# Clear existing UI elements
	for element in ship_ui_elements.values():
		if is_instance_valid(element):
			element.queue_free()
	ship_ui_elements.clear()
	
	# Create UI elements for each ship
	if fleet:
		for ship in fleet.member_ships:
			_add_ship_ui(ship)
		
		# Update formation display
		update_formation_display(fleet.formation_manager.current_formation)

func _add_ship_ui(ship: Ship) -> void:
	# Create a UI element for this ship
	var ship_item = preload("res://UI/Fleet/Fleet_Ship_Item.tscn").instantiate()
	ships_container.add_child(ship_item)
	
	# Configure the UI element
	ship_item.set_ship(ship)
	
	# Mark flagship if applicable
	if ship == fleet.flagship:
		ship_item.set_flagship(true)
	
	# Store reference
	ship_ui_elements[ship] = ship_item

func show_command_mode() -> void:
	command_panel.visible = true
	fleet_panel.visible = true

func hide_command_mode() -> void:
	command_panel.visible = false
	target_selection_panel.visible = false
	
	# Keep ship list visible if there are ships
	fleet_panel.visible = fleet and fleet.member_ships.size() > 0

func show_target_selection(command: String) -> void:
	target_selection_panel.visible = true
	
	# Configure target selection UI based on command
	var target_label = $TargetSelectionPanel/Label
	
	match command:
		"attack":
			target_label.text = "Select target to attack"
		"defend":
			target_label.text = "Select position or ally to defend"
		"move_to":
			target_label.text = "Select position to move to"
		_:
			target_label.text = "Select target"

func hide_target_selection() -> void:
	target_selection_panel.visible = false

func update_formation_display(formation_type: int) -> void:
	if formation_names.has(formation_type):
		formation_label.text = "Formation: " + formation_names[formation_type]
	else:
		formation_label.text = "Formation: Unknown"

func update_ship_status(ship: Ship) -> void:
	# Update UI for a specific ship
	if ship_ui_elements.has(ship):
		ship_ui_elements[ship].update_status()

func _on_ship_added(ship: Ship) -> void:
	_add_ship_ui(ship)
	
	# Show fleet panel if it was hidden
	fleet_panel.visible = true

func _on_ship_removed(ship: Ship) -> void:
	# Remove UI element for this ship
	if ship_ui_elements.has(ship):
		if is_instance_valid(ship_ui_elements[ship]):
			ship_ui_elements[ship].queue_free()
		ship_ui_elements.erase(ship)
	
	# Hide fleet panel if no ships left
	if fleet.member_ships.size() == 0:
		fleet_panel.visible = false

func _on_flagship_changed(ship: Ship) -> void:
	# Update flagship indicators
	for s in ship_ui_elements:
		if is_instance_valid(ship_ui_elements[s]):
			ship_ui_elements[s].set_flagship(s == ship)

func _connect_fleet_signals() -> void:
	if fleet:
		fleet.connect("ship_added", Callable(self, "_on_ship_added"))
		fleet.connect("ship_removed", Callable(self, "_on_ship_removed"))
		fleet.connect("flagship_changed", Callable(self, "_on_flagship_changed"))

func _disconnect_fleet_signals() -> void:
	if fleet:
		if fleet.is_connected("ship_added", Callable(self, "_on_ship_added")):
			fleet.disconnect("ship_added", Callable(self, "_on_ship_added"))
		
		if fleet.is_connected("ship_removed", Callable(self, "_on_ship_removed")):
			fleet.disconnect("ship_removed", Callable(self, "_on_ship_removed"))
		
		if fleet.is_connected("flagship_changed", Callable(self, "_on_flagship_changed")):
			fleet.disconnect("flagship_changed", Callable(self, "_on_flagship_changed"))

func _connect_command_buttons() -> void:
	# Connect UI buttons to commands
	$CommandPanel/AttackButton.pressed.connect(Callable(self, "_on_attack_button_pressed"))
	$CommandPanel/DefendButton.pressed.connect(Callable(self, "_on_defend_button_pressed"))
	$CommandPanel/MoveButton.pressed.connect(Callable(self, "_on_move_button_pressed"))
	$CommandPanel/ScatterButton.pressed.connect(Callable(self, "_on_scatter_button_pressed"))
	$CommandPanel/RegroupButton.pressed.connect(Callable(self, "_on_regroup_button_pressed"))
	$CommandPanel/FormationNextButton.pressed.connect(Callable(self, "_on_formation_next_button_pressed"))
	$CommandPanel/FormationPrevButton.pressed.connect(Callable(self, "_on_formation_prev_button_pressed"))

# UI Button handlers
func _on_attack_button_pressed() -> void:
	# Tell fleet commander to initiate attack command
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander.current_command = "attack"
		fleet_commander._prepare_target_selection()

func _on_defend_button_pressed() -> void:
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander.current_command = "defend"
		fleet_commander._prepare_target_selection()

func _on_move_button_pressed() -> void:
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander.current_command = "move_to"
		fleet_commander._prepare_target_selection()

func _on_scatter_button_pressed() -> void:
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander._execute_command("scatter")

func _on_regroup_button_pressed() -> void:
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander._execute_command("form_up")

func _on_formation_next_button_pressed() -> void:
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander._cycle_formation(1)

func _on_formation_prev_button_pressed() -> void:
	var fleet_commander = _get_fleet_commander()
	if fleet_commander:
		fleet_commander._cycle_formation(-1)

func _get_fleet_commander() -> PlayerFleetCommander:
	# Find the player fleet commander
	var commanders = get_tree().get_nodes_in_group("FleetCommander")
	for commander in commanders:
		if commander is PlayerFleetCommander:
			return commander
	return null
