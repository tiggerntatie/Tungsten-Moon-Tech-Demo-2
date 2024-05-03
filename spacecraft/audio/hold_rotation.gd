extends AudioStreamPlayer3D

var timer : SceneTreeTimer = null

func _on_spacecraft_torque_changed(value : Vector3, threshold: float):
	if value.length() < threshold:
		stop()
	else:
		start_timer()

func start_timer():
	play()
	var scene := get_tree()
	if scene != null:
		timer = scene.create_timer(1.9)
		timer.timeout.connect(_on_timer_timeout)
	else:
		stop()
	
func _on_timer_timeout():
	if playing:
		start_timer()
