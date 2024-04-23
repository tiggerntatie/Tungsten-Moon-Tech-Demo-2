class_name Spacecraft

extends RigidBody3D

const THRUST_INC = 10.0 	# Newtons
const THRUST_MAX = 20000 	# Newtons
const THRUST_MIN = 5000 	# Newtons
const THRUST_STEP_MULTIPLIER = 0.2 # 
const FULL_FUEL = 2000 		# kg
const ISP = 300 			# s
const GEARTH = 9.80665 		# m/s^2
const MOUSE_SENS = 0.002	# m/unit and deg/unit
const SCROLL_SENS = 0.05	# m/unit
const JOY_SENS = 0.01		# m/unit
const VERT_SPRING_K = 50000 # N/m
const HORIZ_SPRING_K = 10000 # N/m
const SPRING_K : Vector3 = Vector3(50000, 50000, 50000)
const SPRING_DAMP : Vector3 = Vector3(10000, 10000, 10000)

@onready var LEVEL : Node3D = $".."
@onready var MOON : Node3D = $"../SmartMoon"
@onready var GROUNDRADAR : RayCast3D = $GroundRadar
@onready var COLLISIONSHAPE : CollisionShape3D = $CollisionShape3D
@onready var HUDHVEL : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_HSpeed/HVEL
@onready var HUDVVEL : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_VSpeed/VVEL
@onready var HUDALT : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Altitude/ALT
@onready var HUDRALT : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_RAltitude/RALT
@onready var HUDTHRUST : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Thrust/THRUST
@onready var HUDFUEL : ProgressBar = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Fuel/FUEL
@onready var HUDAALT : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_OrbitApoapsis/AALT
@onready var HUDPALT : Label = $InstrumentPanel/SubViewport/InstrumentCanvas/L_OrbitPeriapsis/PALT
@onready var HUDSTAB : ColorRect = $InstrumentPanel/SubViewport/InstrumentCanvas/L_Stabilizer/STAB
@onready var CAMERA : Camera3D = $YawPivot/PitchPivot/Camera3D
@onready var XRCAMERA : XRCamera3D = $"XROrigin3D/XRCamera3D"
@onready var XRORIGIN : XROrigin3D = $XROrigin3D
@onready var YAWPIVOT : Node3D = $YawPivot
@onready var PITCHPIVOT : Node3D = $YawPivot/PitchPivot
@onready var THROTTLE : Node3D = $Throttle
@onready var SIDESTICK : Node3D = $SideStick
@onready var ALTCTRLBUTTON : Node3D = $AltCtrlButton
@onready var STABILIZERBUTTON : Node3D = $StabilizerButton
@onready var LANDINGLIGHT : SpotLight3D = $LandingLight
@onready var dv_logical_position := DVector3.new()
@onready var dv_logical_velocity := DVector3.new(0,0,0)
@onready var dv_gravity_force := DVector3.new()
@onready var v_thrust := Vector3.ZERO
@onready var v_torque := Vector3.ZERO
@onready var fuel : float = FULL_FUEL
@onready var reset_view_yaw : Transform3D = YAWPIVOT.transform
@onready var reset_view_pitch : Transform3D = PITCHPIVOT.transform


# projected impact point in global coordinates
var v_impact_point := Vector3.INF
var v_impact_normal := Vector3.INF
# UNROTATED captured logical position
var dv_captured_logical_position : DVector3
#var v_captured_impact_point := Vector3.INF
var thrust : float = 0.0
var dv_last_position : DVector3
var last_xz_radius : float
var altitude_agl : float = NAN
var altitude_radar : float = NAN
var terrain_altitude : float = NAN
#var v_altitude_agl : Vector3 = Vector3.INF

# Sidestick State
var sidestick_x : float = 0.0
var sidestick_y : float = 0.0

# UI State 
var ui_in : bool
var ui_rotation : bool
var ui_thrust_lock : bool
var mouse_button_2 : bool
	
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
	
