@tool
extends Node3D

@export_range(0.0, 359.9, 0.1) var heading_degrees : float = 0.0:
	set(value):
		heading_degrees = value
		if not suspend_orientation:
			_orient_ball_from_angles()
		
@export_range(-90.0, 90.0, 0.1) var pitch_degrees : float = 0.0:
	set(value):
		pitch_degrees = value
		if not suspend_orientation:
			_orient_ball_from_angles()
		
@export_range(-180.0, 180.0, 0.1) var roll_degrees : float = 0.0:
	set(value):
		roll_degrees = value
		if not suspend_orientation:
			_orient_ball_from_angles()
		
var orientation : Vector3 = Vector3(0.0, 0.0, 0.0):
	set(value):
		orientation = value
		suspend_orientation = true
		heading_degrees = rad_to_deg(value.y)
		pitch_degrees = rad_to_deg(value.x)
		roll_degrees = rad_to_deg(value.z)
		suspend_orientation = false
		_orient_ball_from_angles()

const TIME_TO_FAST_RESET := 1.0
var current_orientation := Quaternion.from_euler(Vector3.UP)
var reference_orientation := Quaternion.from_euler(Vector3.UP)
var target_orientation := Quaternion.from_euler(Vector3.UP)		# the orientation we are seeking during reset
var saved_ship : Spacecraft
var suspend_orientation : bool = false
var reset_in_progress : bool = false
var reset_weight : float

func _orient_ball_from_angles()->void:
	$Ball/Ball.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	$Ball/Ball.rotate_y(deg_to_rad(-heading_degrees))
	$Ball/Ball.rotate_x(deg_to_rad(pitch_degrees))
	$Ball/Ball.rotate_z(deg_to_rad(-roll_degrees))
	
func _on_spacecraft_state_update(ship : Spacecraft):
	saved_ship = ship
	current_orientation = ship.basis.get_rotation_quaternion()

# Called when the node enters the scene tree for the first time.
func _ready():
	reset_in_progress = false
	_orient_ball_from_angles()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	var reference : Quaternion = reference_orientation
	if reset_in_progress:
		reset_weight = clamp(reset_weight + delta, 0.0, TIME_TO_FAST_RESET)
		reference = reference_orientation.slerp(target_orientation, pow(reset_weight/TIME_TO_FAST_RESET, 0.2))
		if reset_weight == TIME_TO_FAST_RESET:
			reset_in_progress = false
			$ResetButton.state = true
			reference_orientation = target_orientation
			reference = target_orientation
	var angles : Vector3 = (reference.inverse()*current_orientation).get_euler()  
	orientation = Vector3(angles.z, -angles.y, -angles.x)
	#$Ball/Ball.

func _on_reset_button_pressed(state):
	if saved_ship.angular_velocity.length() < saved_ship.STABILITY_MINIMUM_RATE:
		reset_in_progress = true
		reset_weight = 0.0
		target_orientation = saved_ship.quaternion


func _on_reset_button_released():
	if not reset_in_progress:
		# do not signify that reset is underway
		$ResetButton.state = true
