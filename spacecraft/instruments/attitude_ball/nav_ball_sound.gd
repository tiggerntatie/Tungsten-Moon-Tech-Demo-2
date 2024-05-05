extends AudioStreamPlayer3D

func _on_attitude_ball_orientation_changed(rate : float, threshold : float):
	pitch_scale = clampf(rate / threshold, 1.0, 4.0)
	if not playing or get_playback_position() > 1.5:
		play(0.5)


func _on_attitude_ball_orientation_stopped():
	if playing:
		seek(3.0)
