extends MeshInstance3D

const G = 6.674E-11
const rhoW = 19250.0 # kg/m^3
@onready var LogicalM =  rhoW*(PI*4/3)*pow(mesh.radius,3)

# position assumes relative to planet center, returns force vector
func get_acceleration(dv_position: DVector3, v_thrust_acc: Vector3 = Vector3.ZERO) -> DVector3:
	var dv_acc = dv_position.normalized()
	dv_acc.multiply_scalar(-G*LogicalM/pow(dv_position.length(),2))
	dv_acc.add(DVector3.FromVector3(v_thrust_acc))
	return dv_acc

# establish spacecraft logical position (usually called at start)
func get_logical_position(body: Spacecraft) -> DVector3:
	return DVector3.FromVector3(body.position - position)

# update the planet position based on spacecraft logical position
func set_from_logical_position(body: Spacecraft):
	var p = DVector3.FromVector3(body.position)
	p.sub(body.dv_logical_position)
	position = p.vector3()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
