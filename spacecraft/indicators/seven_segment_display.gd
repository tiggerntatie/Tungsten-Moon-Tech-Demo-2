@tool
extends Node3D

@export var display_value : float = 1.0:
	set(value):
		display_value = value
		if Engine.is_editor_hint():
			_layout_panel()
			
@export var display_is_valid : bool = true:
	set(value):
		display_is_valid = value
		if Engine.is_editor_hint():
			_layout_panel()
		
@export_range(1, 8, 1) var number_of_digits : int = 1:
	set(value):
		number_of_digits = value
		if Engine.is_editor_hint():
			_layout_panel()
			
@export_range(0, 7, 1) var number_of_decimals : int = 0:
	set(value):
		number_of_decimals = value
		if Engine.is_editor_hint():
			_layout_panel()

@export var display_colons : bool = false:
	set(value):
		display_colons = value
		if Engine.is_editor_hint():
			_layout_panel()

@export var label_text : String = "":
	set(value):
		label_text = value
		if Engine.is_editor_hint():
			_layout_panel()

@export var digit_height : float = 0.015:
	set(value):
		digit_height = value
		if Engine.is_editor_hint():
			_layout_panel()
			
@export var label_height : float = 0.01:
	set(value):
		label_height = value
		if Engine.is_editor_hint():
			_layout_panel()

const FRAME_WIDTH = 0.001	
const FRAME_DEPTH = 0.003
const DIGIT_ASPECT = 0.6

func _layout_panel():
	var digit_width = digit_height * DIGIT_ASPECT
	var display_width = digit_width * number_of_digits
	$Display.mesh.size = Vector2(display_width, digit_height)
	$Display.position = Vector3(display_width/2.0, -digit_height/2.0, 0.001)
	$Display.get_surface_override_material(0).set_shader_parameter("number_of_digits", number_of_digits)
	$Display.get_surface_override_material(0).set_shader_parameter("value", display_value)
	$Display.get_surface_override_material(0).set_shader_parameter("dashes", not display_is_valid)
	$Display.get_surface_override_material(0).set_shader_parameter("decimals", number_of_decimals)
	$Display.get_surface_override_material(0).set_shader_parameter("colons", display_colons)
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




# Called when the node enters the scene tree for the first time.
func _ready():
	_layout_panel()
