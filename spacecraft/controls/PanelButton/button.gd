@tool
extends Node3D

signal button_pressed(name: String, state: bool)
signal button_released(name: String)
signal button_set(name: String, state: bool)

@export var legend : String = "X":
	set(value):
		legend = value
		_update_button()

@export var width : float = 0.02:
	set(value):
		width = value
		_update_button()
		
@export var height : float = 0.02:
	set(value):
		height = value
		_update_button()

@export var is_toggle : bool = false

## button light state
@export var state : bool = false:
	set(value):
		state = value
		_set_state()
				
func _update_button():
	$Button/MeshInstance3D.mesh.size.x = width
	$Button/MeshInstance3D.mesh.size.y = height
	$Button/CollisionShape3D.shape.size.x = width
	$Button/CollisionShape3D.shape.size.y = height
	$InteractableAreaButton/CollisionShape3D.shape.size.x = width
	$InteractableAreaButton/CollisionShape3D.shape.size.y = height
	$HandPoseArea/CollisionShape3D.shape.size.x = width + 0.005
	$HandPoseArea/CollisionShape3D.shape.size.y = height + 0.005
	$Button/Label3D.text = legend
	_set_state()
	
func _set_state():
	$Button/MeshInstance3D.get_surface_override_material(0).emission_enabled = state
	if state:
		$Button/Label3D.modulate = Color(0.1, 0.1, 0.1)
	else:
		$Button/Label3D.modulate = Color(1.0, 1.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_button()

func press_button() -> void:
	if is_toggle:
		set_button(not state)
	else:
		button_pressed.emit(legend, state)
	
func release_button() -> void:
	button_released.emit(legend)

# set the light state
func set_button(value : bool) -> void:
	state = value
	_set_state()
	button_set.emit(state)

func _on_interactable_area_button_pressed(button):
	press_button()
	
func _on_interactable_area_button_released(button):
	release_button()
	
func _on_button_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			$InteractableAreaButton._on_button_entered($".")
			press_button()
		elif event.is_released():
			$InteractableAreaButton._on_button_exited($".")
			release_button()

func _on_mouse_exited():
	$InteractableAreaButton._on_button_exited($".")
	release_button()
