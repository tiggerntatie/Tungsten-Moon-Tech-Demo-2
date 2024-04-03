@tool
extends Node3D
class_name MoonSmartFace

@export var face_normal : Vector3 = Vector3.ZERO
@onready var SMOON = "$.."
const MESH_PATH := "res://smart_moon/mesh_resources/"

func _ready():
	pass

func resource_file_name(res_power : int, chunk_res_power : int, res_type: String, x : int, y : int) -> String:
	return MESH_PATH + res_type + "_" + str(face_normal.x) + str(face_normal.y) + str(face_normal.z) + "_" + str(res_power) + "_" + str(chunk_res_power) + "_" + str(x) + "_" + str(y) + ".res"

# This function will generate meshes for a single cubic "face" of a sphere. Each face is divided into
# a 2^resolution_power x 2^resolution_power grid of independent meshes. Meshes, once generated,
# are saved to disk as resources. These will be loaded quickly in future runs.
func generate_meshes(moon_data : MoonData, resolution_power : int, chunk_resolution_power : int):
	var radius = moon_data.radius	# radius in km
	var resolution := pow(2, resolution_power)
	var chunk_resolution := pow(2, chunk_resolution_power)
	position = face_normal * radius
	# remove old meshes
	_clean_out_meshes()
	# generate normal vectors unit length, in the face plane
	var va := Vector3(position.y, position.z, position.x)
	var vb := face_normal.cross(va)
	for y in range(resolution):
		for x in range(resolution):
			var resource_path = resource_file_name(resolution_power, chunk_resolution_power, "mesh", x, y)
			var collision_res_path = resource_file_name(resolution_power, chunk_resolution_power, "coll", x, y)
			var chunk := MeshInstance3D.new()
			chunk.material_override = get_parent_node_3d().material_override
			chunk.set_layer_mask_value(1, true)	#lit by sun and planet
			chunk.set_layer_mask_value(2, true)	
			add_child(chunk)
			chunk.position = ((x+0.5)/resolution - 0.5)*2*va +  ((y+0.5)/resolution - 0.5)*2*vb
			if ResourceLoader.exists(resource_path) and ResourceLoader.exists(collision_res_path): 
				call_deferred("_load_mesh", chunk, resource_path, collision_res_path)
			else:
				# local, face-relative osition of each chunk
				generate_chunk_mesh(chunk, moon_data, 2*va/resolution, 2*vb/resolution, chunk_resolution, resource_path, collision_res_path)
	
