@tool
extends Node3D

@export var ship_bottom : float = 2.4: # height of lander base above ground
	set(value):
		ship_bottom = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var ship_width : float = 3.2: # octagon side-to-side
	set(value):
		ship_width = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var ship_front_width : float = 1.4: # width of forward octagon face
	set(value):
		ship_front_width = value
		if Engine.is_editor_hint():
			_rebuild_model()


@export var pad_span : float = 8.0:
	set(value):
		pad_span = value
		if Engine.is_editor_hint():
			_rebuild_model()
		
@export var vertical_sep : float = 2.0:
	set(value):
		vertical_sep = value
		if Engine.is_editor_hint():
			_rebuild_model()
	
@export var bar_diameter : float = 0.15:
	set(value):
		bar_diameter = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var pad_diameter : float = 0.8:
	set(value):
		pad_diameter = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var pad_height : float = 0.4:
	set(value):
		pad_height = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var leg_material : StandardMaterial3D:
	set(value):
		leg_material = value
		if Engine.is_editor_hint():
			_rebuild_model()


func _build_leg(angle : float, r : float, span : float):
	var top_bar := MeshInstance3D.new()
	add_child(top_bar)
	top_bar.mesh = CapsuleMesh.new()
	top_bar.mesh.radius = bar_diameter / 2.0
	top_bar.mesh.radial_segments = 16
	top_bar.rotation.z = atan(span/(ship_bottom + vertical_sep))
	top_bar.mesh.height = sqrt((ship_bottom+vertical_sep)**2.0 + span**2.0)
	top_bar.rotation.y = angle
	top_bar.position.x = (r + span/2.0)*cos(angle)
	top_bar.position.z = -(r + span/2.0)*sin(angle)
	top_bar.position.y = (ship_bottom + vertical_sep)/2.0
	top_bar.set_surface_override_material(0, leg_material)
	var left_bar := MeshInstance3D.new()
	add_child(left_bar)
	left_bar.mesh = CapsuleMesh.new()
	left_bar.mesh.radius = bar_diameter / 2.0
	left_bar.mesh.radial_segments = 16
	left_bar.rotation.z = atan(span/(ship_bottom + 0.2))
	left_bar.mesh.height = sqrt((ship_bottom+0.2)**2.0 + span**2.0 + 0.5**2.0)
	left_bar.rotation.y = angle - atan(0.5 / span)
	left_bar.position.x = (r + span/2.0)*cos(angle) - 0.25*sin(angle)
	left_bar.position.z = -(r + span/2.0)*sin(angle) - 0.25*cos(angle)
	left_bar.position.y = (ship_bottom + 0.2)/2.0
	left_bar.set_surface_override_material(0, leg_material)
	var right_bar := MeshInstance3D.new()
	add_child(right_bar)
	right_bar.mesh = CapsuleMesh.new()
	right_bar.mesh.radius = bar_diameter / 2.0
	right_bar.mesh.radial_segments = 16
	right_bar.rotation.z = atan(span/(ship_bottom + 0.2))
	right_bar.mesh.height = sqrt((ship_bottom+0.2)**2.0 + span**2.0 + 0.5**2.0)
	right_bar.rotation.y = angle + atan(0.5 / span)
	right_bar.position.x = (r + span/2.0)*cos(angle) + 0.25*sin(angle)
	right_bar.position.z = -(r + span/2.0)*sin(angle) + 0.25*cos(angle)
	right_bar.position.y = (ship_bottom + 0.2)/2.0
	right_bar.set_surface_override_material(0, leg_material)
	var pad := MeshInstance3D.new()
	add_child(pad)
	pad.mesh = CylinderMesh.new()
	pad.mesh.bottom_radius = pad_diameter / 2.0
	pad.mesh.top_radius = pad_diameter / 2.0
	pad.mesh.height = pad_height
	pad.mesh.radial_segments = 16
	pad.position.y = pad_height/2.0
	pad.position.x = sqrt(2.0)*pad_span/2.0*cos(angle)
	pad.position.z = -sqrt(2.0)*pad_span/2.0*sin(angle)
	pad.set_surface_override_material(0, leg_material)


func _rebuild_model():
	for child in get_children():
		child.queue_free()
	var r = sqrt(2.0)*(ship_width + ship_front_width)/4.0
	var span = sqrt(2.0)*pad_span/2.0 - r
	_build_leg(PI/4.0, r, span)
	_build_leg(3.0*PI/4.0, r, span)
	_build_leg(5.0*PI/4.0, r, span)
	_build_leg(7.0*PI/4.0, r, span)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_rebuild_model()
