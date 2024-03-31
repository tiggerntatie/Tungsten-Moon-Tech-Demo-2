@tool
extends Node3D

@export var moon_data : MoonData:
	set(val):
		moon_data = val
		on_data_changed()
		if moon_data != null and not moon_data.is_connected("changed", self.on_data_changed):
			moon_data.connect("changed", self.on_data_changed)

@export_range(2, 8, 1) var resolution_power := 3:
	set(val):
		resolution_power = val
		on_data_changed()
		
@export_range(2, 8, 1) var chunk_resolution_power := 5:
	set(val):
		chunk_resolution_power = val
		on_data_changed()

# Called when the node enters the scene tree for the first time.
func _ready():
	scale = Vector3.ONE*MOON_SCALE
	on_data_changed()
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func on_data_changed():
	for face in get_children():
		face.generate_meshes(moon_data, resolution_power, chunk_resolution_power)


const G = 6.674E-11
const rhoW = 19250.0 # kg/m^3
const SHRINK_ALTITUDE = 10000 # meters above ground
const SHRINK_FACTOR = 4
const MOON_SCALE = 1000	
@onready var LEVEL : Node3D = get_node("/root/Level")
@onready var physical_radius = $".".moon_data.radius*1000
@onready var LogicalM =  rhoW*(PI*4/3)*pow(physical_radius,3)
var scale_factor : float = 1.0

# position assumes relative to planet center, returns force vector
func get_acceleration(dv_position: DVector3, v_thrust_acc: Vector3 = Vector3.ZERO) -> DVector3:
	var dv_acc = dv_position.normalized()
	dv_acc.multiply_scalar(-G*LogicalM/pow(dv_position.length(),2))
	dv_acc.add(DVector3.FromVector3(v_thrust_acc))
	return dv_acc

# establish spacecraft logical position (usually called at start)
func get_logical_position(body: Spacecraft) -> DVector3:
	return DVector3.FromVector3(body.position - scale_factor*position)

# update the planet position based on spacecraft logical position
# optional xz_radius enforces an invariant radius in xz plane after de-rotating
func set_from_logical_position(body: Spacecraft, eyeball_offset: Vector3 = Vector3.ZERO, xz_radius: float = 0.0):
	var p = DVector3.FromVector3(body.position)
	#var offset = Vector3.ZERO
	var r = body.dv_logical_position.length()
	if  r - SHRINK_ALTITUDE > physical_radius: # above transition region
		#offset = eyeball_offset
		if scale_factor < SHRINK_FACTOR:
			scale_factor = SHRINK_FACTOR
			var scalef = MOON_SCALE/scale_factor
			scale = Vector3(scalef, scalef, scalef)
	elif r - SHRINK_ALTITUDE <= physical_radius: # below transition region
		if scale_factor > 1:
			scale_factor = 1
			scale = Vector3(MOON_SCALE, MOON_SCALE, MOON_SCALE)
	# p.sub(DVector3.Div(body.dv_logical_position, scale_factor))
	# make a copy of logical position
	var dv_unrotated_logical_position: DVector3 = body.dv_logical_position.copy()
	# de-rotate it 
	dv_unrotated_logical_position.rotate_y(-LEVEL.current_moon_rotation, xz_radius)
	# scale it and create a new position
	p.sub(DVector3.Div(dv_unrotated_logical_position, scale_factor))
	position = p.vector3() + eyeball_offset
	
# update the spacecraft logical position, based on planet position
# FIXME review eyeball_offset calculation before implementing. Should work at low altitude.. 
func set_logical_position_from_physical(body: Spacecraft, eyeball_offset: Vector3 = Vector3.ZERO, xz_radius: float = 0.0):
	var dv_temp_logical_position = DVector3.FromVector3(body.position)	# spacecraft position, roughly zero
	var dv_raw_position = DVector3.FromVector3(position)
	var moon_position = DVector3.Sub(DVector3.Div(dv_raw_position, scale.x/MOON_SCALE), DVector3.FromVector3(eyeball_offset))	# Current logical moon position, correcting for eyeball offset
	dv_temp_logical_position.sub(moon_position)		# now the UNrotated logical position
	dv_temp_logical_position.rotate_y(LEVEL.current_moon_rotation, xz_radius)  # rotate the logical position according to moon rotation
	body.dv_logical_position = dv_temp_logical_position	# stuff the logical position back on the spacecraft
	
