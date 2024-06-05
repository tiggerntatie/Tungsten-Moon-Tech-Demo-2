extends TerrainObject

@export_category("Landing Pad Features")

## List of pointers to other pads of interest
@export var other_pads_array: Array[TerrainObject]

func _on_terrain_object_moved(identifier : String, lon: float, lat: float):
	for pad in other_pads_array:
		if pad.identifier == identifier:
			$StaticBody3D/OtherPadsLabel.set_pads(moon_data, latitude, longitude, other_pads_array)

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	Signals.connect("terrain_object_moved", _on_terrain_object_moved)
	$StaticBody3D/Pedestal.set_pedestal_height(altitude_adjust)
	$StaticBody3D.position.y = altitude_adjust
	$StaticBody3D/PositionLabel.set_position_text(identifier, longitude, latitude)
	$StaticBody3D/OtherPadsLabel.set_pads(moon_data, latitude, longitude, other_pads_array)
