class_name Spacecraft

extends RigidBody3D

signal thrust_changed(float)
signal torque_changed(newtorque: Vector3, oldtorque: Vector3, threshold: float) # new torque, old torque, threshold value
signal landed

const THRUST_INC = 10.0 	# Newtons
const THRUST_MAX = 20000 	# Newtons
const THRUST_MIN = THRUST_MAX*0.1 	# Newtons
const THRUST_STEP_MULTIPLIER = 0.4 # 
const FULL_FUEL = 2500 		# kg
const ISP = 300 			# s
const GEARTH = 9.80665 		# m/s^2
const MOUSE_SENS = 0.002	# m/unit and deg/unit
const SCROLL_SENS = 0.05	# m/unit
const JOY_SENS = 0.01		# m/unit
const VERT_SPRING_K = 50000 # N/m
const HORIZ_SPRING_K = 10000 # N/m
const SPRING_K : Vector3 = Vector3(50000, 50000, 50000)
const SPRING_DAMP : Vector3 = Vector3(10000, 10000, 10000)
const STABILITY_COEFFICIENT := 20.0	# for stability feedback loop
const STABILITY_MINIMUM_RATE := 0.00001
const RATE_FROM_TORQUE := 0.1	# how a torque command translates to rad/sec in rate mode
const TORQUE_THRESHOLD := 0.01	# torque below which we can turn off the sound
const VERTICAL_VELOCITY_TC := 0.3 # seconds timme constant for filtering
const ROLL_INPUT_TC := 0.25 # seconds time constant for joystick x-axis
const PITCH_INPUT_TC := 0.25 # y-axis
const STICK_NULL := 0.1	# sidestick null zone

@onready var LEVEL : Node3D = $".."
@onready var MOON : Node3D = $"../SmartMoon"
@onready var GROUNDRADAR : RayCast3D = $ShipV2/GroundRadar
@onready var COLLISIONSHAPE : CollisionShape3D = $CollisionShape3D
@onready var CAMERA : Camera3D = $ShipV2/YawPivot/PitchPivot/Camera3D
@onready var XRREFERENCE : Marker3D = $ShipV2/XRReferencePosition
@onready var XRCAMERA : XRCamera3D = $ShipV2/XROrigin3D/XRCamera3D
@onready var XRORIGIN : XROrigin3D = $ShipV2/XROrigin3D
@onready var YAWPIVOT : Node3D = $ShipV2/YawPivot
@onready var PITCHPIVOT : Node3D = $ShipV2/YawPivot/PitchPivot
@onready var THROTTLE : Node3D = $ShipV2/Throttle
@onready var SIDESTICK : Node3D = $ShipV2/SideStick
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
var is_landed := false
# UNROTATED captured logical position
var dv_captured_logical_position : DVector3
#var v_captured_impact_point := Vector3.INF
var thrust : float = 0.0
var dv_last_position : DVector3
var last_xz_radius : float
var altitude_agl : float = NAN
var altitude_agl_previous : float = NAN
var vertical_velocity_agl : float = 0.0
var altitude_radar : float = NAN
var terrain_altitude : float = NAN
const RADAR_RANGE := 2000.0
# height of transition from raycast to model based altitude above ground
const RADAR_TRANSITION_LOW := RADAR_RANGE/4.0
const RADAR_TRANSITION_HIGH := RADAR_RANGE/2.0

# Sidestick State
var sidestick_x : float = 0.0
var sidestick_y : float = 0.0
var sidestick_filtered_x : float = 0.0
var sidestick_filtered_y : float = 0.0
var v_last_torque := Vector3.ZERO

# UI State 
var rotation_rate_mode : bool
var ui_thrust_lock : bool
var mouse_button_2 : bool
var alternate_control : bool
var update_displays : bool = false
var update_navball : bool = false

# Asynchronous XR inputs
var left_ax := false
var left_by := false
var right_ax := false
var right_by := false
var left_primary := Vector2.ZERO
var right_primary := Vector2.ZERO

