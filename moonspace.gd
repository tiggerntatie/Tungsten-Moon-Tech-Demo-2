extends Node3D

@onready var CAMERA : Camera3D = $"./Spacecraft/YawPivot/PitchPivot/Camera3D"
@onready var XRCAMERA : XRCamera3D = $"./Spacecraft/YawPivot/PitchPivot/XROrigin3D/XRCamera3D"
var xr_interface: XRInterface

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
		CAMERA.current = false
		XRCAMERA.current = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		get_viewport().use_xr = false
		CAMERA.current = true
		XRCAMERA.current = false
	# END VR Setup	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
