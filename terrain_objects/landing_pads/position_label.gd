extends Label3D

func set_position_text(objname: String, lon: float, lat: float)-> void:
	text = "%s %3.1f°E, %2.1f°N" % [objname, lon, lat]