# simple exponential filter
func exponential_filter(delta : float, time_constant : float, prev_output : float, raw_input : float) -> float:
	var weight : float = time_constant/delta
	return ((weight-1.0)*prev_output + raw_input)/weight

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
	v_thrust = Vector3.ZERO
	v_torque = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	altitude_agl = NAN
	altitude_agl_previous = NAN
	vertical_velocity_agl = 0.0
	Signals.emit_signal("ButtonLight_set_state", true)
	Signals.emit_signal("ButtonLight_set_state", false)
	alternate_control = false
	rotation_rate_mode = true
	Signals.emit_signal("ButtonAlternateControl_set_state", alternate_control)
	Signals.emit_signal("ButtonRateMode_set_state", rotation_rate_mode)
	Signals.emit_signal("Spacecraft_reset")
	is_landed = false
	set_thrust(0.0)
	reset_viewpoint()

# reset the pilot viewpoint
func reset_viewpoint():
	if XRCAMERA.current:
		# this is a little bit of VR magic .. the spacecraft alignment is not the default for Godot!
		XRORIGIN.rotation = XRREFERENCE.rotation - Vector3(0.0, XRCAMERA.rotation.y, 0.0)
		XRORIGIN.position = XRREFERENCE.position - Vector3(-XRCAMERA.position.z, XRCAMERA.position.y, XRCAMERA.position.x)
	else:
		YAWPIVOT.transform = reset_view_yaw
		PITCHPIVOT.transform = reset_view_pitch
		XRORIGIN.visible = false


# compute a viewpoint offset, relative to ship cg
func get_viewpoint_offset()-> Vector3:
	var view_offset : Vector3
	if XRCAMERA.current:
		view_offset = XRCAMERA.global_position
	else:
		view_offset = CAMERA.global_position
	view_offset -= global_position
	return view_offset


# Set spacecraft logical position to lat/long and heading (cw from N) (all in degrees)
# Also sets rotation to be level with local ground, pointing at heading
# Also sets linear velocity to match moon rotation at the given altitude
func set_logical_position(lat: float, lon: float, radius: float, alt_agl: float, heading: float, moon_rate: float):
	# NOTE: Longitude zero is in the direction of +Z per Godot convention
	# NOTE: Spacecraft rotation depends on spacecraft orientation facing +X
	var phi_physical: float = deg_to_rad(lon)
	var phi_logical: float =  phi_physical + LEVEL.current_moon_rotation
	var theta: float = deg_to_rad(lat)
	var gamma: float = deg_to_rad(-heading)
	var terrain_altitude : float = MOON.moon_data.get_terrain_altitude(lat, lon, MOON.MOON_SCALE)
	var altitude = terrain_altitude + alt_agl
	dv_logical_position.x = (radius + altitude) * cos(theta)*sin(phi_logical)
	dv_logical_position.y = (radius + altitude) * sin(theta)
	dv_logical_position.z = (radius + altitude) * cos(theta)*cos(phi_logical)
	dv_logical_velocity = get_landed_velocity(dv_logical_position, dv_logical_position.xz_length(), moon_rate)
	var q1 : Quaternion = Quaternion.from_euler(Vector3(0.0, phi_physical+PI/2.0, PI/2.0-theta))
	var q2 : Quaternion = Quaternion.from_euler(Vector3(0.0, gamma, 0.0))
	rotation = (q1*q2).get_euler()	# This rotates the ship to correspond to its unrotated position on the globe
	MOON.set_from_logical_position(self, get_viewpoint_offset(), alt_agl)
	reset_spacecraft()

# get the current computed height above "msl"
func get_altitude_msl() -> float:
	return dv_logical_position.length()-MOON.physical_radius

# compute a terrain height from Raycast (radar) and model data that favors radar
# at low altitude, and model at high altitude
func blend_terrain_altitude(msl_altitude : float, radar_altitude: float) -> float:
		var model_based_altitude : float = MOON.moon_data.get_terrain_altitude_from_vector(-MOON.position, MOON.MOON_SCALE)
		var radar_based_altitude = msl_altitude - radar_altitude
		if msl_altitude - model_based_altitude < RADAR_TRANSITION_LOW:
			return radar_based_altitude
		elif msl_altitude - model_based_altitude > RADAR_TRANSITION_HIGH:
			return model_based_altitude
		else:
			var blended : float = ((model_based_altitude*(model_based_altitude-RADAR_TRANSITION_LOW) +
				radar_based_altitude*(RADAR_TRANSITION_HIGH-model_based_altitude))
				/(RADAR_TRANSITION_HIGH-RADAR_TRANSITION_LOW))
			return blended


