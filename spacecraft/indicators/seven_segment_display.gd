@tool
extends Node3D

@export var number_of_digits : int = 1:
	set(value):
		number_of_digits = value
		if Engine.is_editor_hint():
			_layout_digits()
	
@export var label_text : String = "":
	set(value):
		label_text = value
		if Engine.is_editor_hint():
			_layout_digits()
			
@export var digit_height : float = 1.5:
	set(value):
		digit_height = value
		if Engine.is_editor_hint():
			_layout_digits()

const FRAME_WIDTH = 0.1	# cm
const DIGIT_WIDTH = 1.75
const DIGIT_HEIGHT = 2.5
var digit_array := []
var digit_scene
		
func _layout_digits():
	digit_scene = preload("res://spacecraft/indicators/seven_segment_digit.tscn")
	# references to the tree
	$PanelText.text = label_text
	# clean out old children
	for digit in digit_array:
		digit.queue_free()
	digit_array = []
	var x_pos = 0.0
	var y_pos = 0.0
	var digit_index := 0
	for digit_num in range(number_of_digits):
		var inst = digit_scene.instantiate()
		digit_array.push_back(inst)
		add_child(inst)
		inst.name = name + "Digit" + str(digit_num)
		inst.position = Vector3(x_pos, y_pos, inst.position.z)
		x_pos += DIGIT_WIDTH
	$PanelText.position.x = x_pos + DIGIT_WIDTH*0.2
	$PanelText.position.y = -DIGIT_HEIGHT/2.0
	scale = Vector3.ONE * 0.01 * digit_height / DIGIT_HEIGHT
	

# Called when the node enters the scene tree for the first time.
func _ready():
	_layout_digits()
