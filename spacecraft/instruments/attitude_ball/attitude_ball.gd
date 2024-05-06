@tool
extends Node3D

signal orientation_changed(rate : float, threshold : float)	# radians per second
signal orientation_stopped

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

var heading : float = deg_to_rad(heading_degrees):
	set(value):
		heading = value
		heading_degrees = rad_to_deg(value)
		
var pitch : float = deg_to_rad(pitch_degrees):
	set(value):
		pitch = value
		pitch_degrees = rad_to_deg(value)
		
var roll : float = deg_to_rad(roll_degrees):
	set(value):
		roll = value
		roll_degrees = rad_to_deg(value)
		

var orientation : Vector3 = Vector3(0.0, 0.0, 0.0):
	set(value):
		orientation = value
		suspend_orientation = true
		heading = value.y
		pitch = value.x
		roll = value.z
		suspend_orientation = false
		_orient_ball_from_angles()

const TIME_TO_FAST_RESET := 1.0
const TIME_TO_SLOW_RESET := 10.0
const THRESHOLD_SOUND_RATE := 0.02 # rate at which the ball starts making noise
var time_to_reset : float
var current_orientation := Quaternion.from_euler(Vector3.UP)
var reference_orientation := Quaternion.from_euler(Vector3.UP)
var target_orientation := Quaternion.from_euler(Vector3.UP)		# the orientation we are seeking during reset
var saved_ship : Spacecraft
var suspend_orientation : bool = false
var reset_in_progress : bool = false
var reset_weight : float
var landed : bool = TYPE_NIL

func _orient_ball_from_angles()->void:
	$Ball/Ball.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	$Ball/Ball.rotate_y(deg_to_rad(-heading_degrees))
	$Ball/Ball.rotate_x(deg_to_rad(pitch_degrees))
	$Ball/Ball.rotate_z(deg_to_rad(-roll_degrees))
	
func _on_spacecraft_state_update(ship : Spacecraft):
	saved_ship = ship
	# the game global frame is stationary (the moon), but it is really rotating, so 
	# we need to add the rotation in for display purposese
	current_orientation = ship.basis.rotated(Vector3.UP, saved_ship.LEVEL.current_moon_rotation).get_rotation_quaternion()

	
# Called when the node enters the scene tree for the first time.
func _ready():
	reset_in_progress = false
	$Ball/Ball.quaternion = reference_orientation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	var reference : Quaternion = reference_orientation
	if reset_in_progress:
		reset_weight = clamp(reset_weight + delta, 0.0, time_to_reset)
		# reference_orientation is initially aligned with moon, thereafter it is
		# the same as the orientation at the end of the last reset. This slerp will
		# create a series of reference orientations that vary from the initial, to the target orientation
		reference = reference_orientation.slerp(target_orientation, pow(reset_weight/time_to_reset, 0.2))
		if reset_weight == time_to_reset:
			reset_in_progress = false
			$ResetButton.state = true
			# reset is complete. Set reference equal to the target_orientation
			reference_orientation = target_orientation
			reference = target_orientation
	# This gives us the net rotation of the ship since the ball was reset
	var deltaq := reference.inverse()*current_orientation
	# This transforms the delta quaternion of the ship to the ball, taking into account 
	# the differnt "forward" axis of the ship and the ball, and
	# the fact that roll rotation is reversed in a nav ball.
	$Ball/Ball.quaternion = Quaternion(deltaq.z, deltaq.y, deltaq.x, deltaq.w)
	var rate : float = saved_ship.angular_velocity.length()
	if rate > THRESHOLD_SOUND_RATE:
		orientation_changed.emit(rate, THRESHOLD_SOUND_RATE)
	else:
		orientation_stopped.emit()
	
func _on_reset_button_pressed(_state):
	# ship must be close to not rotating
	if saved_ship.angular_damp or abs(saved_ship.angular_velocity.length() - saved_ship.LEVEL.moon_axis_rate) < saved_ship.STABILITY_MINIMUM_RATE:
		if saved_ship.angular_damp:
			time_to_reset = TIME_TO_SLOW_RESET
			# target orientation is facing north, wings level at the current spherical position
			# Getting euler angles for lat/lon/heading is mind-blowing. This code corresponds
			# with the process used in Spacecraft/set_logical_position
			var p : Vector3 = (-saved_ship.MOON.position).rotated(Vector3.UP, saved_ship.LEVEL.current_moon_rotation)
			var ey := PI - atan2(p.z,p.x)
			var ez := PI/2.0 - atan2(p.y, Vector2(p.x,p.z).length())
			target_orientation = Quaternion.from_euler(Vector3(0.0, ey, ez))
		else:
			# target orientation is the current ship orientation, corrected for moon rotation
			target_orientation = saved_ship.basis.rotated(Vector3.UP, saved_ship.LEVEL.current_moon_rotation).get_rotation_quaternion()
			time_to_reset = TIME_TO_FAST_RESET
		reset_in_progress = true
		reset_weight = 0.0


func _on_reset_button_released():
	if not reset_in_progress:
		# do not signify that reset is underway
		$ResetButton.state = true


func _on_spacecraft_has_landed():
	landed = true


func _on_spacecraft_has_lifted_off():
	landed = false
