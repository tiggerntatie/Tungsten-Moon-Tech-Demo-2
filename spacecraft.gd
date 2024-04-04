class_name Spacecraft

extends RigidBody3D

const THRUST_INC = 10.0 	# Newtons
const THRUST_MAX = 20000 	# Newtons
const THRUST_MIN = 5000 	# Newtons
const FULL_FUEL = 2000 		# kg
const ISP = 300 			# s
const GEARTH = 9.80665 		# m/s^2
const MOUSE_SENS = 0.002	# m/unit and deg/unit
const SCROLL_SENS = 0.05	# m/unit
const JOY_SENS = 0.01		# m/unit

@onready var LEVEL : Node3D = $".."
@onready var MOON : Node3D = $"../SmartMoon"
@onready var GROUNDRADAR : RayCast3D = $GroundRadar
@onready var COLLISIONSHAPE : CollisionShape3D = $CollisionShape3D
@onready var HUDVEL : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Velocity/VEL
@onready var HUDALT : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Altitude/ALT
@onready var HUDTHRUST : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Thrust/THRUST
@onready var HUDFUEL : ProgressBar = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Fuel/FUEL
@onready var CAMERA : Camera3D = $YawPivot/PitchPivot/Camera3D
@onready var XRCAMERA : XRCamera3D = $"YawPivot/PitchPivot/XROrigin3D/XRCamera3D"
@onready var dv_logical_position := DVector3.new()
@onready var dv_logical_velocity := DVector3.new(0,0,0)
@onready var dv_gravity_force := DVector3.new()
@onready var v_thrust := Vector3.ZERO
@onready var v_torque := Vector3.ZERO
@onready var fuel : float = FULL_FUEL

var landed := false
var flying := true

var dv_last_position : DVector3
var last_xz_radius : float
var altitude_agl : float

# UI State 
var ui_in : bool = false
var ui_rotation : bool = true
var ui_thrust_lock : bool = true
var ui_alternate_control : bool = false
	
# Calculate new position and velocity for each step
# 4th order runge kutte integration
func process_physics(delta, dv_position, dv_velocity, v_th, mass_param):
	var d2 = delta/2
	var d6 = delta/6
	var v_thrust_acc = v_th/mass_param
	var k1v = MOON.get_acceleration(dv_position, v_thrust_acc)
	var k1r = dv_velocity
	var k2v = MOON.get_acceleration(DVector3.Add(dv_position, DVector3.Mul(d2, k1r)), v_thrust_acc)
	var k2r = DVector3.Add(dv_velocity, DVector3.Mul(d2, k1v))
	var k3v = MOON.get_acceleration(DVector3.Add(dv_position, DVector3.Mul(d2, k2r)), v_thrust_acc)
	var k3r = DVector3.Add(dv_velocity, DVector3.Mul(d2, k2v))
	var k4v = MOON.get_acceleration(DVector3.Add(dv_position, DVector3.Mul(delta, k3r)), v_thrust_acc)
	var k4r = DVector3.Add(dv_velocity, DVector3.Mul(delta, k3v))
	dv_logical_velocity = DVector3.Add(dv_velocity,
		DVector3.Mul(d6, DVector3.QAdd(k1v, DVector3.Mul(2, k2v), DVector3.Mul(2, k3v), k4v)))
	dv_logical_position = DVector3.Add(dv_position,
		DVector3.Mul(d6, DVector3.QAdd(k1r, DVector3.Mul(2, k2r), DVector3.Mul(2, k3r), k4r)))

# Calculate new position and velocity for each step
# Assuming the spacecraft is stationary, relative to moon surface
# xz_radius is used to guarantee radius in xz plane is invariant with each iteration
func process_stationary_physics(delta: float, dv_pos: DVector3, xz_radius: float):
	dv_pos.rotate_y(LEVEL.moon_axis_rate * delta, xz_radius)
	dv_logical_velocity = get_landed_velocity(dv_pos, xz_radius, LEVEL.moon_axis_rate)
	
# Return a DVector3 representing velocity at the current logical position, assuming no relative motion
# with respect to the moon.	
# dv_pos
# hradius is logical radius parallel to xz plane
# rate is the moon rotation rate in radian/sec
func get_landed_velocity(dv_pos: DVector3, hradius: float, rate: float):
	var angle: float = atan2(dv_pos.x, dv_pos.z)
	var vel: float = hradius*rate
	return DVector3.new(vel*cos(angle), 0.0, vel*(-sin(angle)))

