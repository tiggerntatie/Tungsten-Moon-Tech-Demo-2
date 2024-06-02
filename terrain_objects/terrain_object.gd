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

# range at which the object becomes invisible
const VISIBLE_RANGE := 10000.0
const BURIED_LENGTH := 10.0	# nominal length of pedestal buried beneath ground
@onready var PAD : MeshInstance3D = $StaticBody3D/PadSurface
@onready var PEDESTAL : MeshInstance3D = $StaticBody3D/Pedestal

# default moon scale 
var default_moon_scale_set : bool = false
var default_moon_scale : Vector3
var dv_relative_position : DVector3
var last_moon_scale : Vector3
var check_visible : bool = true
var run_timer : bool = false

func _on_moon_position_changed(dv_position : DVector3, moon_scale: Vector3):
	if not default_moon_scale_set:
		position = position*moon_scale.x
		default_moon_scale = moon_scale
		last_moon_scale = moon_scale
		dv_relative_position.multiply_scalar(moon_scale.x)
		default_moon_scale_set = true
	elif moon_scale != last_moon_scale:
		# only reset scale when it changes
		scale = Vector3.ONE*(moon_scale.x/default_moon_scale.x)
		last_moon_scale = moon_scale
	# only update global_position when it is visible
	if visible or check_visible:
		if check_visible:
			check_visible = false
		global_position = DVector3.Add(
			dv_position, 
			DVector3.Mul(scale.x, dv_relative_position)
			).vector3()
		if global_position.length()/scale.x < VISIBLE_RANGE:
			if run_timer:
				print("stop timer")
				run_timer = false
			visible = true
		else:
			visible = false
			if not run_timer:
				print("begin timers")
				start_timer()
			
			

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
	PEDESTAL.mesh.top_radius = PAD.mesh.top_radius/4
	PEDESTAL.mesh.bottom_radius = PEDESTAL.mesh.top_radius
	PEDESTAL.mesh.height = altitude_adjust + BURIED_LENGTH
	PEDESTAL.position = Vector3(0.0, -PEDESTAL.mesh.height/2.0, 0.0)
	top_level = true

# periodically update the object position and make visible if necessary
func start_timer():
	var scene := get_tree()
	if scene != null:
		run_timer = true
		var timer := scene.create_timer(10.0)
		timer.timeout.connect(_on_timer_timeout)
	
func _on_timer_timeout():
	check_visible = true
	if run_timer:
		print("restart timer")
		start_timer()
