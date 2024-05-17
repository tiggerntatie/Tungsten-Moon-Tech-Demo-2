@tool
extends Node3D

@export var display_value : float = 1.0:
	set(value):
		display_value = value
		if Engine.is_editor_hint():
			_display_is_ready = true
			call_deferred("_update_panel")
		else:
			_update_panel()
			
@export var display_is_valid : bool = true:
	set(value):
		print("2")
		display_is_valid = value
		if Engine.is_editor_hint():
			_display_is_ready = true
		_update_panel()
		
@export_range(1, 8, 1) var number_of_digits : int = 1:
	set(value):
		number_of_digits = value
		if Engine.is_editor_hint():
			call_deferred("_layout_panel")
		else:
			_update_panel()
			
@export_range(0, 7, 1) var number_of_decimals : int = 0:
	set(value):
		number_of_decimals = value
		if Engine.is_editor_hint():
			call_deferred("_layout_panel")
		else:
			_update_panel()

@export var display_colons : bool = false:
	set(value):
		display_colons = value
		if Engine.is_editor_hint():
			call_deferred("_layout_panel")
		else:
			_update_panel()
			
@export var label_text : String = "":
	set(value):
		label_text = value
		if Engine.is_editor_hint():
			call_deferred("_layout_panel")

@export var digit_height : float = 0.015:
	set(value):
		digit_height = value
		if Engine.is_editor_hint():
			call_deferred("_layout_panel")
			
@export var label_height : float = 0.01:
	set(value):
		label_height = value
		if Engine.is_editor_hint():
			call_deferred("_layout_panel")

const FRAME_WIDTH = 0.001	
const FRAME_DEPTH = 0.003
const DIGIT_ASPECT = 0.6
var _display_is_ready : bool = false

# send new data to the panel in realtime
func _update_panel():
	if _display_is_ready:
		$Display.get_surface_override_material(0).set_shader_parameter("number_of_digits", number_of_digits)
		$Display.get_surface_override_material(0).set_shader_parameter("value", display_value)
		$Display.get_surface_override_material(0).set_shader_parameter("dashes", not display_is_valid)
		$Display.get_surface_override_material(0).set_shader_parameter("decimals", number_of_decimals)
		$Display.get_surface_override_material(0).set_shader_parameter("colons", display_colons)

# set up the panel configuration once
func _layout_panel():
	var digit_width = digit_height * DIGIT_ASPECT
	var display_width = digit_width * number_of_digits
	$Display.mesh.size = Vector2(display_width, digit_height)
	$Display.position = Vector3(display_width/2.0, -digit_height/2.0, 0.001)
	$FrameL.mesh.size = Vector3(FRAME_WIDTH, digit_height, FRAME_DEPTH)
	$FrameL.position = Vector3(-FRAME_WIDTH/2, -digit_height/2, FRAME_DEPTH/2)
	$FrameR.mesh.size = Vector3(FRAME_WIDTH, digit_height, FRAME_DEPTH)
	$FrameR.position = Vector3(display_width + FRAME_WIDTH/2, -digit_height/2, FRAME_DEPTH/2)
	$FrameT.mesh.size = Vector3(display_width + FRAME_WIDTH*2, FRAME_WIDTH, FRAME_DEPTH)
	$FrameT.position = Vector3(display_width/2, FRAME_WIDTH/2, FRAME_DEPTH/2)
	$FrameB.mesh.size = Vector3(display_width + FRAME_WIDTH*2, FRAME_WIDTH, FRAME_DEPTH)
	$FrameB.position = Vector3(display_width/2, -(digit_height+FRAME_WIDTH/2), FRAME_DEPTH/2)
	$PanelText.pixel_size = label_height / float($PanelText.font_size)
	$PanelText.text = label_text
	$PanelText.position = Vector3(display_width + digit_width*0.2, -digit_height/2.0, 0.001)
	_update_panel()




# Called when the node enters the scene tree for the first time.
func _ready():
	_layout_panel()
	if not Engine.is_editor_hint():
		Signals.add_user_signal(name + "_set_valid", [{"name":"state", "type": TYPE_BOOL}])
		Signals.add_user_signal(name + "_set_value", [{"name":"value", "type": TYPE_FLOAT}])
		Signals.connect(name + "_set_valid", _on_set_valid)
		Signals.connect(name + "_set_value", _on_set_value)
		# send signal thus:
		# Signals.emit_signal("DisplayFuelPercentage_set_value", fuel_level)
	_display_is_ready = true
 
# Handlers for incoming events
func _on_set_valid(state : bool) -> void:
	display_is_valid = state
	
func _on_set_value(value : float) -> void:
	display_value = value
