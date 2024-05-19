@tool
extends MeshInstance3D


@export var ship_bottom : float = 2.4: # height of lander base above ground
	set(value):
		ship_bottom = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var lower_deck_height : float = 1.5: # distance from ship_bottom to the floor
	set(value):
		lower_deck_height = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var ship_top_deck_height : float = 1.6: # floor to top of ship
	set(value):
		ship_top_deck_height = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var pressure_hull_thickness : float = 0.05: #
	set(value):
		pressure_hull_thickness = value
		if Engine.is_editor_hint():
			_rebuild_model()
 
@export var ship_width : float = 3.2: # octagon side-to-side
	set(value):
		ship_width = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var ship_front_width : float = 1.4: # width of forward octagon face
	set(value):
		ship_front_width = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var turret_height : float = 0.5:
	set(value):
		turret_height = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cockpit_window_width : float = 1.0:
	set(value):
		cockpit_window_width = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cockpit_top_window_depth : float = 0.5:
	set(value):
		cockpit_top_window_depth = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cockpit_window_bumpout_width : float = 0.6:
	set(value):
		cockpit_window_bumpout_width = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cockpit_window_front_bumpout_depth : float = 0.4:
	set(value):
		cockpit_window_front_bumpout_depth = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cockpit_window_top_bumpout_depth : float = 0.4:
	set(value):
		cockpit_window_top_bumpout_depth = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cabin_width_overall : float = 1.4:
	set(value):
		cabin_width_overall = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var cabin_depth_overall : float = 3.0:
	set(value):
		cabin_depth_overall = value
		if Engine.is_editor_hint():
			_rebuild_model()


# derived quantities
var turret_width : float
var turret_front_width : float
var A_ : Vector3 # top of turret, y-coordinate
var B_ : Vector3 # bottom of turret or top of deck, y-coordinate
var C_ : Vector3 # ceiling, y-coordinate
var D_ : Vector3 # floor, y-coordinate
var E_ : Vector3 # base of ship
# turret XZ coordinates, clockwise from front
var _E : Vector3
var _F : Vector3
var _G : Vector3
var _H : Vector3
var _A : Vector3
var _B : Vector3
var _C : Vector3
var _D : Vector3
# turret top coordinates, clockwise from front
var AE : Vector3
var AF : Vector3
var AG : Vector3
var AH : Vector3
var AA : Vector3
var AB : Vector3
var AC : Vector3
var AD : Vector3
# turret base coordinates
var BE : Vector3
var BF : Vector3
var BG : Vector3
var BH : Vector3
var BA : Vector3
var BB : Vector3
var BC : Vector3
var BD : Vector3
# top deck coordinates
var _I : Vector3
var _J : Vector3
var _K : Vector3
var _L : Vector3
var _M : Vector3
var _N : Vector3
var _O : Vector3
var _P : Vector3
var _Q : Vector3
var _R : Vector3
var _S : Vector3
var _T : Vector3

# top deck
var BI : Vector3
var BJ : Vector3
var BK : Vector3
var BL : Vector3
var BM : Vector3
var BN : Vector3
var BO : Vector3
var BP : Vector3
var BQ : Vector3
var BR : Vector3
var BS : Vector3
var BT : Vector3

# interior
var _W : Vector3
var _V : Vector3
var _U : Vector3
var _Z : Vector3
var _Y : Vector3
var _X : Vector3

# floor
var DP : Vector3
var DM : Vector3
var DZ : Vector3
var DU : Vector3
var DV : Vector3
var DW : Vector3
var DX : Vector3
var DY : Vector3
# ceiling
var CW : Vector3
var CV : Vector3
var CU : Vector3
var CZ : Vector3
var CN : Vector3
var CO : Vector3
var CY : Vector3
var CX : Vector3

# bottom deck
var EI : Vector3
var EL : Vector3
var EQ : Vector3
var ET : Vector3
var EJ : Vector3
var EK : Vector3
var ER : Vector3
var ES : Vector3


# add arbitrary flat surface, with triangles predetermined
func _add_flat_surface(va, ta, normal_vector : Vector3):
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	#######################################
	## Insert code here to generate mesh ##
	for v in va:
		verts.append(v)
		normals.append(normal_vector.normalized())
		if normal_vector == Vector3.UP:
			uvs.append(Vector2(v.z-va[0].z, -v.x+va[0].x))
		elif normal_vector == Vector3.DOWN:
			uvs.append(Vector2(-v.z+va[0].z, -v.x+va[0].x))
		else:
			uvs.append(Vector2(sqrt((v.x-va[0].x)**2 + (v.z-va[0].z)**2), va[0].y-v.y))
	for t in ta:
		indices.append(t[0])
		indices.append(t[1])
		indices.append(t[2])
	#######################################

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

