@tool
extends Node3D

@onready var segment_list : Array = [
	$DisplaySegmentA,	# 0
	$DisplaySegmentB,	# 1
	$DisplaySegmentC,	# 2
	$DisplaySegmentD,	# 3
	$DisplaySegmentE,	# 4
	$DisplaySegmentF,	# 5
	$DisplaySegmentG,	# 6
	$DisplaySegmentDP,	# 7
]

# on, then off segments
@onready var digit_map : Array = [
	[[0, 1, 2, 3, 4, 5], [6]],	# 0
	[[1, 2], [0, 3, 4, 5, 6]],	# 1
	[[0, 1, 3, 4, 6], [2, 5]],	# 2
	[[0, 1, 2, 3, 6], [4, 5]],	# 3
	[[1, 2, 5, 6], [0, 3, 4]],	# 4
	[[0, 2, 3, 5, 6], [1, 4]],	# 6
	[[0, 1, 2, 5], [3, 4, 6]],	# 7
	[[0, 1, 2, 3, 4, 5, 6], []],	# 8
	[[0, 1, 2, 3, 5, 6], [4]],	# 9
]

@export_range(0, 9, 1) var digit : int = 0:
	set(value):
		digit = value
		_update_segments()
		
@export var dp : bool = false:
	set(value):
		dp = value
		_update_segments()

func _update_segments():
	# on segments
	for n in digit_map[digit][0]:
		segment_list[n].state = true
	# off segments
	for n in digit_map[digit][1]:
		segment_list[n].state = false
	digit_map[7].material_override.emission_enabled = dp

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_segments()

