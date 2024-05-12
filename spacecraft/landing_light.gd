extends SpotLight3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("ButtonLight_changed", _on_landing_light_button_changed)

func _on_landing_light_button_changed(state, lightstate):
	visible = state