# Note: we will actually build a mesh that is larger than requested, but only generate triangles in the desired mesh
# This function is much more complicated than typical examples because it is one mesh that will fit with its neighbors. The problem is 
# ensuring that edge vertex normals match where two meshes come together. If they don't match, the seams between meshes become quite 
# obvious. To make this work, calculations are done for a larger mesh, then only a smaller subset of that is used to generate the visible
# mesh!
func generate_chunk_mesh(chunk : MeshInstance3D, moon_data : MoonData, va : Vector3, vb : Vector3, resolution : int, path : String, collpath : String):
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var radius = moon_data.radius	
	var vertex_resolution := resolution + 1
	var expand_resolution := resolution + 2
	var expand_vertex_resolution := vertex_resolution + 2
	var expand_vertex_qty : int = pow(expand_vertex_resolution, 2)
	var square_qty : int = pow(resolution, 2)
	var expand_square_qty : int = pow(resolution+2, 2)
	var vertex_array := PackedVector3Array()
	var uv_array := PackedVector2Array()
	var normal_array := PackedVector3Array()
	var index_array := PackedInt32Array()
	var expand_index_array := PackedInt32Array()
	var visibles := Dictionary()
	normal_array.resize(expand_vertex_qty)
	uv_array.resize(expand_vertex_qty)
	vertex_array.resize(expand_vertex_qty)
	index_array.resize(square_qty*6)
	expand_index_array.resize(expand_square_qty*6)
	var expand_tri_index : int = 0
	for y in range(expand_vertex_resolution):
		for x in range(expand_vertex_resolution):
			var i : int = x + y * expand_vertex_resolution
			var percent : Vector2 = (Vector2(x, y) - Vector2.ONE) / resolution 
			var point_on_face : Vector3 = (percent.x-0.5)*va + (percent.y-0.5)*vb 
			var point_on_unit_sphere := (point_on_face+chunk.position+face_normal*radius).normalized()
			var point_on_moon := moon_data.point_on_moon(point_on_unit_sphere) 
			var point_in_local_frame : Vector3 = point_on_moon - chunk.position - face_normal*radius
			vertex_array[i] = point_in_local_frame
			uv_array[i] = Vector2(percent.x, percent.y)
			# note if this vertex will be visible in this chunk
			if x > 0 and y > 0 and x < expand_vertex_resolution-1 and y < expand_vertex_resolution-1:
				visibles[i] = true
			# assemble all triangles
			if x != expand_resolution and y != expand_resolution:
				expand_index_array[expand_tri_index+2] = i
				expand_index_array[expand_tri_index+1] = i+expand_vertex_resolution+1
				expand_index_array[expand_tri_index] = i+expand_vertex_resolution
			
				expand_index_array[expand_tri_index+5] = i
				expand_index_array[expand_tri_index+4] = i+1
				expand_index_array[expand_tri_index+3] = i+expand_vertex_resolution+1
				expand_tri_index += 6
	# generate vertex normals
	for a in range(0, len(expand_index_array), 3):			
		var b : int = a + 1
		var c : int = a + 2
		var ab : Vector3 = vertex_array[expand_index_array[b]] - vertex_array[expand_index_array[a]]
		var bc : Vector3 = vertex_array[expand_index_array[c]] - vertex_array[expand_index_array[b]]
		var ca : Vector3 = vertex_array[expand_index_array[a]] - vertex_array[expand_index_array[c]]
		var cross_bc_ab : Vector3 = bc.cross(ab)
		var cross_ca_bc : Vector3 = ca.cross(bc)
		var cross_ab_ca : Vector3 = ab.cross(ca)
		var cross_sum : Vector3 = cross_bc_ab + cross_ca_bc + cross_ab_ca
		normal_array[expand_index_array[a]] += cross_sum
		normal_array[expand_index_array[b]] += cross_sum
		normal_array[expand_index_array[c]] += cross_sum
	# normalize the normals
	for i in range(normal_array.size()):
		normal_array[i] = normal_array[i].normalized()
	# filter expand_index_array triangles into index_array
	var tri_index : int = 0
	for a in range(0, len(expand_index_array),3):
		var b : int = a + 1
		var c : int = a + 2
		if visibles.has(expand_index_array[a]) and visibles.has(expand_index_array[b]) and visibles.has(expand_index_array[c]):
			index_array[tri_index] = expand_index_array[a]
			index_array[tri_index+1] = expand_index_array[b]
			index_array[tri_index+2] = expand_index_array[c]
			tri_index += 3
	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_TEX_UV] = uv_array
	arrays[Mesh.ARRAY_INDEX] = index_array

	call_deferred("_update_mesh", arrays, chunk, path, collpath)

# clear out old meshes
func _clean_out_meshes():
	for child in get_children():
		child.queue_free()
		
# switch over carefully.. 
func _update_mesh(arrays : Array, chunk : MeshInstance3D, path : String, collpath : String):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh.take_over_path(path)
	ResourceSaver.save(_mesh, path)
	chunk.set_mesh(_mesh)
	#chunk.create_multiple_convex_collisions() # trimesh uses few resources, but doesn't work correctly
	chunk.create_trimesh_collision()
	var coll = chunk.get_child(0).get_child(0).get_shape()	# retrieve staticbody/collision shape
	coll.take_over_path(collpath)
	ResourceSaver.save(coll, collpath)

# load a mesh ressource
func _load_mesh(chunk : MeshInstance3D, path : String, collpath : String):
	var _mesh : ArrayMesh = ResourceLoader.load(path)
	chunk.set_mesh(_mesh)
	var staticbody = StaticBody3D.new()
	var collshape = CollisionShape3D.new()
	staticbody.add_child(collshape)
	var shape : Shape3D = ResourceLoader.load(collpath)
	collshape.set_shape(shape)
	chunk.add_child(staticbody)