# Set spacecraft logical position to lat/long and heading (cw from N) (all in degrees)
# Also sets rotation to be level with local ground, pointing at heading
# Also sets linear velocity to match moon rotation at the given altitude
func set_logical_position(lat: float, lon: float, radius: float, altitude: float, heading: float, moon_rate: float):
	# NOTE: Longitude zero is in the direction of +Z per Godot convention
	# NOTE: Spacecraft rotation depends on spacecraft orientation facing +X
	var phi: float = deg_to_rad(lon) + LEVEL.current_moon_rotation
	var theta: float = deg_to_rad(lat)
	var gamma: float = deg_to_rad(-heading)
	dv_logical_position.x = (radius + altitude) * cos(theta)*sin(phi)
	dv_logical_position.y = (radius + altitude) * sin(theta)
	dv_logical_position.z = (radius + altitude) * cos(theta)*cos(phi)
	dv_logical_velocity = get_landed_velocity(dv_logical_position, dv_logical_position.xz_length(), moon_rate)
	var q1 : Quaternion = Quaternion.from_euler(Vector3(0.0, phi+PI/2.0, PI/2.0-theta))
	var q2 : Quaternion = Quaternion.from_euler(Vector3(0.0, gamma, 0.0))
	rotation = (q1*q2).get_euler()	# This rotates the ship to correspond to its unrotated position on the globe
	flying = true
	landed = false
	fuel = FULL_FUEL	# FIXME this should be refilled some other way!
	MOON.set_from_logical_position(self)



# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dv_logical_position =  MOON.get_logical_position(self)
	dv_gravity_force = DVector3.Mul(mass, MOON.get_acceleration(dv_logical_position))
	dv_last_position = dv_logical_position.copy()
	contact_monitor = true
	max_contacts_reported = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var delta_fuel = 0.0
	
	# Fuel calculations
	if fuel <= 0.0:
		v_thrust.y = 0.0
		fuel = 0.0
	else:
		delta_fuel = delta * v_thrust.y / (GEARTH * ISP)
		fuel -= delta_fuel

	# Rotate thrust vector to match spacecraft axis, and again to account for axis system rotation
	var v_thrust_global = (basis * v_thrust).rotated(Vector3.UP, LEVEL.current_moon_rotation)
	var net_mass = mass - FULL_FUEL + fuel

	# Camera dependent calculations
	var view_distance = sqrt(pow(dv_logical_position.length(),2) + pow(MOON.physical_radius,2)) / MOON.scale_factor
	var eyeball_offset : Vector3
	if CAMERA.current:
		CAMERA.far = view_distance
		eyeball_offset = CAMERA.global_position
	else:
		XRCAMERA.far = view_distance
		eyeball_offset = XRCAMERA.global_position
		
	
	GROUNDRADAR.target_position = to_local(MOON.position).normalized()*1000/MOON.scale_factor
	if GROUNDRADAR.is_colliding():
		altitude_agl = GROUNDRADAR.to_local(GROUNDRADAR.get_collision_point()).length()-GROUNDRADAR.position.y
		#print("altitude_agl: ", altitude_agl)
	else:
		altitude_agl = NAN
		#print("no radar contact")


	# transition to landed?
	if flying and altitude_agl < 0.0:
		#dv_logical_position = dv_last_position
		last_xz_radius = dv_logical_position.xz_length()
		v_thrust.y = 0.0
		landed = true
		flying = false
		# rotate to match surface 
		var v_crossed = (basis*Vector3.UP).cross(GROUNDRADAR.get_collision_normal())
		rotate(v_crossed.normalized(), asin(v_crossed.length()))
		angular_velocity = Vector3.ZERO
			
	if not flying and not landed and altitude_agl > 0.1:
		flying = true
		landed = false
	
	if landed:
		dv_gravity_force = DVector3.Mul(net_mass, MOON.get_acceleration(dv_logical_position))
		if v_thrust_global.length_squared() > 1.1 * dv_gravity_force.length_squared():
			# transition back to flying. Tentatively.
			MOON.set_logical_position_from_physical(self, eyeball_offset)
			dv_logical_velocity = get_landed_velocity(dv_logical_position, last_xz_radius, LEVEL.moon_axis_rate)
			landed = false
	else: 
		process_physics(delta, dv_logical_position, dv_logical_velocity, v_thrust_global, net_mass)
		MOON.set_from_logical_position(self, eyeball_offset)
		
	# Input Polling
	var p = Input.is_action_just_pressed("Load Prev Scenario")
	var n = Input.is_action_just_pressed("Load Next Scenario")
	var r = Input.is_action_just_pressed("Restart")
	# ignore other inputs if we are chhanging scenarios
	if not LEVEL.scenario_input(p, n, r):
		if Input.is_action_pressed("Thrust Increase"):
			IncreaseThrust()
		if Input.is_action_pressed("Thrust Decrease"):
			DecreaseThrust()
		if not ui_thrust_lock:
			var thrust_input = Input.get_action_strength("Thrust Analog")
			if thrust_input == 0.0:
				v_thrust.y = 0.0
			else:
				v_thrust.y = THRUST_MIN * (1 - thrust_input) + THRUST_MAX * thrust_input	
		if ui_in:
			var horiz_vel = JOY_SENS * Input.get_axis("Viewpoint Left", "Viewpoint Right")
			var forward_vel : float = 0.0
			var upward_vel : float = 0.0
			if ui_alternate_control:
				upward_vel = JOY_SENS * Input.get_axis("Viewpoint Down", "Viewpoint Up")
			else:
				forward_vel = JOY_SENS * Input.get_axis("Viewpoint Backward", "Viewpoint Forward")
			$YawPivot.rotation.y -= JOY_SENS * Input.get_axis("Viewpoint Pan Left", "Viewpoint Pan Right")
			$YawPivot/PitchPivot.rotation.z += JOY_SENS * Input.get_axis("Viewpoint Pan Down", "Viewpoint Pan Up")
			$YawPivot/PitchPivot.rotation.z = clamp($YawPivot/PitchPivot.rotation.z, -PI/2, PI/2)
			var v_move = Quaternion.from_euler(
				Vector3(0.0, $YawPivot.rotation.y, $YawPivot/PitchPivot.rotation.z))*Vector3(forward_vel, upward_vel, horiz_vel)
			var new_eye = $YawPivot.position + v_move
			if (new_eye.x < 1.05 and 
				new_eye.x > 0.0 and
				new_eye.y > 4.5 and
				new_eye.y < 6.05 and 
				new_eye.z > -0.75 and new_eye.z < 0.75 and 
				new_eye.y < (-5.0/6.0)*new_eye.x + 6.675):
				$YawPivot.position = new_eye
			
		elif not landed:   # no rotation while landed, please!
			v_torque.z = Input.get_axis("Pitch Forward", "Pitch Backward")
			v_torque.y = Input.get_axis("Yaw Right Always", "Yaw Left Always")
			if ui_alternate_control:
				v_torque.y = Input.get_axis("Yaw Right", "Yaw Left")
			else:
				v_torque.x = -Input.get_axis("Roll Right", "Roll Left")
			# oddly, this has to be here to keep the ship rotating		
			apply_torque(basis * v_torque * 200)
	
				
	# HUD Updates
	var hvel = dv_logical_position.vector3().normalized().cross(dv_logical_velocity.vector3()).length()
	HUDVEL.text = str(hvel).pad_decimals(1) + " m/s"
	if is_nan(altitude_agl):
		HUDALT.text = str((dv_logical_position.length()-MOON.physical_radius)/1000.0).pad_decimals(2) + " km"
	else:
		HUDALT.text = str(altitude_agl).pad_decimals(1) + " m"
	HUDTHRUST.text = str(v_thrust.y).pad_decimals(0) + " N"
	HUDFUEL.value = 100.0*fuel/FULL_FUEL
	
