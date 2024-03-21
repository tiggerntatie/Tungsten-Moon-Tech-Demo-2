extends Node3D

@onready var SPACECRAFT : RigidBody3D = $Spacecraft
@onready var CAMERA : Camera3D = $Spacecraft/YawPivot/PitchPivot/Camera3D
@onready var XRCAMERA : XRCamera3D = $Spacecraft/YawPivot/PitchPivot/XROrigin3D/XRCamera3D
@onready var ENVIRONMENT : WorldEnvironment = $WorldEnvironment
@onready var SUNLIGHT : DirectionalLight3D = $DirectionalLightSun
@onready var PLANETLIGHT : DirectionalLight3D = $DirectionalLightPlanet
@onready var MOON : MeshInstance3D = $TungstenMoon
@onready var planet_default_light_energy = PLANETLIGHT.light_energy
var xr_interface: XRInterface

## INITIAL SPACECRAFT POSITION
@export_group("Spacecraft Start Position")
## Longitude in degrees
@export_range(-180.0, 180.0, 0.1, "degrees") var initial_longitude : float = 0.0
## Latitude in degrees
@export_range(-90.0, 90.0, 0.1, "degrees") var initial_latitude : float = 0.0
## Heading in degrees (0-359.9, clockwise from North)
@export_range(0.0, 359.9, 0.1, "degrees") var initial_heading : float = 0.0

## SOLAR SYSTEM PARAMETERS
@export_group("Solar System")
## Speed factor. 1 = normal time, 10 = 10x speed up. Affects only astronomical positions.
@export_range(1.0, 10000.0, 1.0) var astronomy_speed_factor : float = 1.0
## Starting time in days. Allows starting the sim at a past or future point in time.
@export var astronomy_starting_day : float = 0.0
## Computed parameters
var astronomy_starting_seconds : float

## SOLAR PARAMETERS
@export_subgroup("Solar Parameters")
## Period of planet orbit around the sun (days)
@export_range(0.01, 500.0) var solar_orbit_period_days : float = 365.0
## Axis direction of apparent sun orbit around the planet
@export var solar_orbit_axis_direction : Vector3 = Vector3(0.0, 1.0, 0.0)
## Initial rotation of planet around sun (radians)
@export_range(0.0, TAU, 0.001) var solar_orbit_rotation = 0.0
## Constant parameters
const G = 6.674E-11
const solar_diameter : float = 1.4E9 # m
const solar_kepler_constant : float = 2.95E-19 # s^2/m^3
## Computed parameters
var solar_distance : float
var solar_orbit_rate : float

## PLANET PARAMETERS
@export_subgroup("Planet Parameters")
## Planet mass (in multiples of Earth mass) e.g. 1.2 is 1.2 times Earth mass
@export_range(0.1, 100.0, 0.01) var planet_mass : float = 1.0
## Orbital period of moon around the planet (hours)
@export_range(0.1, 500.0, 0.01) var planet_orbit_period_hours : float = 50.0
## Axis direction of apparent planet orbit around the moon
@export var planet_orbit_axis_direction : Vector3 = Vector3(0.0, 1.0, 0.0)
## Initial rotation of moon around planet (radians)
@export_range(0.0, TAU, 0.001) var planet_orbit_rotation = 0.0
## Axis direction of planet rotation
@export var planet_axis_direction : Vector3 = Vector3(0.0, 1.0, 0.0)
## Initial rotation of the planet on its axis (radians)
@export_range(0.0, TAU, 0.001) var planet_axis_rotation = 0.0
## Rotational period of the planet about its axis (hours)
@export_range(0.1, 100.0, 0.01) var planet_axis_period_hours : float = 20.0
## Constant Parameters
const density_earth : float = 5515.0 # kg/m^3
const mass_earth : float = 5.97E22 # kg
## Computed parameters
var planet_diameter : float
var planet_distance : float
var planet_orbit_rate : float
var shadow_angular_diameter : float # for rendering solar eclipses on planet surface
var planet_axis_rate : float

## MOON PARAMETERS
@export_subgroup("Moon Parameters")
## Initial rotation of the moon on its axis (radians)
@export_range(0.0, TAU, 0.001) var moon_axis_rotation = 0.0
## Rotational period of the moon about its axis (hours)
@export_range(0.1, 500.0, 0.01) var moon_axis_period_hours : float = 100.0
## Computed parameters
var moon_axis_rate : float :
	get: 
		return moon_axis_rate

var current_moon_rotation : float :
	get: 
		return current_moon_rotation

var current_moon_rotation_count : int
var current_planet_rotation : float
var current_planet_orbit_rotation : float
var current_solar_rotation : float