# Return a DVector3 representing velocity at the current logical position, assuming no relative motion
# with respect to the moon.	
# dv_pos
# hradius is logical radius parallel to xz plane
# rate is the moon rotation rate in radian/sec
func get_landed_velocity(dv_pos: DVector3, hradius: float, rate: float):
	var angle: float = atan2(dv_pos.x, dv_pos.z)
	var vel: float = hradius*rate
	return DVector3.new(vel*cos(angle), 0.0, vel*(-sin(angle)))

# reset the spacecraft internal state
func reset_spacecraft():
	dv_captured_logical_position = null
	fuel = FULL_FUEL	# FIXME this should be refilled some other way!
	thrust = 0.0
	v_thrust = Vector3.ZERO
	v_torque = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	ui_in = false
	ui_rotation = true
	ui_thrust_lock = true
	altitude_agl = NAN
	STABILIZERBUTTON.set_button(false)	# turn light off
	STABILIZERBUTTON.press_button()	# now toggle it on and handle event
	reset_viewpoint()

# reset the pilot viewpoint
func reset_viewpoint():
	if XRCAMERA.current:
		# this is a little bit of VR magic .. the spacecraft alignment is not the default for Godot!
		XRORIGIN.position = Vector3(1.0, 5.7, -0.53) - Vector3(-XRCAMERA.position.z, XRCAMERA.position.y, XRCAMERA.position.x)
		XRORIGIN.rotation = Vector3(0.0, -PI/2.0, 0.0) - Vector3(0.0, XRCAMERA.rotation.y, 0.0)
	else:
		YAWPIVOT.transform = reset_view_yaw
		PITCHPIVOT.transform = reset_view_pitch
		XRORIGIN.visible = false

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
	reset_spacecraft()
	MOON.set_from_logical_position(self)

# get the current computed height above "msl"
func get_altitude_msl() -> float:
	return dv_logical_position.length()-MOON.physical_radius

# Called when the node enters the scene tree for the first time.
func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dv_logical_position =  MOON.get_logical_position(self)
	dv_gravity_force = DVector3.Mul(mass, MOON.get_acceleration(dv_logical_position))
	dv_last_position = dv_logical_position.copy()
	contact_monitor = true
	max_contacts_reported = 1
	reset_spacecraft()


