extends SpotLight3D


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = $"../LandingLightButton".get_button()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_landing_light_pressed(state):
	visible = state
