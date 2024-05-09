@tool
extends Node3D

const PHYSICAL_FULL_SCALE := 0.03736
const PHYSICAL_OFF_SCALE := 0.04067
const DATA_TIMEOUT := 1.0
const MAX_SLEW_RATE := 1.0	# in units / per second

# cross pointer in physical units
var xy_command := Vector2(0.0, 0.0)

# cross pointer position, normalized to +/- 1
var xy_position := Vector2(0.0, 0.0)

# currently selected scale x1 = 1, x10 = 10, etc..
var display_scale : float = 1.0

var xy_cmd_normalized := Vector2.ZERO

# radar online
var radar_online : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$PanelRadioButton.set_radio_button("x1")
	
# called periodically so we can slew the pointers
func _process(delta):
	if radar_online:
		var slew : Vector2 = xy_cmd_normalized - xy_position
		slew.x = clamp(slew.x, -MAX_SLEW_RATE, MAX_SLEW_RATE) * delta
		slew.y = clamp(slew.y, -MAX_SLEW_RATE, MAX_SLEW_RATE) * delta
		xy_position += Vector2(slew.x, slew.y)
	else:		
		xy_position = Vector2(1.0001, 1.0001)
	if abs(xy_position.x) > 1.0:
		xy_position.x = sign(xy_position.x) * 1.0001	# clamp our internal state, too
		$XAxisBar.position.x = sign(xy_position.x) * PHYSICAL_OFF_SCALE
	else:
		$XAxisBar.position.x = xy_position.x * PHYSICAL_FULL_SCALE
	if abs(xy_position.y) > 1.0:
		xy_position.y = sign(xy_position.y) * 1.0001	# clamp our internal state, too
		$YAxisBar.position.y = sign(xy_position.y) * PHYSICAL_OFF_SCALE
	else:
		$YAxisBar.position.y = xy_position.y * PHYSICAL_FULL_SCALE
	
func _start_timer():
	$DataLED.get_surface_override_material(0).emission_enabled = false
	radar_online = true
	$Timer.start(DATA_TIMEOUT)
	
func _on_timer_timeout():
	$DataLED.get_surface_override_material(0).emission_enabled = true
	radar_online = false
	xy_position = Vector2(1.1, 1.1)
 
func _normalize_command():
	xy_cmd_normalized = xy_command / display_scale	

func _on_radio_button_pressed(legend):
	display_scale = float(legend.lstrip('xX'))
	_normalize_command()

func _on_spacecraft_drift_changed(drift):
	xy_command = drift
	_normalize_command()
	if not $Timer.is_stopped():
		$Timer.stop()
	_start_timer()			
