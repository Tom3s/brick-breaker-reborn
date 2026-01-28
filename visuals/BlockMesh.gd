extends MeshInstance3D
class_name BlockMesh

var normal_material: Material = preload("res://visuals/MultiLayerMaterial.material")
var ice_material: Material = preload("res://visuals/IceMaterial.material")
var metal_material: Material = preload("res://visuals/MetalMaterial.material")

var base_size: Vector3 = Vector3.ONE * 2.0

func _ready() -> void:
	material_override = normal_material.duplicate()

func set_visual_scale(size: Vector2) -> void:
	scale.x = size.x / base_size.x
	scale.z = size.y / base_size.z

	scale.y = BreakableGrid.CELL_SIZE / base_size.y

func set_hp(hp: int) -> void:
	material_override.set_shader_parameter("health", hp)

func set_material(type: BreakableBlock.BlockType) -> void:
	if type == BreakableBlock.BlockType.NORMAL:
		material_override = normal_material.duplicate()
	elif type == BreakableBlock.BlockType.ICE:
		material_override = ice_material.duplicate()
	elif type == BreakableBlock.BlockType.METAL:
		material_override = metal_material.duplicate()


		