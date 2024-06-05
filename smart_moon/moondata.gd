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
	
# this returns a unit vector pointing to the position on the moon surface for a given
# latitude and longitude
func get_vector_position(lat: float, lon: float) -> Vector3:
	var lat_rad : float = deg_to_rad(lat)
	var lon_rad : float = deg_to_rad(lon)
	return Vector3(
		cos(lat_rad)*sin(lon_rad),
		sin(lat_rad),
		cos(lat_rad)*cos(lon_rad))
	
# this returns a terrain altitude (relative to msl) for any lat/lon position on the moon surface
# it is generated from the 2d random field used to generate the mesh, but will *differ* from
# actual height, especially near the center of a face
func get_terrain_altitude(lat: float, lon: float, fscale: float) -> float:
	var rel_position : Vector3 = get_vector_position(lat, lon)
	return get_terrain_altitude_from_vector(rel_position, fscale)

# this returns a terrain altitude (relative to msl) for any vector position on the moon surface
# it is generated from the 2d random field used to generate the mesh, but will *differ* from
# actual height, especially near the center of a face
func get_terrain_altitude_from_vector(pos_vector : Vector3, fscale: float) -> float:
	var est_height = (point_on_moon(pos_vector.normalized()).length()-radius)*fscale
	return est_height


# get orientation of an object on the surface, given latitude, longitude and heading
func get_object_surface_rotation(lat: float, lon: float, heading: float) -> Vector3:
	# NOTE: Longitude zero is in the direction of +Z per Godot convention
	# NOTE: Spacecraft rotation depends on spacecraft orientation facing +X
	var phi: float = deg_to_rad(lon)
	var theta: float = deg_to_rad(lat)
	var gamma: float = deg_to_rad(-heading)
	var q1 : Quaternion = Quaternion.from_euler(Vector3(0.0, phi+PI/2.0, PI/2.0-theta))
	var q2 : Quaternion = Quaternion.from_euler(Vector3(0.0, gamma, 0.0))
	return (q1*q2).get_euler()	# This rotates the object to correspond to its position on the globe

# get longitude and latitude of from bearing/distance from starting long/lat.
# distance measured in meters, ASSUMES a 1000x moon sccale unless otherwise given
# longitude/latitude measured in degrees
# lat/long returned as a list
func get_destination_from_bearing_and_distance(
	lat: float, 
	lon: float, 
	heading: float, 
	dist: float,
	fscale: float = 1000.0) -> Array[float]:
	var A : float = deg_to_rad(heading)
	var b = PI/2.0 - deg_to_rad(lat)
	var c = dist/(radius * fscale)	# great circle angle in radians
	# solve cosine rule for a in spherical trigonometry
	var a = acos(cos(b)*cos(c) + sin(b)*sin(c)*cos(A))	
	# infer latitude of destination from a:
	var dest_lat = 90.0 - rad_to_deg(a)
	# solve half angle formula for angle C
	var s = (a + b + c)/2.0
	var C = 2*acos(sqrt((sin(s)*sin(s-c))/(sin(a)*sin(b))))
	if heading > 180.0:
		C *= -1.0
	# infer longitude of destination from C
	var dest_lon = lon + rad_to_deg(C)
	return [dest_lat, dest_lon]

# get distance and bearing from one lat/lon position to another lat/lon
# ASSUMES a 1000x moon sccale unless otherwise given
# lat/lon measured in degrees
# distance/bearing returned as a list
# distance measured in meters
# bearing measured in degrees
func get_distance_and_bearing(
	lat1 : float,
	lon1 : float,
	lat2 : float,
	lon2 : float,
	fscale: float = 1000.0) -> Array[float]:
	var C : float = deg_to_rad(lon2 - lon1)
	var b : float = PI/2.0 - deg_to_rad(lat1)
	var a : float = PI/2.0 - deg_to_rad(lat2)
	var c : float = acos(cos(a)*cos(b) + sin(a)*sin(b)*cos(C))
		# solve half angle formula for angle A
	var s : float = (a + b + c)/2.0
	var A : float = 2*acos(sqrt((sin(s)*sin(s-a))/(sin(b)*sin(c))))
	if C < 0:
		A = 2*PI - A
	var dist : float = c * radius * fscale
	var bearing : float = rad_to_deg(A)
	return [dist, bearing]
