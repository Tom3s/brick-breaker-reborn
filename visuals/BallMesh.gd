extends MeshInstance3D
class_name BallMesh

@onready var flame: Node3D = %Flame
@onready var ice: Node3D = %Ice
@onready var effect: Node3D = %Effect
@onready var debug: MeshInstance3D = %Debug

const DEFAULT_COLOR: String = "0098d2"
const FLAME_COLOR: String = "ff892e"
const ICE_COLOR: String = "FFFFFF"

var is_flame: bool = false

# func set_flame(new_flame: bool) -> void:
# 	if new_flame:
# 		material_override.set_shader_parameter("Color", Color.from_string(FLAME_COLOR, Color.WHITE))
# 	else:
# 		material_override.set_shader_parameter("Color", Color.from_string(DEFAULT_COLOR, Color.WHITE))
# 	flame.visible = new_flame

func set_visual(type: Ball.Type) -> void:
	if type == Ball.Type.FIRE:
		material_override.set_shader_parameter("Color", Color.from_string(FLAME_COLOR, Color.WHITE))
	elif type == Ball.Type.ICE:
		material_override.set_shader_parameter("Color", Color.from_string(ICE_COLOR, Color.WHITE))
	elif type == Ball.Type.NORMAL:
		material_override.set_shader_parameter("Color", Color.from_string(DEFAULT_COLOR, Color.WHITE))
	
	effect.visible = type != Ball.Type.NORMAL
	flame.visible = type == Ball.Type.FIRE
	ice.visible = type == Ball.Type.ICE


# func set_flame_rotation(velocity: Vector2) -> void:
# 	if velocity == Vector2.ZERO:
# 		flame.look_at(global_position + Vector3.FORWARD)
# 		return
		
# 	flame.look_at(global_position + Vector3(velocity.x, 1, velocity.y) / 10)

func set_effect_rotation(velocity: Vector2) -> void:
	if velocity == Vector2.ZERO:
		effect.look_at(global_position + Vector3.FORWARD)
		return
		
	effect.look_at(global_position + Vector3(velocity.x, 1, velocity.y) / 10)