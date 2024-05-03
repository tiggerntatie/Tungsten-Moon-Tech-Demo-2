extends AudioStreamPlayer3D



func _on_spacecraft_torque_changed(value: Vector3, threshold: float):
	if value.length() < threshold:
		play()
	else:
		stop()
