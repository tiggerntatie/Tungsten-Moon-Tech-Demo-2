@tool
extends MeshInstance3D

@onready var state : bool = false:
	set(value):
		state = value
		if not Engine.is_editor_hint():
			material_override.emission_enabled = state
