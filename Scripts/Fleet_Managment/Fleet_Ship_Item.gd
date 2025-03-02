extends PanelContainer
class_name FleetShipItem

# UI references
@onready var ship_name_label = $VBoxContainer/ShipNameLabel
@onready var status_label = $VBoxContainer/StatusLabel
@onready var flagship_indicator = $VBoxContainer/FlagshipIndicator
@onready var select_button = $VBoxContainer/SelectButton

# Ship reference
var ship: Ship

# Signals
signal ship_selected(ship)

func _ready() -> void:
	# Connect signals
	select_button.pressed.connect(Callable(self, "_on_select_button_pressed"))
	
	# Initialize UI state
	flagship_indicator.visible = false

func set_ship(new_ship: Ship) -> void:
	ship = new_ship
	
	# Update UI
	if ship:
		var ship_type = ship.get_class()
		ship_name_label.text = ship_type
		update_status()
	else:
		ship_name_label.text = "Unknown Ship"
		status_label.text = "N/A"

func set_flagship(is_flagship: bool) -> void:
	flagship_indicator.visible = is_flagship
	
	if is_flagship:
		ship_name_label.text += " (Flagship)"

func update_status() -> void:
	if not ship or not is_instance_valid(ship):
		status_label.text = "INVALID"
		return
	
	# Get current state from ship's pilot
	var status_text = "Ready"
	var pilot = ship.pilot
	
	if pilot:
		if pilot is AI_Pilot:
			# Get AI state
			match pilot.current_state:
				AI_Pilot.State.IDLE:
					status_text = "Idle"
				AI_Pilot.State.PATROL:
					status_text = "Patrolling"
				AI_Pilot.State.CHASE:
					status_text = "Pursuing"
				AI_Pilot.State.ATTACK:
					status_text = "Attacking"
				AI_Pilot.State.FLEE:
					status_text = "Fleeing"
				AI_Pilot.State.LAND:
					status_text = "Landing"
				AI_Pilot.State.WARP_IN:
					status_text = "Warping In"
				AI_Pilot.State.WARP_OUT:
					status_text = "Warping Out"
		elif pilot is Player:
			status_text = "Player Controlled"
	
	# Add velocity information
	var velocity_magnitude = ship.velocity.length()
	var speed_text = str(int(velocity_magnitude))
	
	# Add any special status
	var special_status = ""
	if ship.locked:
		special_status = " [LOCKED]"
	
	# Combine status information
	status_label.text = status_text + " - " + speed_text + " units/s" + special_status

func _on_select_button_pressed() -> void:
	if ship and is_instance_valid(ship):
		emit_signal("ship_selected", ship)

func _process(_delta: float) -> void:
	# Periodically update status
	if Engine.get_frames_drawn() % 30 == 0:  # Update every 30 frames
		update_status()