# Called physics every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var delta_fuel = 0.0
	v_torque = Vector3.ZERO		# all torques to zero - we will add them as we discover them

	# Fuel calculations
	if fuel <= 0.0:
		thrust = 0.0
		v_thrust.y = 0.0
		fuel = 0.0
	else:
		delta_fuel = delta * v_thrust.y / (GEARTH * ISP)
		fuel -= delta_fuel

	# Rotate thrust vector to match spacecraft axis, and again to account for axis system rotation
	var v_thrust_global : Vector3 = (basis * v_thrust).rotated(Vector3.UP, LEVEL.current_moon_rotation)
	var net_mass = mass - FULL_FUEL + fuel

	# Camera dependent calculations
	var view_distance = sqrt(pow(dv_logical_position.length(),2) + pow(MOON.physical_radius,2)) / MOON.scale_factor
	if CAMERA.current:
		CAMERA.far = view_distance
	else:
		XRCAMERA.far = view_distance
		
	
	var altitude_msl = get_altitude_msl()
	GROUNDRADAR.target_position = to_local(MOON.position).normalized()*1000/MOON.scale_factor
	if GROUNDRADAR.is_colliding():
		v_impact_point = GROUNDRADAR.get_collision_point()
		v_impact_normal = GROUNDRADAR.get_collision_normal()
		altitude_radar = GROUNDRADAR.to_local(v_impact_point).length()-GROUNDRADAR.position.y
		terrain_altitude = get_altitude_msl() - altitude_radar
	else:
		altitude_radar = NAN

	if not is_nan(altitude_radar):
		altitude_agl = altitude_msl - terrain_altitude
	else:
		altitude_agl = NAN
	
	# compute an impact restoring force
	if altitude_agl < -2.0:
		# too much. reload the scenario!
		LEVEL.scenario_input(false, false, true)
	elif altitude_agl <= 0.0:
		STABILIZERBUTTON.set_button(true)
		if dv_captured_logical_position == null:
			dv_captured_logical_position = dv_logical_position.copy()
			dv_captured_logical_position.rotate_y(-LEVEL.current_moon_rotation) # UNrotate
		var dv_captured = dv_captured_logical_position.copy()
		dv_captured.rotate_y(LEVEL.current_moon_rotation)
		# we haven't done a physics cycle yet, but we need to estimate a restoring force based on 
		# the current velocity to get a projected current position. This doesn't matter if the delta
		# is small, but when it glitches and becomes large, it is essential!
		var dv_estimated_logical_position : DVector3 = DVector3.Add(dv_logical_position, DVector3.Mul(delta, dv_logical_velocity))
		var dv_position_delta = DVector3.Sub(dv_estimated_logical_position, dv_captured)
		# too much spring deflection.. reload scenario
		if dv_position_delta.length() > 1.0:
			LEVEL.scenario_input(false, false, true)
		else:
			var dv_restoring_force = DVector3.Mul(-SPRING_K.y, dv_position_delta)
			var dv_local_velocity = DVector3.Sub(dv_logical_velocity, get_landed_velocity(dv_logical_position, dv_logical_position.xz_length(), LEVEL.moon_axis_rate))
			# damping force (kills oscillations)
			dv_restoring_force.add(DVector3.Mul(-SPRING_DAMP.y, dv_local_velocity))
			# rotate to match surface 
			var v_crossed = (basis*Vector3.UP).cross(v_impact_normal)
			# this torque is computed in global space:
			apply_torque(v_crossed * delta * 100000)

			#print("restoring force: ", v_restoring_force)
			v_thrust_global += dv_restoring_force.vector3()
	else: # agl is undefined or above zero
		dv_captured_logical_position = null


	
	process_physics(delta, dv_logical_position, dv_logical_velocity, v_thrust_global, net_mass)
	MOON.set_from_logical_position(self)
		
	# Input Polling
	# view reset
	if Input.is_action_just_pressed("Reset Viewpoint"):
		reset_viewpoint()
	# scenario selection and/or restart
	var p = Input.is_action_just_pressed("Load Prev Scenario")
	var n = Input.is_action_just_pressed("Load Next Scenario")
	var r = Input.is_action_just_pressed("Restart")
	# ignore other inputs if we are chhanging scenarios
	if not LEVEL.scenario_input(p, n, r):
		if Input.is_action_pressed("Thrust Increase"):
			increase_thrust(delta)
		elif Input.is_action_pressed("Thrust Decrease"):
			decrease_thrust(delta)
		elif Input.is_action_pressed("Thrust Max"):
			set_thrust(1.0)
		elif Input.is_action_pressed("Thrust Cut"):
			set_thrust(0.0)
		if not ui_thrust_lock:
			set_thrust(Input.get_action_strength("Thrust Analog"), false)
		if ui_in:
			v_torque = Vector3.ZERO
			var horiz_vel = JOY_SENS * Input.get_axis("Viewpoint Left", "Viewpoint Right")
			var forward_vel : float = 0.0
			var upward_vel : float = 0.0
			if ALTCTRLBUTTON.get_button():
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
		else:
			if ALTCTRLBUTTON.get_button():
				SIDESTICK.set_sidestick(-Input.get_axis("Yaw Right", "Yaw Left"), Input.get_axis("Pitch Forward", "Pitch Backward"))
			else:
				SIDESTICK.set_sidestick(-Input.get_axis("Roll Right", "Roll Left"), Input.get_axis("Pitch Forward", "Pitch Backward"))
			# oddly, this has to be here to keep the ship rotating		
		v_torque.y += Input.get_axis("Yaw Right Always", "Yaw Left Always")
		v_torque.z += sidestick_y
		if ALTCTRLBUTTON.get_button():
			v_torque.y -= sidestick_x
		else:
			v_torque.x += sidestick_x
		apply_torque(basis * v_torque * delta * 10000)
	
	# Orbit State Calculation
	var GM = MOON.LogicalM*MOON.G
	var P0 = dv_logical_position.vector3().cross(dv_logical_velocity.vector3()).length()
	var r0 = dv_logical_position.vector3().length()
	var v0 = dv_logical_velocity.vector3().length()
	var discriminant = GM*GM/P0/P0 - 2.0*GM/r0 + v0*v0
	var PA = 0.0
	var AA = 0.0
	if discriminant >= 0.0:
		PA = P0/(GM/P0 + sqrt(discriminant)) - MOON.physical_radius
		AA = P0/(GM/P0 - sqrt(discriminant)) - MOON.physical_radius
				
	# HUD Updates
	var v_ground_logical_velocity = get_landed_velocity(dv_logical_position, dv_logical_position.xz_length(), LEVEL.moon_axis_rate).vector3()
	var hvel = dv_logical_position.vector3().normalized().cross(dv_logical_velocity.vector3()-v_ground_logical_velocity).length()
	var vvel = dv_logical_position.vector3().normalized().dot(dv_logical_velocity.vector3())
	HUDHVEL.text = str(hvel).pad_decimals(1) + " m/s"
	HUDVVEL.text = str(vvel).pad_decimals(1) + " m/s"
	HUDALT.text = str(altitude_msl/1000.0).pad_decimals(2) + " km"
	if is_nan(altitude_agl):
		HUDRALT.text = "no signal"
	else:
		HUDRALT.text = str(altitude_agl).pad_decimals(1) + " m"
	HUDTHRUST.text = str(v_thrust.y).pad_decimals(0) + " N"
	HUDFUEL.value = 100.0*fuel/FULL_FUEL
	if AA > 0.0:
		HUDAALT.text = str(AA/1000.0).pad_decimals(2) + " km"
	else:
		HUDAALT.text = "---"
	if PA > 0.0:
		HUDPALT.text = str(PA/1000.0).pad_decimals(2) + " km"
	else:
		HUDPALT.text = "---"
		
	
