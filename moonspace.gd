extends Node3D

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
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		get_viewport().use_xr = false
	# END VR Setup	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
