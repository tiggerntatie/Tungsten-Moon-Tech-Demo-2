@tool
extends Node3D

signal pressed(name: String, legend: String, state: bool, light_state: bool)
signal released(name: String, legend: String, state: bool, light_state: bool)
signal changed(name: String, legend: String, state: bool, light_state: bool)
signal light_changed(name: String, legend: String, state: bool, light_state: bool)

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

@export var light_automatic : bool = true

## button state
@export var state : bool = false:
	set(value):
		state = value
		_set_state()
		
## button light state
@export var light_state : bool = false:
	set(value):
		light_state = value
		_set_state()
				
func _update_button():
	$Button/MeshInstance3D.mesh.size.x = width
	$Button/MeshInstance3D.mesh.size.y = height
	$Button/CollisionShape3D.shape.size.x = width
	$Button/CollisionShape3D.shape.size.y = height
	$Guard/Left.position.x = -width/2.0-$Guard/Left.mesh.size.x/2.0
	$Guard/Left.mesh.size.y = height
	$Guard/CollisionShapeLeft.position.x = -width/2.0-$Guard/CollisionShapeLeft.shape.size.x/2.0
	$Guard/CollisionShapeLeft.shape.size.y = height
	$Guard/Right.position.x = width/2.0+$Guard/Right.mesh.size.x/2.0
	$Guard/Right.mesh.size.y = height
	$Guard/CollisionShapeRight.position.x = width/2.0+$Guard/CollisionShapeRight.shape.size.x/2.0
	$Guard/CollisionShapeRight.shape.size.y = height
	$InteractableAreaButton/CollisionShape3D.shape.size.x = width
	$InteractableAreaButton/CollisionShape3D.shape.size.y = height
	$HandPoseArea/CollisionShape3D.shape.size.x = width + 0.005
	$HandPoseArea/CollisionShape3D.shape.size.y = height + 0.005
	$Button/Label3D.text = legend
	_set_state()
	
func _set_state():
	if light_automatic:
		set_button_light(state)			
	$Button/MeshInstance3D.get_surface_override_material(0).emission_enabled = light_state
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
		pressed.emit(name, legend, state, light_state)
	
func release_button() -> void:
	released.emit(name, legend, state, light_state)

# set the state
func set_button(value : bool) -> void:
	if value != state:
		state = value
		changed.emit(name, legend, state, light_state)

# set the state
func set_button_light(value : bool) -> void:
	if value != light_state:
		light_state = value
		light_changed.emit(name, legend, state, light_state)

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
	if $InteractableAreaButton.pressed:
		$InteractableAreaButton._on_button_exited($".")
		release_button()
