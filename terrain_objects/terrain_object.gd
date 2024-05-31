extends Node3D

class_name TerrainObject

@export var moon_data : MoonData

## Latitude of the object in degrees
@export var latitude : float

## Longitude of the object in degrees
@export var longitude : float

## Heading of the object in degrees
@export var heading : float

## Altitude offset (increase/decrease height)
@export var altitude_adjust : float = 0.0

# range to ship at which global_position is managed directly
const HIGH_PRECISION_RANGE := 500.0

# default moon scale 
var default_moon_scale_set : bool = false
var default_moon_scale : float
var dv_relative_position : DVector3
var dv_moon_position : DVector3

func _on_moon_position_changed(dv_position : DVector3, moon_scale: Vector3):
	var fscale := 1.0
	if not default_moon_scale_set:
		position = position*moon_scale.x
		default_moon_scale = moon_scale.x
		dv_relative_position.multiply_scalar(moon_scale.x)
		default_moon_scale_set = true
	if global_position.length() < HIGH_PRECISION_RANGE:
		top_level = true
		dv_moon_position = dv_position
		global_position = DVector3.Add(dv_moon_position, dv_relative_position).vector3()
	else:
		top_level = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("moon_position_changed", _on_moon_position_changed)
	rotation = moon_data.get_object_surface_rotation(latitude, longitude, heading)
	dv_relative_position = DVector3.FromVector3(moon_data.get_vector_position(latitude, longitude))
	dv_relative_position.multiply_scalar(
		moon_data.get_terrain_altitude(latitude, longitude, 1.0) + 
		moon_data.radius
	)
	position = dv_relative_position.vector3()
	$StaticBody3D.position.y = altitude_adjust


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
