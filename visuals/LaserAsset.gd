extends Node3D
class_name LaserAsset

@onready var beam: MeshInstance3D = %Beam

func set_visual(time_left: float) -> void:
	beam.material_override.set_shader_parameter("TimeLeft", time_left)

