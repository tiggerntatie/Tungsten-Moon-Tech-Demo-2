@tool
extends Node3D

signal button_pressed
signal button_released

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
	button_released.emit()

func set_button(value: bool) -> void:
	state = value
	BUTTON.get_surface_override_material(0).emission_enabled = state

func get_button() -> bool:
	return state
	
func press_button() -> void:
	if is_toggle:
		set_button(not state)
	button_pressed.emit()

