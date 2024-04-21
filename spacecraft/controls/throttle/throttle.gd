extends Node3D

const dead_band := 0.003
const max_position := 0.2
@onready var SLIDER := $SliderOrigin/XRToolsInteractableSlider

signal throttle_output_changed(value: float)

# Emits a value between 0.0 --> 1.0 corresponding to position
func _on_throttle_slider_moved(position):
	var value : float = 0.0
	if position > dead_band:
		value = (position - dead_band)/(max_position - dead_band)
	throttle_output_changed.emit(value)

# Set the throttle lever to position corresponding to thrust 0.0 --> 1.0
func set_throttle_slider(value):
	var set_value := 0.0
	if value > 0.0:
		set_value = value*(max_position-dead_band) + dead_band
	SLIDER.move_slider(set_value)
