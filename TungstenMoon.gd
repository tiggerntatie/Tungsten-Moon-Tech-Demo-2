extends MeshInstance3D

const G = 6.674E-11
const rhoW = 19250.0 # kg/m^3
const SHRINK_ALTITUDE = 10000 # meters above ground
const SHRINK_FACTOR = 4
@onready var LEVEL : Node3D = $".."
@onready var LogicalM =  rhoW*(PI*4/3)*pow(mesh.radius,3)
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
func set_from_logical_position(body: Spacecraft, eyeball_offset: Vector3 = Vector3.ZERO):
	var p = DVector3.FromVector3(body.position)
	#var offset = Vector3.ZERO
	var r = body.dv_logical_position.length()
	if  r - SHRINK_ALTITUDE > mesh.radius: # above transition region
		#offset = eyeball_offset
		if scale_factor < SHRINK_FACTOR:
			scale_factor = SHRINK_FACTOR
			var scalef = 1/scale_factor
			scale = Vector3(scalef, scalef, scalef)
	elif r - SHRINK_ALTITUDE < mesh.radius: # below transition region
		if scale_factor > 1:
			scale_factor = 1
			scale = Vector3(1, 1, 1)
	# p.sub(DVector3.Div(body.dv_logical_position, scale_factor))
	# make a copy of logical position
	var dv_unrotated_logical_position: DVector3 = body.dv_logical_position.copy()
	# de-rotate it 
	dv_unrotated_logical_position.rotate_y(-LEVEL.current_moon_rotation)
	# scale it and create a new position
	p.sub(DVector3.Div(dv_unrotated_logical_position, scale_factor))
	#print(offset, " ", scale_factor)
	position = p.vector3() + eyeball_offset
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
