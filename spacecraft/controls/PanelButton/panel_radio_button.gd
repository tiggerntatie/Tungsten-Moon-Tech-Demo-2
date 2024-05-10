@tool
extends Node3D

signal radio_button_pressed(legend : String)

@export var label_text : String:
	set(value):
		label_text = value
		call_deferred("_resize")
		
const DEFAULT_BASE_WIDTH : float = 0.12
@export var base_width : float =  DEFAULT_BASE_WIDTH:
	set(value):
		base_width = value
		call_deferred("_resize")

var button_qty : int
@export var buttons : Array = ["0", "1"]:
	set(value):
		buttons = value
		button_qty = value.size()
		call_deferred("_resize")

@export var button_width : float = 0.02:
	set(value):
		button_width = value
		call_deferred("_resize")

@export var button_padding : float = 0.005:
	set(value):
		button_padding = value
		call_deferred("_resize")

@export var active_button : String = "0":
	set(value):
		active_button = value
		call_deferred("_illuminate_buttons")

## Render Layer
@export_flags_2d_render var layers:
	set(value):
		layers = value
		call_deferred("_resize")

var button_array := []
var button_scene

func _resize():
	button_scene = preload("res://spacecraft/controls/PanelButton/button.tscn")
	# references to the tree
	$ButtonBase/MeshInstance3D.layers = layers
	$ButtonBase/Label3D.layers = layers
	$ButtonBase/Label3D.text = label_text
	# clean out old children
	var width = base_width
	if label_text.length() == 0:
		width = buttons.size()*(button_width + 2.0 * button_padding)
	for butt in button_array:
		butt.queue_free()
	button_array = []
	$ButtonBase/MeshInstance3D.mesh.size.x = width
	$ButtonBase/CollisionShape3D.shape.size.x = width
	var x_pos = -width/2.0
	for label in buttons:
		x_pos += button_width/2.0 + button_padding
		var inst = button_scene.instantiate()
		button_array.push_back(inst)
		inst.pressed.connect(_on_button_pressed)
		add_child(inst)
		inst.legend = label
		inst.width = button_width
		inst.position = Vector3(x_pos, 0.0, 0.008)
		x_pos += button_width/2.0 + button_padding
	$ButtonBase/Label3D.position.x = x_pos
	_illuminate_buttons()
	
func _illuminate_buttons() -> void:
	for butt in button_array:
		if butt.legend == active_button:
			butt.set_button(true)
		else:
			butt.set_button(false)

func set_radio_button(legend : String) -> void:
	radio_button_pressed.emit(legend)
	active_button = legend


func _ready():
	_resize()

func _on_button_pressed(name: String, legend: String, state: bool, light_state: bool):
	set_radio_button(legend)
