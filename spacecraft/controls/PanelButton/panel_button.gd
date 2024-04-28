@tool
extends Node3D

signal button_pressed(state: bool)
signal button_released
signal button_set(state: bool)

@onready var LABEL : Label3D = $ButtonBase/Label3D
@onready var BASE : MeshInstance3D = $ButtonBase/MeshInstance3D
@onready var BUTTON : MeshInstance3D = $Button/MeshInstance3D

@export var label_text : String:
	set(value):
		label_text = value
		$ButtonBase/Label3D.text = value

## Toggle Button
@export var is_toggle : bool = true

## Initial button state
@export var state : bool = false

## Render Layer
@export_flags_2d_render var layers:
	set(value):
		layers = value
		$ButtonBase/MeshInstance3D.layers = value
		$Button/MeshInstance3D.layers = value

func _ready():
	BUTTON.get_surface_override_material(0).emission_enabled = state

func _on_button_pressed(button):
	press_button()
	
func _on_button_released(button):
	if not is_toggle:
		BUTTON.get_surface_override_material(0).emission_enabled = false
		button_released.emit()

func set_button(value: bool) -> void:
	if value != state:
		if value:
			button_pressed.emit(value)
		else:
			button_released.emit()
	state = value
	BUTTON.get_surface_override_material(0).emission_enabled = state
	button_set.emit(state)

func get_button() -> bool:
	return state
	
func press_button() -> void:
	if is_toggle:
		set_button(not state)
	else:
		BUTTON.get_surface_override_material(0).emission_enabled = true	
		button_pressed.emit(state)

func release_button() -> void:
	if not is_toggle:
		BUTTON.get_surface_override_material(0).emission_enabled = false
		button_released.emit()

func _on_button_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			press_button()
		elif event.is_released():
			release_button()
	
