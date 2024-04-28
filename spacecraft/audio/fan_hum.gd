extends AudioStreamPlayer3D


var _started = false
func _process(delta):
	if not _started:
		play(0.1)
		start_timer()
		_started = true

func start_timer():
	var scene := get_tree()
	if scene != null:
		var timer := scene.create_timer(6.0)
		timer.timeout.connect(_on_timer_timeout)
	
func _on_timer_timeout():
	seek(0.1)
	start_timer()
