extends AudioStreamPlayer3D



func _on_spacecraft_torque_changed(new: Vector3, old: Vector3, threshold: float):
	if new.length() > threshold and old.length() < threshold:
		play()
