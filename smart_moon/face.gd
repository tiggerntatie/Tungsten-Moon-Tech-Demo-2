@tool
extends Node3D
class_name MoonSmartFace

@export var face_normal : Vector3 = Vector3.ZERO
@onready var SMOON = "$.."
const MESH_PATH := "res://smart_moon/mesh_resources/"

func _ready():
	pass

func resource_file_name(res_power : int, chunk_res_power : int, x : int, y : int) -> String:
	return MESH_PATH + "mesh_" + str(face_normal.x) + str(face_normal.y) + str(face_normal.z) + "_" + str(res_power) + "_" + str(chunk_res_power) + "_" + str(x) + "_" + str(y) + ".res"

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
			var resource_path = resource_file_name(resolution_power, chunk_resolution_power, x, y)
			var chunk := MeshInstance3D.new()
			add_child(chunk)
			chunk.position = ((x+0.5)/resolution - 0.5)*2*va +  ((y+0.5)/resolution - 0.5)*2*vb
			if ResourceLoader.exists(resource_path):
				call_deferred("_load_mesh", chunk, resource_path)
			else:
				# local, face-relative osition of each chunk
				generate_chunk_mesh(chunk, moon_data, 2*va/resolution, 2*vb/resolution, chunk_resolution, resource_path)
	

func generate_chunk_mesh(chunk : MeshInstance3D, moon_data : MoonData, va : Vector3, vb : Vector3, resolution : int, path : String):
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var radius = moon_data.radius	
	var vertex_resolution := resolution + 1
	var vertex_qty : int = pow(vertex_resolution, 2)
	var square_qty : int = pow(resolution, 2)
	var vertex_array := PackedVector3Array()
	var uv_array := PackedVector2Array()
	var normal_array := PackedVector3Array()
	var index_array := PackedInt32Array()
	normal_array.resize(vertex_qty)
	uv_array.resize(vertex_qty)
	vertex_array.resize(vertex_qty)
	index_array.resize(square_qty*6)
	var tri_index : int = 0
	for y in range(vertex_resolution):
		for x in range(vertex_resolution):
			var i : int = x + y * vertex_resolution
			var percent : Vector2 = Vector2(x, y) / resolution
			var point_on_face : Vector3 = (percent.x-0.5)*va + (percent.y-0.5)*vb 
			var point_on_unit_sphere := (point_on_face+chunk.position+face_normal*radius).normalized()
			var point_on_moon := moon_data.point_on_moon(point_on_unit_sphere) 
			var point_in_local_frame : Vector3 = point_on_moon - chunk.position - face_normal*radius
			vertex_array[i] = point_in_local_frame
			uv_array[i] = Vector2(percent.x, percent.y)
			if x != resolution and y != resolution:
				index_array[tri_index+2] = i
				index_array[tri_index+1] = i+vertex_resolution+1
				index_array[tri_index] = i+vertex_resolution
			
				index_array[tri_index+5] = i
				index_array[tri_index+4] = i+1
				index_array[tri_index+3] = i+vertex_resolution+1
				tri_index += 6
	# generate vertex normals
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

	call_deferred("_update_mesh", arrays, chunk, path)

# clear out old meshes
func _clean_out_meshes():
	for child in get_children():
		child.queue_free()
		
# switch over carefully.. 
func _update_mesh(arrays : Array, chunk : MeshInstance3D, path : String):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh.take_over_path(path)
	ResourceSaver.save(_mesh, path)
	chunk.set_mesh(_mesh)
	chunk.create_multiple_convex_collisions()

# load a mesh ressource
func _load_mesh(chunk : MeshInstance3D, path : String):
	var _mesh : ArrayMesh = ResourceLoader.load(path)
	chunk.set_mesh(_mesh)
	chunk.create_multiple_convex_collisions()
