@tool
extends Node3D

@export var state : bool = false:
	set(value):
		state = value
		$MeshInstance3D.material_override.emission_enabled = state
