@tool
extends Node3D

@export var moon_data : MoonData:
	set(val):
		moon_data = val
		on_data_changed()
		if moon_data != null and not moon_data.is_connected("changed", self.on_data_changed):
			moon_data.connect("changed", self.on_data_changed)
			
func _ready():
	on_data_changed()

func on_data_changed():
	for child in get_children():
		var mesh := child as MoonMeshFace
		mesh.regenerate_mesh(moon_data)