# Called when the node enters the scene tree for the first time.
func _ready():
	# locally owned global signals
	Signals.add_user_signal(name + "_state_changed", [{"name":"ship", "type": TYPE_OBJECT}])
	Signals.add_user_signal(name + "_lifted_off")
	Signals.add_user_signal(
		"astronomy_tick", 
		[{"name":"sidereal_days", "type": TYPE_INT},{"name":"seconds", "type":TYPE_INT}])
	# external global signals
	Signals.connect("ButtonRefuel_pressed", _on_refuel_button_pressed)
	Signals.connect("ButtonAlternateControl_changed", _on_alternate_control_changed)
	Signals.connect("ButtonRateMode_changed", _on_rotation_rate_mode_changed)
	Signals.connect("astronomy_tick", _on_astronomy_tick)
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dv_logical_position =  MOON.get_logical_position(self)
	dv_gravity_force = DVector3.Mul(mass, MOON.get_acceleration(dv_logical_position))
	dv_last_position = dv_logical_position.copy()
	contact_monitor = true
	max_contacts_reported = 1
	reset_spacecraft()


# Called physics every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if LEVEL == null:
		return
	var delta_fuel = 0.0
	v_torque = Vector3.ZERO		# all torques to zero - we will add them as we discover them
	# set up a view offset
	var view_offset := get_viewpoint_offset()

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
	GROUNDRADAR.target_position = to_local(MOON.position).normalized()*RADAR_RANGE/MOON.scale_factor
	if GROUNDRADAR.is_colliding():
		v_impact_point = GROUNDRADAR.get_collision_point()
		v_impact_normal = GROUNDRADAR.get_collision_normal()
		altitude_radar = (GROUNDRADAR.to_local(v_impact_point).length()-GROUNDRADAR.position.y)*MOON.scale_factor
		terrain_altitude = blend_terrain_altitude(altitude_msl, altitude_radar)
	else:
		altitude_radar = NAN

	if not is_nan(altitude_radar):
		if is_nan(altitude_agl):	# reset the radar displays
			Signals.emit_signal("DisplayRadarAltitude_set_valid", true)
			Signals.emit_signal("DisplayRadarHorizontalSpeed_set_valid", true)
			Signals.emit_signal("DisplayRadarVerticalSpeed_set_valid", true)
		altitude_agl = altitude_msl - terrain_altitude
		if not is_nan(altitude_agl_previous):
			var vvel : float = (altitude_agl - altitude_agl_previous) / delta
			# filter this a bit
			vertical_velocity_agl = exponential_filter(
				delta, VERTICAL_VELOCITY_TC, vertical_velocity_agl, vvel)
		altitude_agl_previous = altitude_agl
	else:
		if not is_nan(altitude_agl):
			Signals.emit_signal("DisplayRadarAltitude_set_valid", false)
			Signals.emit_signal("DisplayRadarHorizontalSpeed_set_valid", false)
			Signals.emit_signal("DisplayRadarVerticalSpeed_set_valid", false)
		altitude_agl = NAN
	
	# compute an impact restoring force
	if altitude_agl < -2.0:
		# too much. reload the scenario!
		print("Crashed under ground!")
		LEVEL.scenario_input(false, false, true)
	elif altitude_agl <= 0.0:
		is_landed = true
		angular_damp = 1	# use Godot to damp out the jiggles
		if dv_captured_logical_position == null:
			Signals.emit_signal(name + "_landed")
			landed.emit()
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
			print("Landing exceeded landing gear margins!")
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

			v_thrust_global += dv_restoring_force.vector3()
	else: # agl is undefined or above zero
		if is_landed: 
			Signals.emit_signal(name + "_lifted_off")
			angular_damp = 0
			dv_captured_logical_position = null
			angular_velocity = Vector3.ZERO
			is_landed = false



	process_physics(delta, dv_logical_position, dv_logical_velocity, v_thrust_global, net_mass)
	MOON.set_from_logical_position(self, view_offset, altitude_agl)
		
	# Input Polling
	# view reset
	if Input.is_action_just_pressed("Reset Viewpoint") or left_ax:
		left_ax = false
		reset_viewpoint()
	# scenario selection and/or restart
	var p = Input.is_action_just_pressed("Load Prev Scenario") or right_ax
	var n = Input.is_action_just_pressed("Load Next Scenario") or right_by
	var r = Input.is_action_just_pressed("Restart") or left_by
	right_ax = false
	right_by = false
	left_by = false
	# ignore other inputs if we are chhanging scenarios
	if p or n or r:
		print("Control input: ", p, n, r)
	if not LEVEL.scenario_input(p, n, r):
		if left_primary.y != 0.0:
			change_thrust(delta, left_primary.y)	# will move throttle if manipulated (up or down)
		change_thrust(delta, Input.get_axis("Thrust Decrease","Thrust Increase"))
		if Input.is_action_pressed("Thrust Max", true):
			set_thrust(1.0)
		elif Input.is_action_pressed("Thrust Cut", true):
			set_thrust(0.0)
		if not ui_thrust_lock:
			set_thrust(Input.get_action_strength("Thrust Analog"), false)

		var horiz_vel: float
		var forward_vel : float = 0.0
		if alternate_control:
			forward_vel = JOY_SENS * Input.get_axis("Viewpoint Backward", "Viewpoint Forward")
			horiz_vel = JOY_SENS * Input.get_axis("Viewpoint Left", "Viewpoint Right")
		else:
			YAWPIVOT.rotation.y -= JOY_SENS * Input.get_axis("Viewpoint Pan Left", "Viewpoint Pan Right")
			PITCHPIVOT.rotation.z += JOY_SENS * Input.get_axis("Viewpoint Pan Down", "Viewpoint Pan Up")
			PITCHPIVOT.rotation.z = clamp(PITCHPIVOT.rotation.z, -PI/2, PI/2)
		if alternate_control:
			SIDESTICK.set_sidestick(-(Input.get_axis("Yaw Right", "Yaw Left") - right_primary.x), Input.get_axis("Pitch Forward", "Pitch Backward") - right_primary.y)
		else:
			SIDESTICK.set_sidestick(-(Input.get_axis("Roll Right", "Roll Left") - right_primary.x), Input.get_axis("Pitch Forward", "Pitch Backward") - right_primary.y)
		var v_move = Quaternion.from_euler(
			Vector3(0.0, YAWPIVOT.rotation.y, PITCHPIVOT.rotation.z))*Vector3(forward_vel, 0.0, horiz_vel)
		var new_eye = YAWPIVOT.position + v_move
		if (new_eye.x < 1.8 and 
			new_eye.x > 1.2 and
			new_eye.y > 5 and
			new_eye.y < 5.7 and 
			new_eye.z > -0.3 and new_eye.z < 0.3):
			#new_eye.y < (-5.0/6.0)*new_eye.x + 6.675):
			YAWPIVOT.position = new_eye
		
		# oddly, this has to be here to keep the ship rotating		
		v_torque = Vector3.ZERO
		v_torque.y += Input.get_axis("Yaw Right Always", "Yaw Left Always")
		sidestick_filtered_x = exponential_filter(delta, PITCH_INPUT_TC, sidestick_filtered_x, sidestick_x)
		sidestick_filtered_y = exponential_filter(delta, PITCH_INPUT_TC, sidestick_filtered_y, sidestick_y)
		v_torque.z += sidestick_filtered_y
		if alternate_control:
			v_torque.y -= sidestick_filtered_x
		else:
			v_torque.x += sidestick_filtered_x
		# rotational stabilization, but only if we're not damping oscillations using angular_damp
		# a body that is not rotating in global game space is actually spinning with the moon rate
		if rotation_rate_mode:
			# rate mode. Convert commanded torque (body coords) to a rotational rate in global space
			var v_commanded_rate = basis * v_torque * RATE_FROM_TORQUE
			var corrected_angular_velocity : Vector3 = angular_velocity + Vector3.UP*LEVEL.moon_axis_rate - v_commanded_rate
			var corrected_angular_rate := corrected_angular_velocity.length()
			if  corrected_angular_rate > STABILITY_MINIMUM_RATE and (angular_damp == 0.0):
				# convert torque to local space, adjust for ship moment of inertia
				var v_correction_torque = basis.inverse() * (-corrected_angular_velocity * STABILITY_COEFFICIENT)
				#if v_correction_torque.length() < STABILITY_MINIMUM_TORQUE:
				#	v_correction_torque = Vector3.ZERO
				v_torque += v_correction_torque.limit_length()
