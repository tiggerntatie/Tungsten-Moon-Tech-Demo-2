extends MeshInstance3D

@onready var PAD : MeshInstance3D = $"../PadSurface"
const BURIED_LENGTH := 10.0	# nominal length of pedestal buried beneath ground

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh.top_radius = PAD.mesh.top_radius/4
	mesh.bottom_radius = mesh.top_radius

func set_pedestal_height(altitude_adjust: float)-> void:
	mesh.height = altitude_adjust + BURIED_LENGTH
	position = Vector3(0.0, -mesh.height/2.0, 0.0)