func _compute_turret_coordinates():
	# calculate coordinates of turret top
	turret_width = ship_width - 2.0*cockpit_top_window_depth
	turret_front_width = cockpit_window_width + pressure_hull_thickness*2.0
	_E = Vector3(turret_width/2.0, 0.0, turret_front_width/2.0)
	_F = Vector3(turret_front_width/2.0, 0.0, turret_width/2.0)
	_G = Vector3(-turret_front_width/2.0, 0.0, turret_width/2.0)
	_H = Vector3(-turret_width/2.0, 0.0, turret_front_width/2.0)
	_A = Vector3(-turret_width/2.0, 0.0, -turret_front_width/2.0)
	_B = Vector3(-turret_front_width/2.0, 0.0, -turret_width/2.0)
	_C = Vector3(turret_front_width/2.0, 0.0, -turret_width/2.0)
	_D = Vector3(turret_width/2.0, 0.0, -turret_front_width/2.0)
	AE = A_ + _E
	AF = A_ + _F
	AG = A_ + _G
	AH = A_ + _H
	AA = A_ + _A
	AB = A_ + _B
	AC = A_ + _C
	AD = A_ + _D
	# coordinates of turret base
	BE = B_ + _E
	BF = B_ + _F
	BG = B_ + _G
	BH = B_ + _H
	BA = B_ + _A
	BB = B_ + _B
	BC = B_ + _C
	BD = B_ + _D

func _compute_body_coordinates():
	# XZ coordinates of ship outline
	_I = Vector3(-ship_width/2.0, 0.0, -ship_front_width/2.0)
	_L = Vector3(ship_width/2.0, 0.0, -ship_front_width/2.0)
	_Q = Vector3(ship_width/2.0, 0.0, ship_front_width/2.0)
	_T = Vector3(-ship_width/2.0, 0.0, ship_front_width/2.0)
	_J = Vector3(-ship_front_width/2.0, 0.0, -ship_width/2.0)
	_K = Vector3(ship_front_width/2.0, 0.0, -ship_width/2.0)
	_R = Vector3(ship_front_width/2.0, 0.0, ship_width/2.0)
	_S = Vector3(-ship_front_width/2.0, 0.0, ship_width/2.0)
	# cutout for cockpit
	_N = Vector3(ship_width/2.0 - cockpit_top_window_depth, 0.0, -cockpit_window_width/2.0)
	_O = Vector3(ship_width/2.0 - cockpit_top_window_depth, 0.0, cockpit_window_width/2.0)
	_M = Vector3(ship_width/2.0, 0.0, -cockpit_window_width/2.0)
	_P = Vector3(ship_width/2.0, 0.0, cockpit_window_width/2.0)
	# top deck
	BI = B_ + _I
	BL = B_ + _L
	BQ = B_ + _Q
	BT = B_ + _T
	BJ = B_ + _J
	BK = B_ + _K
	BR = B_ + _R
	BS = B_ + _S
	# cutout for cockpit
	BN = B_ + _N
	BO = B_ + _O
	BM = B_ + _M
	BP = B_ + _P
	# front face
	DP = D_ + _P
	DM = D_ + _M
	# bottom deck
	EI = E_ + _I
	EL = E_ + _L
	EQ = E_ + _Q
	ET = E_ + _T
	EJ = E_ + _J
	EK = E_ + _K
	ER = E_ + _R
	ES = E_ + _S
	
func _compute_cabin_coordinates():
	_W = Vector3(ship_width/2.0-cabin_depth_overall, 0.0, cabin_width_overall/2.0)
	_V = Vector3(ship_width/2.0-cabin_depth_overall, 0.0, -cabin_width_overall/2.0)
	_U = Vector3(ship_width/2.0-pressure_hull_thickness, 0.0, -cabin_width_overall/2.0)
	_Z = Vector3(ship_width/2.0-pressure_hull_thickness, 0.0, -cockpit_window_width/2.0)
	_Y = Vector3(ship_width/2.0-pressure_hull_thickness, 0.0, cockpit_window_width/2.0)
	_X = Vector3(ship_width/2.0-pressure_hull_thickness, 0.0, cabin_width_overall/2.0)
	# ceiling
	CW = C_ + _W
	CV = C_ + _V
	CU = C_ + _U
	CZ = C_ + _Z
	CN = C_ + _N
	CO = C_ + _O
	CY = C_ + _Y
	CX = C_ + _X
	# floor
	DW = D_ + _W
	DV = D_ + _V
	DU = D_ + _U
	DZ = D_ + _Z
	DY = D_ + _Y
	DX = D_ + _X

