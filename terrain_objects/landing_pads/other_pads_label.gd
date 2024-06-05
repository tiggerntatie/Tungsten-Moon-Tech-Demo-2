extends Label3D

func set_pads(
	moon_data : MoonData, 
	latitude : float, 
	longitude: float, 
	other_pads : Array[TerrainObject])-> void:
		
	text = "Other Pads\n"
	for pad in other_pads:
		var dest : Array[float] = moon_data.get_distance_and_bearing(
			latitude, 
			longitude, 
			pad.latitude,
			pad.longitude,
		)
		text += pad.identifier + " "
		var dist_text : String = "%3.0f m " % dest[0]
		if dest[0] > 1000.0:
			dist_text =  "%.1f km " % (dest[0]/1000.0)
		text += dist_text
		var brg_text : String = "%3.0f°" % dest[1]
		text += brg_text + "\n"
