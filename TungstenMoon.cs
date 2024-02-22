using Godot;
using System;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Media3D;

public partial class TungstenMoon : MeshInstance3D
{
	const float G = 6.674E-11f;
	const float rhoW = 19250.0f; // kg/m^3
	float LogicalM; 
	
	public Vector3 GetForce(RigidBody3D Body)
	{
		Vector3 R = Position - Body.Position;
		return R.Normalized()*G*LogicalM*Body.Mass/R.LengthSquared();
	}
	
	public Vector3D GetLogicalPosition(RigidBody3D Body)
	{
		return new Vector3D();
	}
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
}

/*
extends MeshInstance3D

const G = 6.674E-11
const rhoW = 19250.0 # kg/m^3
var LogicalM: float 

func getForce(body) -> Vector3:
	var R = position - body.position
	var r = R.length()
	var runit = R.normalized()
	var f = G*LogicalM*body.mass/(r*r)
	return runit*f

func getLogicalPosition(body) -> Array:
	return $"../Spacecraft".vectorSub(body.position, position)
	
func setLogicalPosition(body):
	var v = $"../Spacecraft".vectorSub(body.position, body.logicalPosition)
	position = Vector3(v[0], v[1], v[2])
	
# Called when the node enters the scene tree for the first time.
func _ready():
	LogicalM = rhoW*(PI*4/3)*mesh.radius**3
	pass # Replace with function body.
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

*/