func _build_cabin():
	_compute_cabin_coordinates()
	# ceiling
	_add_flat_surface(
		[CW,CV,CU,CZ,CN,CO,CY,CX],
		[[0,5,1],[5,4,1],[4,2,1],[4,3,2],[5,7,6],[7,5,0]],
		Vector3.DOWN)
	# floor
	_add_flat_surface(
		[DW,DV,DU,DZ,DM,DP,DY,DX],
		[[0,1,3],[1,2,3],[3,4,5],[3,5,6],[3,6,0],[6,7,0]],
		Vector3.UP
	)
	# right window edge
	_add_flat_surface([BP,BO,CO,CY,DY,DP],[[0,1,3],[1,2,3],[3,4,5],[3,5,0]],Vector3.BACK)
	# left window edge
	_add_flat_surface([DM,DZ,CZ,CN,BN,BM],[[0,1,2],[2,3,4],[4,5,2],[5,0,2]],Vector3.FORWARD)
	# rear window edge
	_add_flat_surface([BO,BN,CN,CO], [[0,1,3],[1,2,3]], Vector3.RIGHT)
	# rear cabin wall
	_add_flat_surface([CW,CV,DV,DW], [[0,1,3],[1,2,3]], Vector3.RIGHT)
	# right cabin wall
	_add_flat_surface([CX,CW,DW,DX], [[0,1,3],[1,2,3]], Vector3.FORWARD)
	# left cabin wall
	_add_flat_surface([CV,CU,DU,DV], [[0,1,3],[1,2,3]], Vector3.BACK)
	# right front cabin wall
	_add_flat_surface([CY,CX,DX,DY], [[0,1,3],[1,2,3]], Vector3.LEFT)
	# left front cabin wall
	_add_flat_surface([CU,CZ,DZ,DU], [[0,1,3],[1,2,3]], Vector3.LEFT)
	
	
func _build_body():
	_compute_body_coordinates()
	_add_flat_surface(
		[BI,BJ,BK,BL,BM,BN,BO,BP,BQ,BR,BS,BT],
		[[0,1,5],[1,2,5],[2,3,5],[3,4,5],[5,6,0],[6,11,0],[6,10,11],[6,9,10],[6,8,9],[6,7,8]],
		Vector3.UP
	)
	_add_flat_surface(
		[EQ,EL,EK,EJ,EI,ET,ES,ER],
		[[0,1,7],[1,2,3],[3,4,5],[5,6,7],[7,1,5],[1,3,5]],
		Vector3.DOWN
	)
	_add_flat_surface([BM,BL,EL,EQ,BQ,BP,DP,DM], [[0,1,7],[1,2,7],[2,6,7],[2,3,6],[3,4,6],[4,5,6]], Vector3.RIGHT)
	_add_flat_surface([BL,BK,EK,EL], [[0,1,3],[1,2,3]], Vector3(1.0,0.0,-1.0))
	_add_flat_surface([BK,BJ,EJ,EK], [[0,1,3],[1,2,3]], Vector3.FORWARD)
	_add_flat_surface([BR,BQ,EQ,ER], [[0,1,3],[1,2,3]], Vector3(1.0,0.0,1.0))
	_add_flat_surface([BS,BR,ER,ES], [[0,1,3],[1,2,3]], Vector3.BACK)
	_add_flat_surface([BT,BS,ES,ET], [[0,1,3],[1,2,3]], Vector3(-1.0,0.0,1.0))
	_add_flat_surface([BI,BT,ET,EI], [[0,1,3],[1,2,3]], Vector3.LEFT)
	_add_flat_surface([BJ,BI,EI,EJ], [[0,1,3],[1,2,3]], Vector3(-1.0,0.0,-1.0))
	

func _build_turret():
	_compute_turret_coordinates()
	_add_flat_surface(
		[AE, AF, AG, AH, AA, AB, AC, AD],
		[[0, 1, 2], [2, 3, 4], [0, 2, 4], [4, 5, 6], [4, 6, 0], [6, 7, 0]],
		Vector3.UP
	)
	_add_flat_surface([AB,AA,BA,BB],[[0,1,3],[1,2,3]], Vector3(-1.0, 0.0, -1.0))
	_add_flat_surface([AC,AB,BB,BC], [[0,1,3],[1,2,3]], Vector3.FORWARD)
	_add_flat_surface([AD,AC,BC,BD],[[0,1,3],[1,2,3]], Vector3(1.0, 0.0, -1.0))
	_add_flat_surface([AE,AD,BD,BE],[[0,1,3],[1,2,3]], Vector3.RIGHT)
	_add_flat_surface([AF,AE,BE,BF],[[0,1,3],[1,2,3]], Vector3(1.0, 0.0, 1.0))
	_add_flat_surface([AG,AF,BF,BG],[[0,1,3],[1,2,3]], Vector3.BACK)
	_add_flat_surface([AH,AG,BG,BH],[[0,1,3],[1,2,3]], Vector3(-1.0, 0.0, 1.0))
	_add_flat_surface([AA,AH,BH,BA],[[0,1,3],[1,2,3]], Vector3.LEFT)

func _compute_derived_parameters():
	# calculate y-coordinates at levels from bottom to top:
	E_ = Vector3(0.0, ship_bottom, 0.0)
	D_ = E_ + Vector3(0.0, lower_deck_height, 0.0)
	C_ = D_ + Vector3(0.0, ship_top_deck_height - pressure_hull_thickness, 0.0)
	B_ = D_ + Vector3(0.0, ship_top_deck_height, 0.0)
	A_ = B_ + Vector3(0.0, turret_height, 0.0)
	_build_turret()
	_build_body()
	_build_cabin()
	

func _build_mesh():
	_compute_derived_parameters()

func _ready():
	_build_mesh()

func _rebuild_model():
	mesh.clear_surfaces()
	_build_mesh()
