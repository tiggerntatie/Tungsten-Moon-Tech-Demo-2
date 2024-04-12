class_name MeshChunk

extends MeshInstance3D

@onready var dv_position : DVector3 = DVector3.FromVector3(position):
	set (val):
		dv_position = val
		position = val.vector3()

# size is distance within which high precision position calculations must be done
var size : float
var is_high_precision := false
var saved_relative_position
var cubic_position : Vector3 = Vector3.ZERO
@onready var parent : MoonSmartFace = get_parent()
@onready var moon : Node3D = parent.get_parent()
@onready var dv_face_position := parent.dv_position

func _ready():
	reset_high_precision()
	start_timer()

func reset_high_precision():
	#print("chunk: reset_high_precision")
	is_high_precision = false
	top_level = false
	evaluate_precision()

func evaluate_precision():
	var high_precision = global_position.length() < size*moon.scale.x
	print(global_position, " ", size, " ", moon.scale.x)
	if high_precision:
		print("is high precision")
		if not is_high_precision:
			print("adding high precision")
			is_high_precision = true
			top_level = true	# position updates manually set at global level
			moon.high_precision_chunks[self] = null
	else:
		if is_high_precision:
			print("removing high precision")
			is_high_precision = false
			top_level = false	# position updates set from parent
			moon.high_precision_chunks.erase(self)
	

func start_timer():
	var timer := get_tree().create_timer(60.0)
	timer.timeout.connect(_on_timer_timeout)
	
func _on_timer_timeout():
	evaluate_precision()
	start_timer()
