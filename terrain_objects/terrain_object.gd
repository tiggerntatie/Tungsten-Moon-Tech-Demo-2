extends Node3D

class_name TerrainObject

@export var moon_data : MoonData

## Latitude of the object in degrees
@export var latitude : float

## Longitude of the object in degrees
@export var longitude : float

## Heading of the object in degrees
@export var heading : float

func _on_moon_position_changed(dv_position : DVector3):
	print(dv_position.to_string())

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("moon_position_changed", _on_moon_position_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