#		if ((v_last_torque.length() < TORQUE_THRESHOLD and v_torque.length() >= TORQUE_THRESHOLD) or 
#			(v_last_torque.length() >= TORQUE_THRESHOLD and v_torque.length() < TORQUE_THRESHOLD)) :
		if v_last_torque.length() != v_torque.length():
			torque_changed.emit(v_torque, v_last_torque, TORQUE_THRESHOLD)
		v_last_torque = v_torque
		# convert back to global space
		apply_torque(basis * v_torque * delta * 10000)
	
	if update_displays:
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
					
		# Display Updates
		var v_ground_logical_velocity = get_landed_velocity(dv_logical_position, dv_logical_position.xz_length(), LEVEL.moon_axis_rate).vector3()
		var v_logical_velocity = dv_logical_velocity.vector3()
		# logical ground normal
		var v_normal = dv_logical_position.vector3().normalized()
		# logical velocity, relative to ground
		var v_logical_ground_rel_velocity = v_logical_velocity-v_ground_logical_velocity
		var v_logical_hvel = v_logical_ground_rel_velocity - v_logical_ground_rel_velocity.dot(v_normal) * v_normal
		# scalar horizontal velocity
		var hvel = v_logical_hvel.length()
		# unrotated logical ground relative horizontal.. 
		var v_global_unrot_hvel = v_logical_hvel.rotated(Vector3.UP, -LEVEL.current_moon_rotation)
		# transformed to ship-local coordinates
		var v_local_hvel = basis.inverse()*v_global_unrot_hvel
		# obtain vector for local vertical
		var v_local_vertical = -(basis.inverse()*MOON.position)
		# horizontal drift data only valid if within 45 degrees of vertical and in radar range
		if v_local_vertical.angle_to(Vector3.UP) < PI/4 and not is_nan(altitude_radar):
			# map the h drift onto our xz plane
			v_local_hvel = Vector2(v_local_hvel.z, v_local_hvel.x).normalized()*v_local_hvel.length()
			# obtain an angle in the local horizontal plane and DISPLAY it!
			Signals.emit_signal("CrossPointer_drift_changed", v_local_hvel)
			Signals.emit_signal("DisplayRadarHorizontalSpeed_set_value", hvel)
			Signals.emit_signal("DisplayRadarHorizontalSpeed_set_valid", true)
		else:
			Signals.emit_signal("DisplayRadarHorizontalSpeed_set_valid", false)
		# altitude change direction
		Signals.emit_signal("DisplayRadarVerticalSpeed_set_value", vertical_velocity_agl)
		Signals.emit_signal("DisplayIMUAltitude_set_value", altitude_msl/1000.0)
		Signals.emit_signal("DisplayIMUSpeed_set_value", v_logical_velocity.length())
		Signals.emit_signal("DisplayIMUAcceleration_set_value", v_thrust_global.length()/net_mass)
		Signals.emit_signal("DisplayRadarAltitude_set_value", altitude_agl)
		Signals.emit_signal("DisplayFuelPercentage_set_value", 100.0*fuel/FULL_FUEL)
		if AA > 0.0:
			Signals.emit_signal("DisplayIMUApoapsis_set_value", AA/1000.0)
			Signals.emit_signal("DisplayIMUApoapsis_set_valid", true)
		else:
			Signals.emit_signal("DisplayIMUApoapsis_set_valid", false)
		if PA > 0.0:
			Signals.emit_signal("DisplayIMUPeriapsis_set_value", PA/1000.0)
			Signals.emit_signal("DisplayIMUPeriapsis_set_valid", true)
		else:
			Signals.emit_signal("DisplayIMUPeriapsis_set_valid", false)
	
		# done with display updates
		update_displays = false
	if update_navball:
		# Inform interested parties!
		Signals.emit_signal(name + "_state_changed", self as Object)
		update_navball = false
		
	
	
