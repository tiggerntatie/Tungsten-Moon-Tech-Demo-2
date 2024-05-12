@tool
extends Node3D

signal pressed(name: String, legend: String, state: bool, light_state: bool)
signal released(name: String, legend: String, state: bool, light_state: bool)
signal changed(name: String, legend: String, state: bool, light_state: bool)
signal light_changed(name: String, legend: String, state: bool, light_state: bool)

@export var legend : String = "":
	set(value):
		legend = value
		_update_button()
		
@export var legend_image : Texture2D = null:
	set(value):
		legend_image = value
		_update_button()

@export_range(0.01, 100.0, 0.01) var legend_image_scale : float = 1.0:
	set(value):
		legend_image_scale = value
		_update_button()

@export var panel_label : String = "":
	set(value):
		panel_label = value
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
				
const default_legend_image_scale := 0.003
				
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
	$PanelText.position.x = width/2.0+$Guard/Right.mesh.size.x+0.005
	$PanelText.text = panel_label
	if legend_image == null:
		$Button/Label3D.text = legend
		$Button/Label3D.visible = true
		$Button/Sprite3D.visible = false
	else:
		$Button/Sprite3D.texture = legend_image
		$Button/Label3D.visible = false
		$Button/Sprite3D.visible = true
		$Button/Sprite3D.scale = Vector3.ONE * default_legend_image_scale * legend_image_scale
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
	# define signals for reporting and changing state
	if not Engine.is_editor_hint():
		Signals.add_user_signal(name + "_pressed", [{"name":"state", "type": TYPE_BOOL}, {"name":"light_state", "type": TYPE_BOOL}])
		Signals.add_user_signal(name + "_released", [{"name":"state", "type": TYPE_BOOL}, {"name":"light_state", "type": TYPE_BOOL}])
		Signals.add_user_signal(name + "_changed", [{"name":"state", "type": TYPE_BOOL}, {"name":"light_state", "type": TYPE_BOOL}])
		Signals.add_user_signal(name + "_light_changed", [{"name":"state", "type": TYPE_BOOL}, {"name":"light_state", "type": TYPE_BOOL}])
		Signals.add_user_signal(name + "_press")
		Signals.add_user_signal(name + "_set_state", [{"name":"state", "type": TYPE_BOOL}, {"name":"light_state", "type": TYPE_BOOL}])
		Signals.add_user_signal(name + "_set_light_state", [{"name":"state", "type": TYPE_BOOL}, {"name":"light_state", "type": TYPE_BOOL}])
		Signals.connect(name + "_press", _on_press)
		Signals.connect(name + "_set_state", _on_set_state)
		Signals.connect(name + "_set_light_state", _on_set_light_state)
	_update_button()
		

func press_button() -> void:
	pressed.emit(name, legend, state, light_state)
	if is_toggle:
		set_button(not state)
	else:
		Signals.emit_signal(name + "_pressed", state, light_state)
	
func release_button() -> void:
	released.emit(name, legend, state, light_state)
	if not is_toggle:
		Signals.emit_signal(name + "_released", state, light_state)


# set the state
func set_button(value : bool) -> void:
	if value != state:
		state = value
		if light_automatic:
			light_state = value
		changed.emit(name, legend, state, light_state)
		if not Engine.is_editor_hint():
			Signals.emit_signal(name + "_changed", state, light_state)

# set the state
func set_button_light(value : bool) -> void:
	if value != light_state:
		light_state = value
		light_changed.emit(name, legend, state, light_state)
		if not Engine.is_editor_hint():
			Signals.emit_signal(name + "_light_changed", state, light_state)

func _on_interactable_area_button_pressed(button):
	press_button()
	
func _on_interactable_area_button_released(button):
	release_button()
	
func _on_button_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			$InteractableAreaButton._on_button_entered($".")
		elif event.is_released():
			$InteractableAreaButton._on_button_exited($".")

func _on_mouse_exited():
	if $InteractableAreaButton.pressed:
		$InteractableAreaButton._on_button_exited($".")
		
# incocming signal to set button state
func _on_set_state(state: bool) -> void:
	set_button(state)

# incoming signal to set light state
func _on_set_light_state(state: bool) -> void:
	set_button_light(state)

# incoming signal to press button
func _on_press() -> void:
	press_button()
