extends MeshInstance3D
class_name BlockMesh

var block_material: Material = preload("res://visuals/MultiLayerMaterial.material")

var base_size: Vector3 = Vector3.ONE * 2.0

func _ready() -> void:
	material_override = block_material.duplicate()

func set_visual_scale(size: Vector2) -> void:
	scale.x = size.x / base_size.x
	scale.z = size.y / base_size.z

	scale.y = BreakableGrid.CELL_SIZE / base_size.y

func set_hp(hp: int) -> void:
	material_override.set_shader_parameter("health", hp)