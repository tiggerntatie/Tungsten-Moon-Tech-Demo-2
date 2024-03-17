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

@onready var LEVEL : Node3D = $".."
@onready var MOON : Node3D = $"../TungstenMoon"
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

var v_last_rotation : Vector3
var dv_last_position : DVector3
var last_xz_radius : float
var altitude_agl : float
	
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
	var phi: float = deg_to_rad(lon)
	var theta: float = deg_to_rad(lat)
	var gamma: float = deg_to_rad(-heading)
	dv_logical_position.x = (radius + altitude) * cos(theta)*sin(phi)
	dv_logical_position.y = (radius + altitude) * sin(theta)
	dv_logical_position.z = (radius + altitude) * cos(theta)*cos(phi)
	dv_logical_velocity = get_landed_velocity(dv_logical_position, dv_logical_position.xz_length(), moon_rate)
	var q1 : Quaternion = Quaternion.from_euler(Vector3(0.0, phi+PI/2.0, PI/2.0-theta))
	var q2 : Quaternion = Quaternion.from_euler(Vector3(0.0, gamma, 0.0))
	rotation = (q1*q2).get_euler()
	angular_velocity = Vector3(0.0, moon_rate, 0.0)
	MOON.set_from_logical_position(self)


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dv_logical_position =  MOON.get_logical_position(self)
	dv_gravity_force = DVector3.Mul(mass, MOON.get_acceleration(dv_logical_position))
	dv_last_position = dv_logical_position.copy()
	v_last_rotation = rotation
	contact_monitor = true
	max_contacts_reported = 1

func _printstatus():
	print("fl: ", flying, " lnd: ", landed)

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

	var v_thrust_global = basis * v_thrust
	var net_mass = mass - FULL_FUEL + fuel

	# Camera dependent calculations
	var view_distance = sqrt(pow(dv_logical_position.length(),2) + pow(MOON.mesh.radius,2)) / $"../TungstenMoon".scale_factor
	var eyeball_offset : Vector3
	if CAMERA.current:
		CAMERA.far = view_distance
		eyeball_offset = CAMERA.global_position
	else:
		XRCAMERA.far = view_distance
		eyeball_offset = XRCAMERA.global_position
		
	
	GROUNDRADAR.target_position = to_local(MOON.position)
	if GROUNDRADAR.is_colliding():
		altitude_agl = GROUNDRADAR.get_collision_point().length()

	#print(MOON.position)
	#dv_logical_position.print()

	# transition to landed?
	if flying:
		if altitude_agl < 10.0:
			#dv_logical_position = dv_last_position
			#rotation = v_last_rotation
			last_xz_radius = dv_logical_position.xz_length()
			angular_velocity = Vector3(0.0, LEVEL.moon_axis_rate, 0.0)
			v_thrust.y = 0.0
			landed = true
			flying = false
			_printstatus()
	if altitude_agl > 15.0:
		if not flying:
			flying = true
			landed = false
			_printstatus()

	if landed:
		dv_gravity_force = DVector3.Mul(net_mass, MOON.get_acceleration(dv_logical_position))
		if v_thrust_global.length_squared() > 1.1 * dv_gravity_force.length_squared():
			landed = false
			_printstatus()
		else:
			process_stationary_physics(delta, dv_logical_position, last_xz_radius)
			MOON.set_from_logical_position(self, eyeball_offset, last_xz_radius)

	#if flying:
	#	dv_last_position = dv_logical_position.copy()
	#	v_last_rotation = rotation
			
	if not landed:
		process_physics(delta, dv_logical_position, dv_logical_velocity, v_thrust_global, net_mass)
		MOON.set_from_logical_position(self, eyeball_offset)
		
	# Inputs
	if Input.is_action_pressed("Thrust Increase"):
		IncreaseThrust()
	if Input.is_action_pressed("Thrust Decrease"):
		DecreaseThrust()
	v_torque.z = Input.get_axis("Pitch Forward", "Pitch Backward")
	v_torque.y = Input.get_axis("Yaw Right", "Yaw Left")
	v_torque.x = -Input.get_axis("Roll Right", "Roll Left")
	apply_torque(basis * v_torque * 200)
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
				
	# HUD Updates
	HUDVEL.text = str(dv_logical_velocity.length()).pad_decimals(1) + " m/s"
	HUDALT.text = str(altitude_agl).pad_decimals(1) + " m"
	HUDTHRUST.text = str(v_thrust.y).pad_decimals(0) + " N"
	HUDFUEL.value = 100.0*fuel/FULL_FUEL
	
func IncreaseThrust():
		if v_thrust.y == 0.0:
			v_thrust.y = THRUST_MIN
		else:
			v_thrust.y += THRUST_INC
			if v_thrust.y > THRUST_MAX:
				v_thrust.y = THRUST_MAX

func DecreaseThrust():
	v_thrust.y -= THRUST_INC
	if v_thrust.y < THRUST_MIN:
		v_thrust.y = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Thrust Max"):
		v_thrust.y = THRUST_MAX
	elif event.is_action_pressed("Thrust Cut"):
		v_thrust.y = 0.0
	elif event.is_action_pressed("Kill Rotation"):
		angular_velocity = Vector3.ZERO
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("Mouse Modifier"):
			$YawPivot.position.z += MOUSE_SENS * event.relative.x
			$YawPivot.position.x -= MOUSE_SENS * event.relative.y
		else:
			$YawPivot.rotation.y -= MOUSE_SENS * event.relative.x
			$YawPivot/PitchPivot.rotation.z -= MOUSE_SENS * event.relative.y
	elif event is InputEventMouseButton:
		var dir = 0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			dir = SCROLL_SENS
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dir = -SCROLL_SENS
		$YawPivot.position.z -= dir * sin($YawPivot.rotation.y) * cos($YawPivot/PitchPivot.rotation.z)
		$YawPivot.position.x += dir * cos($YawPivot.rotation.y) * cos($YawPivot/PitchPivot.rotation.z)
		$YawPivot.position.y += dir * sin($YawPivot/PitchPivot.rotation.z)
		
	elif event.is_action_pressed("Restart"):
		get_tree().reload_current_scene()
