extends MeshInstance3D
class_name BallMesh

@onready var flame: Node3D = %Flame
@onready var debug: MeshInstance3D = %Debug

const DEFAULT_COLOR: String = "0098d2"
const FLAME_COLOR: String = "ff892e"

var is_flame: bool = false

func set_flame(new_flame: bool) -> void:
	if new_flame:
		material_override.set_shader_parameter("Color", Color.from_string(FLAME_COLOR, Color.WHITE))
	else:
		material_override.set_shader_parameter("Color", Color.from_string(DEFAULT_COLOR, Color.WHITE))
	flame.visible = new_flame
	


func set_flame_rotation(velocity: Vector2) -> void:
	flame.look_at(global_position + Vector3(velocity.x, 1, velocity.y) / 10)
