@tool
extends Resource

class_name MoonData

@export_range(1, 400, 1) var radius : float = 1.0:
	set(val):
		radius = val
		emit_signal("changed")

@export_range(2, 8, 1) var resolution_power : int = 2:
	set(val):
		resolution_power = val
		emit_signal("changed")

@export var noise_map : FastNoiseLite:
	set(val):
		noise_map = val
		emit_signal("changed")
		if noise_map != null and not noise_map.is_connected("changed", self.on_data_changed):
			noise_map.connect("changed", self.on_data_changed)

@export var amplitude : float = 1.0:
	set(val):
		amplitude = val
		emit_signal("changed")

@export_range(0.0, 0.99, 0.01) var flatten_percentage : float = 0.01:
	set(val):
		flatten_percentage = val
		emit_signal("changed")

# pick up changes in moondata's embedded resources and let them flow down with our own
func on_data_changed():
	emit_signal("changed")
	
# encapsulate moon point transformations here:
func point_on_moon(point_on_sphere : Vector3, unit_sphere_out : bool = false) -> Vector3:
	var elevation = noise_map.get_noise_3dv(point_on_sphere)   # returns from -1 to 1?
	var elevation1 = (elevation + 1)/2.0*amplitude  # now (0..amplitude)
	var elevation2 = elevation1 - flatten_percentage * amplitude	  # 
	var elevation3 = max(0.0, elevation2)/(1.0-flatten_percentage)
	#print(elevation, " ", elevation1, " ", elevation2, " ", elevation3)
	var output : Vector3 = point_on_sphere * (radius + elevation3)
	if unit_sphere_out:
		return output / radius
	return output
	
