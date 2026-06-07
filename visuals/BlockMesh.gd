extends MeshInstance3D
class_name BlockMesh

var normal_material: Material = preload("res://visuals/ColoredMaterial.material")
var ice_material: Material = preload("res://visuals/IceMaterial.material")
var metal_material: Material = preload("res://visuals/MetalMaterial.material")

var hp_material: Material = preload("res://visuals/HPIndicatorMaterial.material")

@onready
var hp_indicator: MeshInstance3D = %HPIndicator

var hp_texture_base_path: String = "res://visuals/textures/hp_indicators"

# TODO: convert to ENUM
var current_hp_skin: String = "dots"

var base_size: Vector3 = Vector3.ONE * 2.0

func _ready() -> void:
	material_override = normal_material.duplicate()
	hp_indicator.material_override = hp_material.duplicate()

func set_visual_scale(size: Vector2) -> void:
	scale.x = size.x / base_size.x
	scale.z = size.y / base_size.z

	LoggerMogyi.log(self, "Set block scale to %v (actual scale param %v)" % [scale, size])

	scale.y = BreakableGrid.CELL_SIZE / base_size.y

	var smaller_scale: float = min(size.x, size.y)
	hp_indicator.scale.x = smaller_scale / scale.x / base_size.x
	hp_indicator.scale.y = smaller_scale / scale.z / base_size.z

	LoggerMogyi.log(self, "Set hp_indicator scale to %v (actual scale param %v)" % [hp_indicator.scale, size])


func set_hp(hp: int) -> void:
	if hp <= 0:
		return
	# material_override.set_shader_parameter("health", hp)
	# handle hp over 9
	hp = min(hp, 9)
	var texture_path: String = "%s/%s/%d.png" % [hp_texture_base_path, current_hp_skin, hp]
	# var image: Image = load(texture_path)
	hp_indicator.material_override.set_shader_parameter("Texture", load(texture_path))


func set_material(type: BreakableBlock.BlockType) -> void:
	if type == BreakableBlock.BlockType.NORMAL:
		material_override = normal_material.duplicate()
	elif type == BreakableBlock.BlockType.ICE:
		material_override = ice_material.duplicate()
	elif type == BreakableBlock.BlockType.METAL:
		material_override = metal_material.duplicate()


		
