extends SpotLight3D

@onready var default_landing_light_range : float = spot_range

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("ButtonLight_changed", _on_landing_light_button_changed)
	Signals.connect("moon_scale_changed", _on_moon_scale_changed)

func _on_landing_light_button_changed(state, lightstate):
	visible = state

func _on_moon_scale_changed(scale_factor: float) -> void:
	spot_range = default_landing_light_range / scale_factor
