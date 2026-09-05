@tool
extends Node3D

@onready var mesh: ProceduralBlockMesh = %Mesh
@onready var points: Polygon2D = %Points

@export_tool_button("Transfer points and build mesh")
var _generate_button: Callable = func() -> void:
	mesh.points = points.polygon
	mesh.create_mesh()
