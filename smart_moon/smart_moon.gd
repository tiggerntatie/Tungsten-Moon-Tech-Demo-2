@tool
extends Node3D

signal meshes_loaded(value: float)
signal all_meshes_loaded

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
		
@export var material_override : Material:
	set(val):
		material_override = val
		on_data_changed()

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		Signals.add_user_signal(
			"moon_position_changed", 
			[{"name":"dv_position", "type": TYPE_OBJECT},{"name":"scale", "type":TYPE_VECTOR3}]
			)
		Signals.add_user_signal(
			"moon_scale_changed", 
			[{"name":"scale_factor", "type":TYPE_FLOAT}]
			)

		LEVEL =  get_node("/root/Level")
	on_data_changed()


# get a list of faces (excludes non-face children!)
func get_faces():
	var faces := []
	for child in get_children():
		if is_instance_of(child, MoonSmartFace):
			faces.append(child)
	return faces
	

func on_data_changed():
	if not Engine.is_editor_hint():
		scale = Vector3.ONE*MOON_SCALE
	mesh_max_count = 0
	mesh_count = 0
	for face in get_faces():
		face.generate_meshes(moon_data, resolution_power, chunk_resolution_power)
	reset_high_precision_chunks()


const G = 6.674E-11

const rhoW = 19250.0 # kg/m^3
const SHRINK_ALTITUDE = 1500.0 
const SHRINK_ALTITUDE_DEAD_ZONE = 100.0 # hysteresis
const SHRINK_FACTOR = 10  # was 4
const MOON_SCALE = 1000	
var LEVEL : Node3D
@onready var physical_radius = $".".moon_data.radius*1000
@onready var LogicalM =  rhoW*(PI*4/3)*pow(physical_radius,3)
var scale_factor : float = 1.0
var high_precision_chunks: Dictionary = {}
var mesh_max_count : int
var mesh_count : int

# maintain a high fidelity version of moon position
@onready var dv_position : DVector3 = DVector3.FromVector3(position):
	set (val):
		dv_position = val
		Signals.emit_signal("moon_position_changed", dv_position, scale)
		update_high_precision_chunks()
		position = val.vector3()

func update_high_precision_chunks():
	for chunk : MeshChunk in high_precision_chunks.keys():
		var dv_temp := DVector3.Add(chunk.dv_face_position, chunk.dv_position)
		dv_temp.multiply_scalar(scale.x)
		dv_temp.add(dv_position)
		chunk.global_position = dv_temp.vector3()

func scale_high_precision_chunks():
	for chunk : MeshChunk in high_precision_chunks.keys():
		if chunk.is_set_as_top_level():
			chunk.scale = scale		# match to planet scale

func reset_high_precision_chunks():
	high_precision_chunks.clear()
	for face in get_faces():
		face.reset_high_precision_chunks()


func reset_scenario():
	#print("MOON.reset_scenario()")
	reset_high_precision_chunks()
	

# position assumes relative to planet center (assumed at origin), returns force vector
func get_acceleration(dv_body_position: DVector3, v_thrust_acc: Vector3 = Vector3.ZERO) -> DVector3:
	var dv_acc = dv_body_position.normalized()
	dv_acc.multiply_scalar(-G*LogicalM/pow(dv_body_position.length(),2))
	dv_acc.add(DVector3.FromVector3(v_thrust_acc))
	return dv_acc

# establish spacecraft logical position (usually called at start)
func get_logical_position(body: Spacecraft) -> DVector3:
	return DVector3.FromVector3(body.position - scale_factor*position)

# update the planet position based on spacecraft logical position
# altitude agl is determined by spacecraft
# optional xz_radius enforces an invariant radius in xz plane after de-rotating
# view_offset is vector position of eye relative to CG
func set_from_logical_position(body: Spacecraft, view_offset: Vector3, alt_agl: float, xz_radius: float = 0.0):
	var p = DVector3.FromVector3(body.position)
	#var r = body.dv_logical_position.length()
	if  alt_agl > SHRINK_ALTITUDE: # above transition region
		if scale_factor < SHRINK_FACTOR:
			scale_factor = SHRINK_FACTOR
			var scalef = MOON_SCALE/scale_factor
			scale = Vector3(scalef, scalef, scalef)
			Signals.emit_signal("moon_scale_changed", scale_factor)
	elif alt_agl < SHRINK_ALTITUDE - SHRINK_ALTITUDE_DEAD_ZONE: # below transition region
		if scale_factor > 1.0:
			scale_factor = 1.0
			scale = Vector3(MOON_SCALE, MOON_SCALE, MOON_SCALE)
			Signals.emit_signal("moon_scale_changed", scale_factor)

	
	# p.sub(DVector3.Div(body.dv_logical_position, scale_factor))
	# make a copy of logical position
	var dv_unrotated_logical_position: DVector3 = body.dv_logical_position.copy()
	# de-rotate it 
	dv_unrotated_logical_position.rotate_y(-LEVEL.current_moon_rotation, xz_radius)
	# scale it and create a new position
	p.sub(DVector3.Div(dv_unrotated_logical_position, scale_factor))
	if scale_factor != 1.0:
		p.add(DVector3.FromVector3(view_offset*((scale_factor-1.0)/scale_factor)))
	dv_position = p
	Signals.emit_signal("moon_position_changed", dv_position, scale)
	scale_high_precision_chunks()
	
# update the spacecraft logical position, based on planet position
func set_logical_position_from_physical(body: Spacecraft, xz_radius: float = 0.0):
	var dv_temp_logical_position = DVector3.FromVector3(body.position)	# spacecraft position, roughly zero
	var dv_raw_position = DVector3.FromVector3(position)
	var moon_position = DVector3.Div(dv_raw_position, scale.x/MOON_SCALE)	# Current logical moon position, correcting for eyeball offset
	dv_temp_logical_position.sub(moon_position)		# now the UNrotated logical position
	dv_temp_logical_position.rotate_y(LEVEL.current_moon_rotation, xz_radius)  # rotate the logical position according to moon rotation
	body.dv_logical_position = dv_temp_logical_position	# stuff the logical position back on the spacecraft


func _on_face_loaded(normal, total_meshes):
	mesh_max_count = total_meshes


func _on_mesh_loaded():
	mesh_count += 1
	if not Engine.is_editor_hint():
		if mesh_count == 6*mesh_max_count:
			all_meshes_loaded.emit()  # ALL done
		meshes_loaded.emit(mesh_count/(6*mesh_max_count))
