extends Node3D

# default moon scale 
var default_moon_scale_set : bool = false
var default_moon_scale : float

func _on_moon_position_changed(dv_position : DVector3, moon_scale: Vector3):
	var fscale : float = 1.0
	if not default_moon_scale_set:
		default_moon_scale = moon_scale.x
		default_moon_scale_set = true
	fscale = moon_scale.x / default_moon_scale
	scale = Vector3.ONE * fscale
	# terrain objects scaled at unity by default, so position must be corrected
	#position = DVector3.Mul(fscale, dv_position).vector3()
	position = dv_position.vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("moon_position_changed", _on_moon_position_changed)