func change_thrust(step : float, value : float):
	if value != 0.0:
		ui_thrust_lock = true
		thrust = clamp(thrust+value*step*THRUST_STEP_MULTIPLIER, 0.0, 1.0)
		THROTTLE.set_throttle_slider(thrust)
 
func set_thrust(value : float, lock : bool = true):
	ui_thrust_lock = lock
	thrust = value
	THROTTLE.set_throttle_slider(thrust)

func _on_throttle_output_changed(value):
	thrust_changed.emit(value)
	thrust = value
	if value == 0.0:
		v_thrust.y = 0.0
	else:
		v_thrust.y = THRUST_MIN + (THRUST_MAX - THRUST_MIN)*value

func _on_sidestick_output_changed(x:float, y:float) -> void:
	var x_nulled : float = 0.0 if abs(x) < STICK_NULL else (x - sign(x)*STICK_NULL)/(1.0-STICK_NULL)
	var y_nulled : float = 0.0 if abs(y) < STICK_NULL else (y - sign(y)*STICK_NULL)/(1.0-STICK_NULL)
	sidestick_x = x
	sidestick_y = y

func _on_alternate_control_changed(state: bool, light_state: bool) -> void:
	alternate_control = state

func _on_rotation_rate_mode_changed(state: bool, light_state: bool) -> void:
	rotation_rate_mode = state

