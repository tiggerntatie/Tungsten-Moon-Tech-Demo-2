extends MeshInstance3D

const G = 6.674E-11
const rhoW = 19250.0 # kg/m^3
@onready var LogicalM =  rhoW*(PI*4/3)*pow(mesh.radius,3)
var xr_interface: XRInterface

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
	# VR setup
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully")
		
		# Turn off v-sync
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
		# Change our main viewport to putput to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		get_viewport().use_xr = false
	# END VR Setup	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
