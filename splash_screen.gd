extends Control

var progress := []
var scene_name : String
var scene_load_status := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	scene_name = "res://moonspace.tscn"
	ResourceLoader.load_threaded_request(scene_name)	# use sub threads

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(scene_name, progress)
	$ProgressBar.value = 100.0*progress[0]
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene := ResourceLoader.load_threaded_get(scene_name)
		get_tree().change_scene_to_packed(new_scene)

func _on_meshes_loaded(value : float):
	print(value)