func _on_refuel_button_pressed(_state, _light_state):
	fuel = FULL_FUEL	# FIXME this should be refilled some other way

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Toggle Thrust Lock"):
		ui_thrust_lock = not ui_thrust_lock
	elif event.is_action_pressed("Alternate Control"):
		Signals.emit_signal("ButtonAlternateControl_press")
	elif event.is_action_pressed("Rotation Damp Toggle"):
		Signals.emit_signal("ButtonRateMode_press")
	elif (event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_RIGHT):
		mouse_button_2 = event.is_pressed()
	elif event is InputEventMouseMotion and mouse_button_2:
		YAWPIVOT.rotation.y -= MOUSE_SENS * event.relative.x
		PITCHPIVOT.rotation.z -= MOUSE_SENS * event.relative.y
		PITCHPIVOT.rotation.z = clamp(PITCHPIVOT.rotation.z, -PI/2, PI/2)
	elif event.is_action_pressed("Quit"):
		get_tree().quit()

func _on_xr_left_button_pressed(name):
	if name == "ax_button":
		left_ax = true
	elif name == "by_button":
		left_by = true

func _on_xr_left_button_released(name):
	if name == "ax_button":
		left_ax = false
	elif name == "by_button":
		left_by = false

func _on_xr_right_button_pressed(name):
	if name == "ax_button":
		right_ax = true
	elif name == "by_button":
		right_by = true
		
func _on_xr_right_button_released(name):
	if name == "ax_button":
		right_ax = false
	elif name == "by_button":
		right_by = false
		
func _on_xr_left_input_vector_2_changed(name, value):
	if name == "primary":
		left_primary = value

func _on_xr_right_input_vector_2_changed(name, value):
	if name == "primary":
		right_primary = value

func _on_display_timer_timeout():
	update_displays = true

func _on_navball_timer_timeout():
	update_navball = true

func _on_astronomy_tick(current_moon_rotation_count: int, astronomy_seconds: int):
	Signals.emit_signal("DisplayDays_set_value", current_moon_rotation_count)
	var hours : float = floor(astronomy_seconds / 3600.0)
	var minutes : float = floor((astronomy_seconds - hours*3600.0)/60.0)
	var seconds : float = astronomy_seconds - hours*3600.0 - minutes*60.0
	Signals.emit_signal("DisplayHHMMSS_set_value", hours*10000.0 + minutes*100.0 + seconds)
