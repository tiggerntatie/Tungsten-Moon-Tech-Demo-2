@tool
extends MeshInstance3D

@export var state : bool = false:
	set(value):
		state = value
		material_override.emission_enabled = state
