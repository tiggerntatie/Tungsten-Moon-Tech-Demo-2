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

@export var cockpit_window_frame_width : float = 0.03:
	set(value):
		cockpit_window_frame_width = value
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

@export var exterior_material : StandardMaterial3D:
	set(value):
		exterior_material = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var interior_material : StandardMaterial3D:
	set(value):
		interior_material = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var gasket_material : StandardMaterial3D:
	set(value):
		gasket_material = value
		if Engine.is_editor_hint():
			_rebuild_model()

@export var window_material : StandardMaterial3D:
	set(value):
		window_material = value
		if Engine.is_editor_hint():
			_rebuild_model()

const cockpit_glass_thickness := 0.005	
const cockpit_frame_thickness := 0.03

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

# inner window frame vertices
var WA : Vector3
var WB : Vector3
var WC : Vector3
var WD : Vector3
var WE : Vector3
var WF : Vector3
var WG : Vector3
var WH : Vector3
var WI : Vector3
var WJ : Vector3
var WK : Vector3
var WL : Vector3
var WM : Vector3
var WN : Vector3
var WO : Vector3
var WP : Vector3



# add arbitrary flat surface, with triangles predetermined
func _add_flat_surface(va, ta, normal_vector : Vector3, material : StandardMaterial3D):
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
	var idx := mesh.get_surface_count() - 1
	mesh.surface_set_material(idx, material)

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

func _compute_window_coordinates():
	# z-coordinate for left and right side
	var _WL = Vector3(0.0, 0.0, -cockpit_window_bumpout_width/2.0)
	var _WR = Vector3(0.0, 0.0, cockpit_window_bumpout_width/2.0)
	# y-coordinate for the top 
	var _WT = B_ + Vector3(0.0, cockpit_window_top_bumpout_depth, 0.0)
	# x-coordinate for the front bumpout
	var _WF = Vector3(BP.x + cockpit_window_front_bumpout_depth, 0.0, 0.0)
	# set coordinates of all interior joints
	WA = _WR + _WT + Vector3(BO.x, 0.0, 0.0)
	WB = _WL + _WT + Vector3(BO.x, 0.0, 0.0)
	WC = _WR + _WT + Vector3(BP.x, 0.0, 0.0)
	WD = _WL + _WT + Vector3(BP.x, 0.0, 0.0)
	WE = _WR + B_ + _WF
	WF = _WL + B_ + _WF
	var front_pane_height = (BP.y - DP.y - cockpit_window_front_bumpout_depth)/2.0
	WI = Vector3(BP.x, BP.y-front_pane_height,BP.z)
	WG = _WR + Vector3(0.0, WI.y, 0.0) + _WF
	WH = _WL + Vector3(0.0, WI.y, 0.0) + _WF
	WJ = Vector3(BM.x, WI.y, BM.z)
	WK = WG - Vector3(0.0, front_pane_height, 0.0)
	WL = WH - Vector3(0.0, front_pane_height, 0.0)
	WM = DP + Vector3(0.0, cockpit_window_front_bumpout_depth, 0.0)
	WN = DM + Vector3(0.0, cockpit_window_front_bumpout_depth, 0.0)
	WO = Vector3(DP.x, DP.y, 0.0) + _WR
	WP = Vector3(DP.x, DP.y, 0.0) + _WL
		
