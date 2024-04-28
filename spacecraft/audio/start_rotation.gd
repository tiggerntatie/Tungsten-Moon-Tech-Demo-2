extends AudioStreamPlayer3D


func _on_spacecraft_torque_changed(value: Vector3):
	if value != Vector3.ZERO:
		play()
