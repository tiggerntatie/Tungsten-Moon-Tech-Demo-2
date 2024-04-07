class_name DVector3

extends RefCounted

var x : float
var y : float
var z : float

static func Add(a: DVector3, b: DVector3) -> DVector3:
	return DVector3.new(a.x+b.x, a.y+b.y, a.z+b.z)

static func QAdd(a: DVector3, b: DVector3, c: DVector3, d: DVector3) -> DVector3:
	return DVector3.new(a.x+b.x+c.x+d.x, a.y+b.y+c.y+d.y, a.z+b.z+c.z+d.z)

static func Sub(a: DVector3, b: DVector3) -> DVector3:
	return DVector3.new(a.x-b.x, a.y-b.y, a.z-b.z)

static func Mul(a: float, b: DVector3) -> DVector3:
	return DVector3.new(a*b.x, a*b.y, a*b.z)

static func Div(a: DVector3, b: float) -> DVector3:
	return DVector3.new(a.x/b, a.y/b, a.z/b)

static func FromVector3(v: Vector3) -> DVector3:
	return DVector3.new(v.x, v.y, v.z)

# scalar multiply
func multiply_scalar(c: float) -> void:
	x *= c
	y *= c
	z *= c

# scalar divide
func divide_scalar(c: float) -> void:
	x /= c
	y /= c
	z /= c

# vector add
func add(v: DVector3) -> void:
	x += v.x
	y += v.y
	z += v.z

# vector subtract
func sub(v: DVector3) -> void:
	x -= v.x
	y -= v.y
	z -= v.z

# vector rotate around y-axis
func rotate_y(th: float, xz_radius: float = 0.0) -> void:
	var xn = x*cos(th) + z*sin(th)
	z = - x*sin(th) + z*cos(th)
	x = xn
	# ensure correct radius in xz plane
	if xz_radius > 0.0:
		var old_xz_r = sqrt(pow(x,2) + pow(z,2))
		x *= xz_radius / old_xz_r
		z *= xz_radius / old_xz_r

# radius in the xz plane
func xz_length() -> float:
	return sqrt(pow(x,2) + pow(z,2))

# magnitude squared
func length_squared() -> float:
	return pow(x,2) + pow(y,2) + pow(z,2)

# magnitude
func length() -> float:
	return sqrt(length_squared())

# normalize
func normalized() -> DVector3:
	return DVector3.Div(self, length())
	
# create a Vector3
func vector3() -> Vector3:
	return Vector3(x, y, z)

# copy a DVector3
func copy() -> DVector3:
	return DVector3.new(x, y, z)
	
# get a string
func _to_string() -> String:
	return str(x) + "," + str(y) + "," + str(z)

func _init(_x = 0.0, _y = 0.0, _z = 0.0):
	x = _x
	y = _y
	z = _z

	
