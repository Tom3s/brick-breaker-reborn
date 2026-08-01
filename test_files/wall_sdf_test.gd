@tool
extends Node3D

@onready var mesh: MeshInstance3D = %Mesh
@onready var ball_parent: Node3D = %BallParent

var ball_positions: PackedVector3Array

var sdf_wall_material: ShaderMaterial

var MAX_BALL_COUNT: int = 32

func _ready() -> void:
	ball_positions.resize(MAX_BALL_COUNT)
	sdf_wall_material = mesh.get_surface_override_material(0)

func _physics_process(delta: float) -> void:
	for i in MAX_BALL_COUNT:
		if ball_parent.get_child_count() <= i:
			ball_positions[i] = Vector3.INF
			continue

		var ball: Node3D = ball_parent.get_child(i)
		ball_positions[i] = ball.global_position

		

	sdf_wall_material.set_shader_parameter("balls", ball_positions)
