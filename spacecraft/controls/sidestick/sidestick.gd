extends Node3D

const dead_band := 3	# degrees
@onready var SIDESTICK := $SideStickOrigin/XRToolsInteractableJoystick
@onready var max_position : float = SIDESTICK.joystick_x_limit_max	 # degrees, +-
var is_grabbed := false

signal sidestick_output_changed(x: float, y: float) # range from -1.0 -> 1.0

# Emits values between -1.0 --> 1.0 corresponding to position
func _on_sidestick_moved(x_angle, y_angle):
	var x : float = 0.0
	var y : float = 0.0
	if abs(x_angle) > dead_band:
		var pmx : float = sign(x_angle)
		x = (x_angle - pmx*dead_band) / (max_position - dead_band)
	if abs(y_angle) > dead_band:
		var pmy : float = sign(y_angle)
		y = (y_angle - pmy*dead_band) / (max_position - dead_band)
	sidestick_output_changed.emit(x, y)

# Set the sidestick to position corresponding to -1.0 --> 1.0
func set_sidestick(x: float, y: float):
	if not is_grabbed:
		var set_x_angle := 0.0
		var set_y_angle := 0.0
		if x != 0.0:
			set_x_angle = x*(max_position-dead_band) + sign(x)*dead_band
		if y != 0.0:
			set_y_angle = y*(max_position-dead_band) + sign(y)*dead_band
		SIDESTICK.move_joystick(deg_to_rad(set_x_angle), deg_to_rad(set_y_angle))


func _on_sidestick_grabbed(interactable):
	is_grabbed = true


func _on_sidestick_released(interactable):
	is_grabbed = false