func _build_cabin():
	_compute_cabin_coordinates()
	# ceiling
	_add_flat_surface(
		[CW,CV,CU,CZ,CN,CO,CY,CX],
		[[0,5,1],[5,4,1],[4,2,1],[4,3,2],[5,7,6],[7,5,0]],
		Vector3.DOWN,
		interior_material)
	# floor
	_add_flat_surface(
		[DW,DV,DU,DZ,DM,DP,DY,DX],
		[[0,1,3],[1,2,3],[3,4,5],[3,5,6],[3,6,0],[6,7,0]],
		Vector3.UP,
		interior_material
	)
	# right window edge
	_add_flat_surface([BP,BO,CO,CY,DY,DP],[[0,1,3],[1,2,3],[3,4,5],[3,5,0]],Vector3.BACK,interior_material)
	# left window edge
	_add_flat_surface([DM,DZ,CZ,CN,BN,BM],[[0,1,2],[2,3,4],[4,5,2],[5,0,2]],Vector3.FORWARD,interior_material)
	# rear window edge
	_add_flat_surface([BO,BN,CN,CO], [[0,1,3],[1,2,3]], Vector3.RIGHT,interior_material)
	# rear cabin wall
	_add_flat_surface([CW,CV,DV,DW], [[0,1,3],[1,2,3]], Vector3.RIGHT,interior_material)
	# right cabin wall
	_add_flat_surface([CX,CW,DW,DX], [[0,1,3],[1,2,3]], Vector3.FORWARD,interior_material)
	# left cabin wall
	_add_flat_surface([CV,CU,DU,DV], [[0,1,3],[1,2,3]], Vector3.BACK,interior_material)
	# right front cabin wall
	_add_flat_surface([CY,CX,DX,DY], [[0,1,3],[1,2,3]], Vector3.LEFT,interior_material)
	# left front cabin wall
	_add_flat_surface([CU,CZ,DZ,DU], [[0,1,3],[1,2,3]], Vector3.LEFT,interior_material)
	
	
func _build_body():
	_compute_body_coordinates()
	_add_flat_surface(
		[BI,BJ,BK,BL,BM,BN,BO,BP,BQ,BR,BS,BT],
		[[0,1,5],[1,2,5],[2,3,5],[3,4,5],[5,6,0],[6,11,0],[6,10,11],[6,9,10],[6,8,9],[6,7,8]],
		Vector3.UP,
		exterior_material
	)
	_add_flat_surface(
		[EQ,EL,EK,EJ,EI,ET,ES,ER],
		[[0,1,7],[1,2,3],[3,4,5],[5,6,7],[7,1,5],[1,3,5]],
		Vector3.DOWN
		,exterior_material
	)
	_add_flat_surface([BM,BL,EL,EQ,BQ,BP,DP,DM], [[0,1,7],[1,2,7],[2,6,7],[2,3,6],[3,4,6],[4,5,6]], Vector3.RIGHT,exterior_material)
	_add_flat_surface([BL,BK,EK,EL], [[0,1,3],[1,2,3]], Vector3(1.0,0.0,-1.0),exterior_material)
	_add_flat_surface([BK,BJ,EJ,EK], [[0,1,3],[1,2,3]], Vector3.FORWARD,exterior_material)
	_add_flat_surface([BR,BQ,EQ,ER], [[0,1,3],[1,2,3]], Vector3(1.0,0.0,1.0),exterior_material)
	_add_flat_surface([BS,BR,ER,ES], [[0,1,3],[1,2,3]], Vector3.BACK,exterior_material)
	_add_flat_surface([BT,BS,ES,ET], [[0,1,3],[1,2,3]], Vector3(-1.0,0.0,1.0),exterior_material)
	_add_flat_surface([BI,BT,ET,EI], [[0,1,3],[1,2,3]], Vector3.LEFT,exterior_material)
	_add_flat_surface([BJ,BI,EI,EJ], [[0,1,3],[1,2,3]], Vector3(-1.0,0.0,-1.0),exterior_material)

# construct a series of rectangular window frame edges, normal to the glass
func _add_frame_normal_edges(va: Array, normal_vector: Vector3):
	var nev := normal_vector*cockpit_frame_thickness
	var vqty := va.size()
	for n in range(vqty):
		var ea := [va[n], va[(n+1)%vqty], va[(n+1)%vqty]+nev, va[n]+nev]
		_add_frame_surface(ea, false, false, exterior_material)


