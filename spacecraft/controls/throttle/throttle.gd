extends Node3D

const dead_band := 0.003
const max_position := 0.2
@export_range(0.0, 1.0, 0.001) var mouse_speed := 0.2
@export_range(0.0, 1.0, 0.001) var mouse_scroll_speed := 0.5
@onready var SLIDER := $SliderOrigin/XRToolsInteractableSlider
@onready var old_cursor_shape : Input.CursorShape = Input.CURSOR_ARROW
var mouse_pressed := false

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

# get the throttle lever position as 0.0 --> 1.0
func get_throttle_slider() -> float:
	if SLIDER.slider_position <= dead_band:
		return 0.0
	else:
		return (SLIDER.slider_position - dead_band)/(max_position - dead_band)

func _on_mouse_entered():
	Input.set_default_cursor_shape(Input.CursorShape.CURSOR_VSIZE)

func _on_mouse_exited():
	Input.set_default_cursor_shape(old_cursor_shape)
	mouse_pressed = false

func _on_handle_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.get_button_index() == MOUSE_BUTTON_LEFT:
			mouse_pressed = event.is_pressed()
		elif event.get_button_index() == MOUSE_BUTTON_WHEEL_UP:
			set_throttle_slider(get_throttle_slider() + mouse_scroll_speed*0.04)
		elif event.get_button_index() == MOUSE_BUTTON_WHEEL_DOWN:
			set_throttle_slider(get_throttle_slider() - mouse_scroll_speed*0.04)
	elif event is InputEventMouseMotion and mouse_pressed:
		set_throttle_slider(get_throttle_slider() - event.relative.y*mouse_speed/100)
		

