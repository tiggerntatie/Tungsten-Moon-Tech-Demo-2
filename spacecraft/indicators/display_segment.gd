@tool
extends Node3D

@export var state : bool = false:
	set(value):
		state = value
		if not Engine.is_editor_hint():
			$MeshInstance3D.material_override.emission_enabled = state
