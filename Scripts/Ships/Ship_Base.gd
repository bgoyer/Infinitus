extends CharacterBody2D
class_name Ship

var thruster: Thruster
var turning: Turning
var locked: bool = false
var pilot: Pilot
var max_velocity: float

func _ready() -> void:
    set_pilot_or_null()
    
func _physics_process(delta: float) -> void:
    move_and_slide()

func accelerate(delta: float) -> void:
    if locked == false:
        locked = true
    
    if thruster == null:
        thruster = get_thruster()
    
    if is_thruster_installed():
        if thruster:
            if velocity.length() < max_velocity:
                velocity += -transform.y * thruster.thrust  * delta * 100
            else:
                velocity *= 0.99

func accelerate_done():
    if locked == true:
        locked = false


func turn_left(delta: float) -> void:
    if turning == null:
            turning = get_turning()
    if is_turning_installed():
        if turning:
            self.global_rotation += (-turning.thrust * delta)

func turn_right(delta: float) -> void:
    if turning == null:
        turning = get_turning()
    if is_turning_installed():
        if turning:
            self.rotate(turning.thrust * delta)

func turn_behind(delta: float) -> void:
    if turning == null:
        turning = get_turning()
    if is_turning_installed() and velocity.length() > 0:
        # Compute the target rotation (adjust the -PI/2 offset if your sprite faces a different direction)
        var target_rotation = (-velocity).angle() + PI/2
        # Calculate the smallest angle difference in the range [-PI, PI]
        var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
        # If the difference is negligible, do nothing.
        if abs(angle_diff) < 0.01:
            return
        # Call the appropriate turning function to gradually rotate toward the target.
        if angle_diff > 0:
            turn_right(delta)
        else:
            turn_left(delta)




####################################Checks######################################

func set_pilot_or_null() -> Pilot:
    for child in self.get_children():
        if child is Pilot:
            child.set_ship(self)
            return child
    return null

func is_thruster_installed() -> bool:
    for child in self.get_children():
        if child is Thruster:
            return true
    return false

func get_thruster() -> Thruster:
    for child in self.get_children():
        if child is Thruster:
            return child
    return null
    
func is_turning_installed() -> bool:
    for child in self.get_children():
        if child is Turning:
            return true
    return false

func get_turning() -> Turning:
    for child in self.get_children():
        if child is Turning:
            return child
    return null
