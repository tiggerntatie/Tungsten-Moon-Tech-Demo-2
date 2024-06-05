extends TerrainObject

@export_category("Landing Pad Features")

## List of pointers to other pads of interest
@export var other_pads_array: Array[TerrainObject]

var beacon_on : bool = false
const unvisited_beacon_color := Color("red")
const visited_beacon_color := Color("green")
var visited = false

func _on_terrain_object_moved(identifier : String, lon: float, lat: float):
	for pad in other_pads_array:
		if pad.identifier == identifier:
			$StaticBody3D/OtherPadsLabel.set_pads(moon_data, latitude, longitude, other_pads_array)

func _on_spacecraft_landed():
	if (visible and 
		not visited and 
		global_position.length()/scale.x < $StaticBody3D/PadSurface.mesh.top_radius * 1.5):
			
		visited = true
		_on_check_visited()
		
func _on_check_visited():
	if visited:
		$StaticBody3D/Beacon.get_surface_override_material(0).emission = visited_beacon_color
		$StaticBody3D/BeaconSpot.light_color = visited_beacon_color
		

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	Signals.connect("terrain_object_moved", _on_terrain_object_moved)
	Signals.connect("Spacecraft_landed", _on_spacecraft_landed)
	$StaticBody3D/Pedestal.set_pedestal_height(altitude_adjust)
	$StaticBody3D.position.y = altitude_adjust
	$StaticBody3D/PositionLabel.set_position_text(identifier, longitude, latitude)
	$StaticBody3D/OtherPadsLabel.set_pads(moon_data, latitude, longitude, other_pads_array)
	$StaticBody3D/Beacon.get_surface_override_material(0).emission = unvisited_beacon_color
	$StaticBody3D/BeaconSpot.light_color = unvisited_beacon_color
	start_beacon_timer()

# periodically update the object position and make visible if necessary
func start_beacon_timer():
	var scene := get_tree()
	if scene != null:
		var timer := scene.create_timer(0.75)
		timer.timeout.connect(_on_beacon_timer_timeout)
	
func _on_beacon_timer_timeout():
	if visible:
		beacon_on = not beacon_on
		$StaticBody3D/Beacon.get_surface_override_material(0).emission_enabled = beacon_on
		$StaticBody3D/BeaconSpot.visible = beacon_on
	start_beacon_timer()