# construct a single quadrilateral surface as part of a window pane, with or without an opening
func _add_frame_surface(va: Array, opening: bool, normal_edge: bool, material : StandardMaterial3D):
	var surface_array = []
	var normal_vector : Vector3 = -(Vector3(va[2]-va[1]).cross(Vector3(va[1]-va[0]))).normalized()
	# compute unit vectors for edges
	var edge_array = []
	for n in [0,1]:
		edge_array.append((va[n+1]-va[n]).normalized())
	# compute coordinates of opening
	var opening_array = []
	if opening:
		# vertices for quadrilateral
		opening_array.append(va[0] + cockpit_window_frame_width*(edge_array[0]+edge_array[1]))
		opening_array.append(va[1] + cockpit_window_frame_width*(-edge_array[0]+edge_array[1]))
		opening_array.append(va[2] + cockpit_window_frame_width*(-edge_array[0]-edge_array[1]))
		opening_array.append(va[3] + cockpit_window_frame_width*(edge_array[0]-edge_array[1]))
		if normal_edge:
			_add_frame_normal_edges(opening_array, normal_vector)
	
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	#######################################
	## Insert code here to generate mesh ##
	var vv : Array
	if opening:
		vv = va + opening_array
	else:
		vv = va
	for v in vv:
		verts.append(v)
		normals.append(normal_vector)
		if normal_vector == Vector3.UP:
			uvs.append(Vector2(v.z-vv[0].z, -v.x+vv[0].x))
		elif normal_vector == Vector3.RIGHT:
			uvs.append(Vector2(-v.z+vv[0].z, v.y+vv[0].y))
		elif normal_vector.x == 0.0:
			uvs.append(Vector2((v.x-vv[0].x), sqrt((v.y-vv[0].y)**2 + (v.z-vv[0].z)**2)))
		else: # normal_vector.y == 0.0
			uvs.append(Vector2(sqrt((v.z-vv[0].z)**2 + (v.x-vv[0].x)**2), v.y - vv[0].y))
	if opening:
		indices.append_array([0,1,4,1,5,4,1,2,5,2,6,5,2,3,6,3,7,6,3,4,7,3,0,4])
	else:
		indices.append_array([0,1,2,0,2,3])
	#######################################

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	var idx := mesh.get_surface_count() - 1
	mesh.surface_set_material(idx, material)
	
# construct a single triangular surface as part of a window pane, with or without an opening
func _add_triangle_frame_surface(va: Array, opening: bool, normal_edge: bool, material : StandardMaterial3D):
	var surface_array = []
	var normal_vector : Vector3 = -(Vector3(va[2]-va[1]).cross(Vector3(va[1]-va[0]))).normalized()
	# compute unit vectors for edges
	var edge_array = []
	edge_array.append((va[1]-va[0]).normalized())
	edge_array.append((va[2]-va[1]).normalized())
	edge_array.append((va[0]-va[2]).normalized())
	# compute coordinates of opening
	var opening_array = []
	if opening:
		# vertices for triangle
		opening_array.append(va[0] + cockpit_window_frame_width*(edge_array[0]-edge_array[2]))
		opening_array.append(va[1] + cockpit_window_frame_width*(-edge_array[0]+edge_array[1]))
		opening_array.append(va[2] + cockpit_window_frame_width*(-edge_array[1]+edge_array[2]))
		if normal_edge:
			_add_frame_normal_edges(opening_array, normal_vector)

	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	#######################################
	## Insert code here to generate mesh ##
	var vv : Array
	if opening:
		vv = va + opening_array
	else:
		vv = va
	for v in vv:
		verts.append(v)
		normals.append(normal_vector)
		if normal_vector == Vector3.UP:
			uvs.append(Vector2(v.z-vv[0].z, -v.x+vv[0].x))
		elif normal_vector == Vector3.RIGHT:
			uvs.append(Vector2(-v.z+vv[0].z, v.y+vv[0].y))
		elif normal_vector.x == 0.0:
			uvs.append(Vector2((v.x-vv[0].x), sqrt((v.y-vv[0].y)**2 + (v.z-vv[0].z)**2)))
		else: # normal_vector.y == 0.0
			uvs.append(Vector2(sqrt((v.z-vv[0].z)**2 + (v.x-vv[0].x)**2), v.y - vv[0].y))
	if opening:
		indices.append_array([0,1,3,3,1,4,1,2,4,2,5,4,2,0,5,5,0,3])
	else:
		indices.append_array([0,1,2])
	#######################################

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	var idx := mesh.get_surface_count() - 1
	mesh.surface_set_material(idx, material)
	
