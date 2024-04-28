extends AudioStreamPlayer3D

var current_thrust := 0.0
var engine_on := false
var timer_active := false
func _on_spacecraft_thrust_changed(value: float):
	current_thrust = value
	if current_thrust == 0.0:
		engine_on = false
	elif not engine_on and current_thrust != 0:
		engine_on = true
		if not timer_active:
			start_timer()

func start_timer():
	play()
	var scene := get_tree()
	if scene != null and current_thrust != 0.0:
		var timer := scene.create_timer(clamp(0.08/current_thrust,0.08,0.8))
		timer_active = true
		timer.timeout.connect(_on_timer_timeout)
	
func _on_timer_timeout():
	timer_active = false
	start_timer()
