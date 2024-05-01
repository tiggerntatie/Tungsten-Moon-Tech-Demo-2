@tool
extends Node3D

@export_range(0.0, 359.9, 0.1) var heading_degrees : float = 0.0:
	set(value):
		heading_degrees = value
		_orient_ball_from_angles()
		
@export_range(-90.0, 90.0, 0.1) var pitch_degrees : float = 0.0:
	set(value):
		pitch_degrees = value
		_orient_ball_from_angles()
		
@export_range(-180.0, 180.0, 0.1) var roll_degrees : float = 0.0:
	set(value):
		roll_degrees = value
		_orient_ball_from_angles()
		
var orientation : Vector3 = Vector3(0.0, 0.0, 0.0):
	set(value):
		orientation = value
		heading_degrees = rad_to_deg(value.y)
		pitch_degrees = rad_to_deg(value.x)
		roll_degrees = rad_to_deg(value.z)
		
func _orient_ball_from_angles()->void:
	$Ball/Ball.rotation_degrees = Vector3(0.0, 175.0, 0.0)
	$Ball/Ball.rotate(Vector3.UP, deg_to_rad(-heading_degrees))
	$Ball/Ball.rotate(Vector3.RIGHT, deg_to_rad(pitch_degrees))
	$Ball/Ball.rotate(Vector3.FORWARD, deg_to_rad(-roll_degrees))
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_orient_ball_from_angles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
