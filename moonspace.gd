extends Node3D

@onready var CAMERA : Camera3D = $"./Spacecraft/YawPivot/PitchPivot/Camera3D"
@onready var XRCAMERA : XRCamera3D = $"./Spacecraft/YawPivot/PitchPivot/XROrigin3D/XRCamera3D"
@onready var ENVIRONMENT : WorldEnvironment = $WorldEnvironment
@onready var SUNLIGHT : DirectionalLight3D = $DirectionalLightSun
@onready var PLANETLIGHT : DirectionalLight3D = $DirectionalLightPlanet
@onready var planet_default_light_energy = PLANETLIGHT.light_energy
var xr_interface: XRInterface
## Inertial reference rotation rate about y-axis, radians per second
@export_range(-1,1) var inertial_rotation_rate : float = 0.000290888
## Planet rotation rate about its local y-axis, radians per second
@export_range(-1,1) var planet_rotation_rate : float = 0.000290888
@export var planet_axis_direction : Vector3 = Vector3(0.0, 1.0, 0.0)
@export_range(0.0, 360.0, 0.1, "degrees") var planet_axis_rotation : float = 0.0
var current_rotation = PI


# Called when the node enters the scene tree for the first time.
func _ready():
	# VR setup
	var XRisup: bool = false
	if XRServer.get_interface_count():
		xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			XRisup = true
			print("OpenXR initialised successfully")
			
			# Turn off v-sync
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
			# Change our main viewport to putput to the HMD
			get_viewport().use_xr = true
			CAMERA.current = false
			XRCAMERA.current = true
	if not XRisup:
		print("OpenXR not found or initialized; running in non-VR mode")
		get_viewport().use_xr = false
		CAMERA.current = true
		XRCAMERA.current = false
	# END VR Setup	
	# Shader setup
	ENVIRONMENT.environment.sky.sky_material.set_shader_parameter("planet_default_light_energy", planet_default_light_energy)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# update shader parameters
	current_rotation += inertial_rotation_rate * delta
	ENVIRONMENT.environment.sky.sky_material.set_shader_parameter("star_rotation", current_rotation)
	SUNLIGHT.rotation.y = current_rotation
	planet_axis_rotation += planet_rotation_rate * delta
	var planet_rotation: Quaternion = Quaternion(planet_axis_direction.normalized(), planet_axis_rotation)
	ENVIRONMENT.environment.sky.sky_material.set_shader_parameter("planet_rotation", planet_rotation)
	var qSunPosition = Quaternion.from_euler(SUNLIGHT.rotation)
	var qPlanetPosition = Quaternion.from_euler(PLANETLIGHT.rotation)
	PLANETLIGHT.light_energy = planet_default_light_energy * qSunPosition.angle_to(qPlanetPosition) / PI
	print(PLANETLIGHT.light_energy)
	
