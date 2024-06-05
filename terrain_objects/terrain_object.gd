extends Node3D

class_name TerrainObject

@export var moon_data : MoonData

## Identifier of the object
@export var identifier : String

## Longitude of the object in degrees
@export var longitude : float:
	set(value):
		longitude = value
		Signals.emit_signal("terrain_object_moved", identifier, longitude, latitude)

## Latitude of the object in degrees
@export var latitude : float:
	set(value):
		latitude = value
		Signals.emit_signal("terrain_object_moved", identifier, longitude, latitude)

## Heading of the object in degrees
@export var heading : float

## Altitude offset (increase/decrease height)
@export var altitude_adjust : float = 0.0

@export_category("Relative position")
## Compute relative position from reference object
@export var relative_position : bool = false

## Reference terrain object
@export var reference_object : TerrainObject

## Departure bearing from reference object, in degrees
@export var departure_bearing : float = 0.0

## Distance from reference object, in meters
@export var distance_from_reference : float = 100.0

# range at which the object becomes invisible
const VISIBLE_RANGE := 10000.0


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
				run_timer = false
			visible = true
		else:
			visible = false
			if not run_timer:
				start_timer()
			
# when the position is reset, every one needs to check visibility right away!
func _on_spacecraft_reset() -> void:
	check_visible = true		

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Signals.has_signal("Spacecraft_reset"):
		Signals.add_user_signal("Spacecraft_reset")
	Signals.connect("moon_position_changed", _on_moon_position_changed)
	Signals.connect("Spacecraft_reset", _on_spacecraft_reset)
	# compute a position relative to another terrain object
	if relative_position:
		var position_array = moon_data.get_destination_from_bearing_and_distance(
			reference_object.latitude,
			reference_object.longitude,
			departure_bearing,
			distance_from_reference
		)
		longitude = position_array[1]
		latitude = position_array[0]
	rotation = moon_data.get_object_surface_rotation(latitude, longitude, heading)
	dv_relative_position = DVector3.FromVector3(moon_data.get_vector_position(latitude, longitude))
	dv_relative_position.multiply_scalar(
		moon_data.get_terrain_altitude(latitude, longitude, 1.0) + 
		moon_data.radius
	)
	position = dv_relative_position.vector3()
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
		start_timer()