func IncreaseThrust():
	ui_thrust_lock = true
	if v_thrust.y == 0.0:
		v_thrust.y = THRUST_MIN
	else:
		v_thrust.y += THRUST_INC
		if v_thrust.y > THRUST_MAX:
			v_thrust.y = THRUST_MAX

func DecreaseThrust():
	ui_thrust_lock = true
	v_thrust.y -= THRUST_INC
	if v_thrust.y < THRUST_MIN:
		v_thrust.y = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Toggle In Out"):
		ui_in = not ui_in
	elif event.is_action_pressed("Toggle Rotation"):
		ui_rotation = not ui_rotation
	elif event.is_action_pressed("Toggle Thrust Lock"):
		ui_thrust_lock = not ui_thrust_lock
	elif event.is_action_pressed("Alternate Control"):
		ui_alternate_control = true
	elif event.is_action_released("Alternate Control"):
		ui_alternate_control = false
	elif event.is_action_pressed("Thrust Increase"):
		IncreaseThrust()
	elif event.is_action_pressed("Thrust Decrease"):
		DecreaseThrust()
	elif event.is_action_pressed("Thrust Max"):
		ui_thrust_lock = true
		v_thrust.y = THRUST_MAX
	elif event.is_action_pressed("Thrust Cut"):
		ui_thrust_lock = true
		v_thrust.y = 0.0
	elif event.is_action_pressed("Kill Rotation"):
		angular_velocity = Vector3.ZERO
	elif event is InputEventMouseMotion:
		$YawPivot.rotation.y -= MOUSE_SENS * event.relative.x
		$YawPivot/PitchPivot.rotation.z -= MOUSE_SENS * event.relative.y
		$YawPivot/PitchPivot.rotation.z = clamp($YawPivot/PitchPivot.rotation.z, -PI/2, PI/2)
	elif event.is_action_pressed("Quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	

		
