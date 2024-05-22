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
	
@export var angle_degrees : float = 45.0:
	set(value):
		angle_degrees = value
		if Engine.is_editor_hint():
			_rebuild_model()



func _rebuild_model():
	var angle = deg_to_rad(angle_degrees)
	var r = sqrt(2.0)*(ship_width + ship_front_width)/4.0
	var span = sqrt(2.0)*pad_span/2.0 - r
	$TopBar.rotation.z = atan(span/(ship_bottom + vertical_sep))
	$TopBar.mesh.height = sqrt((ship_bottom+vertical_sep)**2.0 + span**2.0)
	$TopBar.rotation.y = angle
	$TopBar.position.x = (r + span/2.0)*cos(angle)
	$TopBar.position.z = -(r + span/2.0)*sin(angle)
	$TopBar.position.y = (ship_bottom + vertical_sep)/2.0
	$LeftBar.rotation.z = atan(span/(ship_bottom + 0.2))
	$LeftBar.mesh.height = sqrt((ship_bottom+0.2)**2.0 + span**2.0 + 0.5**2.0)
	$LeftBar.rotation.y = angle - atan(0.5 / span)
	$LeftBar.position.x = (r + span/2.0)*cos(angle) - 0.25*sin(angle)
	$LeftBar.position.z = -(r + span/2.0)*sin(angle) - 0.25*cos(angle)
	$LeftBar.position.y = (ship_bottom + 0.2)/2.0
	$RightBar.rotation.z = atan(span/(ship_bottom + 0.2))
	$RightBar.mesh.height = sqrt((ship_bottom+0.2)**2.0 + span**2.0 + 0.5**2.0)
	$RightBar.rotation.y = angle + atan(0.5 / span)
	$RightBar.position.x = (r + span/2.0)*cos(angle) + 0.25*sin(angle)
	$RightBar.position.z = -(r + span/2.0)*sin(angle) + 0.25*cos(angle)
	$RightBar.position.y = (ship_bottom + 0.2)/2.0
	$Pad.position.y = $Pad.mesh.height/2.0
	$Pad.position.x = sqrt(2.0)*pad_span/2.0*cos(angle)
	$Pad.position.z = -sqrt(2.0)*pad_span/2.0*sin(angle)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_rebuild_model()