func increase_thrust(step : float):
	ui_thrust_lock = true
	thrust = clamp(thrust+step*THRUST_STEP_MULTIPLIER, 0.0, 1.0)
	THROTTLE.set_throttle_slider(thrust)
 
func decrease_thrust(step : float):
	ui_thrust_lock = true
	thrust = clamp(thrust-step*THRUST_STEP_MULTIPLIER, 0.0, 1.0)
	THROTTLE.set_throttle_slider(thrust)

func set_thrust(value : float, lock : bool = true):
	ui_thrust_lock = lock
	thrust = value
	THROTTLE.set_throttle_slider(thrust)

func _on_throttle_output_changed(value):
	if value == 0.0:
		v_thrust.y = 0.0
	else:
		v_thrust.y = THRUST_MIN + (THRUST_MAX - THRUST_MIN)*value

func _on_sidestick_output_changed(x, y):
	sidestick_x = x
	sidestick_y = y

## Manage the "Stabilizer" button state
func _on_stabilizer_pressed(state):
	if state:
		angular_damp = 1
	else:
		angular_damp = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Toggle In Out"):
		ui_in = not ui_in
	elif event.is_action_pressed("Toggle Rotation"):
		ui_rotation = not ui_rotation
	elif event.is_action_pressed("Toggle Thrust Lock"):
		ui_thrust_lock = not ui_thrust_lock
	elif event.is_action_pressed("Alternate Control"):
		ALTCTRLBUTTON.press_button()
	elif event.is_action_pressed("Rotation Damp Toggle"):
		STABILIZERBUTTON.press_button()
	elif (event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_RIGHT):
		mouse_button_2 = event.is_pressed()
	elif event is InputEventMouseMotion and mouse_button_2:
		$YawPivot.rotation.y -= MOUSE_SENS * event.relative.x
		$YawPivot/PitchPivot.rotation.z -= MOUSE_SENS * event.relative.y
		$YawPivot/PitchPivot.rotation.z = clamp($YawPivot/PitchPivot.rotation.z, -PI/2, PI/2)
	elif event.is_action_pressed("Quit"):
		get_tree().quit()


