@tool
extends MeshInstance3D
class_name MoonMeshFace



func regenerate_mesh(moon_data : MoonData):
	const face_normal_array : Array = [
		Vector3(1,0,0), 
		Vector3(-1,0,0), 
		Vector3(0,1,0), 
		Vector3(0,-1,0), 
		Vector3(0,0,1), 
		Vector3(0,0,-1)]
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertex_array := PackedVector3Array()
	var uv_array := PackedVector2Array()
	var normal_array := PackedVector3Array()
	var index_array := PackedInt32Array()
	
	# six faces, each face edge is 2^power divisions. 
	var face_resolution = pow(2,moon_data.resolution_power)+1
	var num_squares_vertices_per_face = pow(face_resolution,2)
	var num_square_vertices : int = 6 * num_squares_vertices_per_face # total square vertices per face side * faces\
	var num_squares_per_face = pow(pow(2,moon_data.resolution_power), 2)
	var num_triangle_indices : int = 6 * num_squares_per_face * 6 # Six faces, two triangles of 3 vertices per square
	
	normal_array.resize(num_square_vertices)
	uv_array.resize(num_square_vertices)
	vertex_array.resize(num_square_vertices)
	index_array.resize(num_triangle_indices)
	
	var tri_index : int = 0		# preparing to construct triangles
	for norm_i in range(face_normal_array.size()):
		var norm : Vector3 = face_normal_array[norm_i]
		var axisA := Vector3(norm.y, norm.z, norm.x)	# one edge perpendicular to normal
		var axisB : Vector3 = norm.cross(axisA)
		# subdividing each face, and finding a Vector3 position for each subdividing square vertex
		for y in range(face_resolution):
			for x in range(face_resolution):
				var i : int = num_squares_vertices_per_face * norm_i + x + y * face_resolution
				var percent : Vector2 = Vector2(x, y) / (face_resolution-1)
				var pointOnUnitCube : Vector3 = norm + (percent.x-0.5) * 2.0 * axisA + (percent.y-0.5) * 2.0 * axisB
				var pointOnUnitSphere := pointOnUnitCube.normalized()
				var pointOnMoon  := moon_data.point_on_moon(pointOnUnitSphere)
				vertex_array[i] = pointOnMoon
				uv_array[i] = Vector2(percent.x, percent.y)		# quick and easy uvs
				if x != face_resolution-1 and y != face_resolution-1:
				#if true:
					index_array[tri_index+2] = i
					index_array[tri_index+1] = i+face_resolution+1
					index_array[tri_index] = i+face_resolution
					
					index_array[tri_index+5] = i
					index_array[tri_index+4] = i+1
					index_array[tri_index+3] = i+face_resolution+1
					tri_index += 6
	for a in range(0, len(index_array), 3):
		var b : int = a + 1
		var c : int = a + 2
		var ab : Vector3 = vertex_array[index_array[b]] - vertex_array[index_array[a]]
		var bc : Vector3 = vertex_array[index_array[c]] - vertex_array[index_array[b]]
		var ca : Vector3 = vertex_array[index_array[a]] - vertex_array[index_array[c]]
		var cross_bc_ab : Vector3 = bc.cross(ab)
		var cross_ca_bc : Vector3 = ca.cross(bc)
		var cross_ab_ca : Vector3 = ab.cross(ca)
		var cross_sum : Vector3 = cross_bc_ab + cross_ca_bc + cross_ab_ca
		normal_array[index_array[a]] += cross_sum
		normal_array[index_array[b]] += cross_sum
		normal_array[index_array[c]] += cross_sum
	# normalize the normals
	for i in range(normal_array.size()):
		normal_array[i] = normal_array[i].normalized()
		
	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_TEX_UV] = uv_array
	arrays[Mesh.ARRAY_INDEX] = index_array

	call_deferred("_update_mesh", arrays)
	
func _update_mesh(arrays : Array):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = _mesh