# construct surfaces for a four-layer four side window pane. 
# va is list of vertices in clockwise order
func _build_window_pane(va: Array, add_frame: Callable):
	var normal_vector : Vector3 = -(Vector3(va[2]-va[1]).cross(Vector3(va[1]-va[0]))).normalized()
	add_frame.call(va, true, false, interior_material)
	var vw = []
	for v in va:
		vw.append(v + normal_vector*(cockpit_glass_thickness/2.0))
	add_frame.call(vw, false, false, window_material)	
	var vg = []
	for v in va:
		vg.append(v + normal_vector*cockpit_glass_thickness)
	add_frame.call(vg, true, true, gasket_material)
	

func _build_window():
	_compute_window_coordinates()
	# top pane
	_build_window_pane([WB,WA,WC,WD], _add_frame_surface)
	_build_window_pane([WD,WC,WE,WF], _add_frame_surface)
	_build_window_pane([WC,WA,BO,BP], _add_frame_surface)
	_build_window_pane([WB,WD,BM,BN], _add_frame_surface)
	_build_window_pane([WE,BP,WI,WG], _add_frame_surface)
	_build_window_pane([WF,WE,WG,WH], _add_frame_surface)
	_build_window_pane([BM,WF,WH,WJ], _add_frame_surface)
	_build_window_pane([WH,WG,WK,WL], _add_frame_surface)
	_build_window_pane([WG,WI,WM,WK], _add_frame_surface)
	_build_window_pane([WJ,WH,WL,WN], _add_frame_surface)
	_build_window_pane([WL,WK,WO,WP], _add_frame_surface)
	# eyebrow windows
	_build_window_pane([WE,WC,BP], _add_triangle_frame_surface)
	_build_window_pane([WD,WF,BM], _add_triangle_frame_surface)
	# toe panels
	_add_triangle_frame_surface([WO,WK,DP], false, false, interior_material)
	_add_triangle_frame_surface([WK,WM,DP], false, false, interior_material)
	_add_triangle_frame_surface([WP,DM,WL], false, false, interior_material)
	_add_triangle_frame_surface([WL,DM,WN], false, false, interior_material)
	

func _build_turret():
	_compute_turret_coordinates()
	_add_flat_surface(
		[AE, AF, AG, AH, AA, AB, AC, AD],
		[[0, 1, 2], [2, 3, 4], [0, 2, 4], [4, 5, 6], [4, 6, 0], [6, 7, 0]],
		Vector3.UP,
		exterior_material
	)
	_add_flat_surface([AB,AA,BA,BB],[[0,1,3],[1,2,3]], Vector3(-1.0, 0.0, -1.0),exterior_material)
	_add_flat_surface([AC,AB,BB,BC], [[0,1,3],[1,2,3]], Vector3.FORWARD,exterior_material)
	_add_flat_surface([AD,AC,BC,BD],[[0,1,3],[1,2,3]], Vector3(1.0, 0.0, -1.0),exterior_material)
	_add_flat_surface([AE,AD,BD,BE],[[0,1,3],[1,2,3]], Vector3.RIGHT,exterior_material)
	_add_flat_surface([AF,AE,BE,BF],[[0,1,3],[1,2,3]], Vector3(1.0, 0.0, 1.0),exterior_material)
	_add_flat_surface([AG,AF,BF,BG],[[0,1,3],[1,2,3]], Vector3.BACK,exterior_material)
	_add_flat_surface([AH,AG,BG,BH],[[0,1,3],[1,2,3]], Vector3(-1.0, 0.0, 1.0),exterior_material)
	_add_flat_surface([AA,AH,BH,BA],[[0,1,3],[1,2,3]], Vector3.LEFT,exterior_material)

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
	_build_window()
	

func _build_mesh():
	_compute_derived_parameters()

func _ready():
	_build_mesh()

func _rebuild_model():
	mesh.clear_surfaces()
	_build_mesh()