## GAME STATE
@export_group("Spacecraft Start Scenarios")
@export var scenario_list : Array = [
	{"long": 161.0, "lat": 0.0, "heading": 0.0},
	{"long": 161.0, "lat": 0.0, "heading": 0.0},
	{"long": 161.0, "lat": 0.0, "heading": 0.0},
	{"long": 161.0, "lat": 0.0, "heading": 0.0},
	{"long": 161.0, "lat": 0.0, "heading": 0.0},
]
var scenario_index : int = 0
const CONFIG_FILE_NAME = "user://settings.cfg"
@onready var config = ConfigFile.new()



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
			XRCAMERA.position = XRCAMERA.position   # reset head position
	if not XRisup:
		print("OpenXR not found or initialized; running in non-VR mode")
		get_viewport().use_xr = false
		CAMERA.current = true
		XRCAMERA.current = false
	# END VR Setup	
	# Shader setup
	ENVIRONMENT.environment.sky.sky_material.set_shader_parameter("planet_default_light_energy", planet_default_light_energy)

	# Compute solar system constants
	moon_axis_rate = TAU/(moon_axis_period_hours*3600)
	planet_axis_rate = TAU/(planet_axis_period_hours*3600)
	solar_orbit_rate = TAU/(solar_orbit_period_days*24*3600)
	planet_orbit_rate = TAU/(planet_orbit_period_hours*3600)
	solar_distance = pow(pow(solar_orbit_period_days*24*3600,2) / solar_kepler_constant, 1.0/3.0)
	SUNLIGHT.light_angular_distance = rad_to_deg(solar_diameter/solar_distance)
	planet_diameter = 2.0*pow((3.0*mass_earth*planet_mass)/(4.0*density_earth*PI), 1.0/3.0)
	planet_distance = pow(G*mass_earth*planet_mass*pow(planet_orbit_period_hours*3600.0/TAU,2),1.0/3.0)
	PLANETLIGHT.light_angular_distance = rad_to_deg(planet_diameter/planet_distance)
	# Initial solar system rotations
	astronomy_starting_seconds = astronomy_starting_day*24*3600
	current_moon_rotation = moon_axis_rotation + moon_axis_rate*astronomy_starting_seconds
	current_moon_rotation_count = floorf(current_moon_rotation / TAU)
	current_moon_rotation = fmod(current_moon_rotation, TAU)
	# now, base starting seconds on moon rotations
	astronomy_starting_seconds = (current_moon_rotation_count * TAU + current_moon_rotation)/moon_axis_rate
	current_planet_rotation = planet_axis_rotation + planet_axis_rate*astronomy_starting_seconds
	current_solar_rotation = solar_orbit_rotation + solar_orbit_rate*astronomy_starting_seconds
	current_planet_orbit_rotation = planet_orbit_rotation + planet_orbit_rate*astronomy_starting_seconds
	
	# Load state?
	var err = config.load(CONFIG_FILE_NAME)
	if err != OK: 
		config.set_value("Scenario", "index", 0)
		config.save(CONFIG_FILE_NAME)
	else:
		scenario_index = config.get_value("Scenario", "index", 0)
		if scenario_index >= scenario_list.size():
			scenario_index = 0
			save_scenario(scenario_index)
	load_scenario(scenario_index)
	
func save_scenario(index : int):
	config.set_value("Scenario", "index", index)
	config.save(CONFIG_FILE_NAME)

func load_scenario(index : int):
	# Supply initial spacecraft position
	print("Locating to long: ", scenario_list[index]["long"], " lat: ", scenario_list[index]["lat"], " hdg: ", scenario_list[index]["heading"])
	SPACECRAFT.set_logical_position(
		scenario_list[index]["lat"], 
		scenario_list[index]["long"], 
		MOON.mesh.radius, 
		1.0, 	# altitude
		scenario_list[index]["heading"],
		moon_axis_rate)
	
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# update shader parameters 
	# Rotate starfield to account for Tungsten Moon rotation
	var step: float = delta * astronomy_speed_factor
	current_moon_rotation += moon_axis_rate * step
	if current_moon_rotation > TAU:
		current_moon_rotation -= TAU
		current_moon_rotation_count += 1
	
	# now, base starting seconds on moon rotations
	astronomy_starting_seconds = (current_moon_rotation_count * TAU + current_moon_rotation)/moon_axis_rate
	current_planet_rotation = planet_axis_rotation + planet_axis_rate*astronomy_starting_seconds
	current_solar_rotation = solar_orbit_rotation + solar_orbit_rate*astronomy_starting_seconds
	current_planet_orbit_rotation = planet_orbit_rotation + planet_orbit_rate*astronomy_starting_seconds

	ENVIRONMENT.environment.sky.sky_material.set_shader_parameter("star_rotation", -current_moon_rotation)
	# Position sun position to account for planet orbit and moon rotation
	var qSunPosition = Quaternion(solar_orbit_axis_direction.normalized(), current_solar_rotation)
	var qPlanetPosition = Quaternion(planet_orbit_axis_direction.normalized(), current_planet_orbit_rotation)
	var qMoonPosition = Quaternion(Vector3(0.0, 1.0, 0.0), -current_moon_rotation)
	SUNLIGHT.rotation = (qSunPosition*qMoonPosition).get_euler()
	PLANETLIGHT.rotation = (qPlanetPosition*qMoonPosition).get_euler()

	# Tell shader about the orientation and rotation state of the planet so it can be textured correctly
	var planet_rotation: Quaternion = Quaternion(planet_axis_direction.normalized(), current_planet_rotation)
	ENVIRONMENT.environment.sky.sky_material.set_shader_parameter("planet_rotation", planet_rotation)
	# Adjust "planetlight" energy based on relative position of sun and planet
	PLANETLIGHT.light_energy = planet_default_light_energy * qSunPosition.angle_to(qPlanetPosition) / PI
	
	# Handle UI
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Load Prev Scenario"):
		scenario_index = clamp(scenario_index - 1, 0, scenario_list.size()-1)
		save_scenario(scenario_index)
		load_scenario(scenario_index)
	if event.is_action_pressed("Load Next Scenario"):
		scenario_index = clamp(scenario_index + 1, 0, scenario_list.size()-1)
		save_scenario(scenario_index)
		load_scenario(scenario_index)
