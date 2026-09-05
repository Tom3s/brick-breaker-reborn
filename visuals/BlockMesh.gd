extends Node3D
class_name BlockMesh

var normal_material: Material = preload("res://visuals/ColoredMaterial.material")
var ice_material: Material = preload("res://visuals/IceMaterial.material")
var metal_material: Material = preload("res://visuals/MetalMaterial.material")

var hp_material: Material = preload("res://visuals/HPIndicatorMaterial.material")

@onready var hp_indicator: MeshInstance3D = %HPIndicator
@onready var mesh: ProceduralBlockMesh = %Mesh

var hp_texture_base_path: String = "res://visuals/textures/hp_indicators"

# TODO: convert to ENUM
var current_hp_skin: String = "dots"

var base_size: Vector3 = Vector3.ONE * 2.0

func _ready() -> void:
	mesh.material_override = normal_material.duplicate()
	hp_indicator.material_override = hp_material.duplicate()

# func set_visual_scale(size: Vector2) -> void:
# 	scale.x = size.x / base_size.x
# 	scale.z = size.y / base_size.z

# 	# LoggerMogyi.log(self, "Set block scale to %v (actual scale param %v)" % [scale, size])

# 	scale.y = BreakableGrid.CELL_SIZE / base_size.y

# 	var smaller_scale: float = min(size.x, size.y)
# 	hp_indicator.scale.x = smaller_scale / scale.x / base_size.x
# 	hp_indicator.scale.y = smaller_scale / scale.z / base_size.z

# 	# LoggerMogyi.log(self, "Set hp_indicator scale to %v (actual scale param %v)" % [hp_indicator.scale, size])

func set_polygon(points: PackedVector2Array) -> void:
	mesh.points = points
	mesh.create_mesh()

	var size: Vector2 = mesh.bound_max - mesh.bound_min
	var smaller_scale: float = min(size.x, size.y)
	# we dont wanna scale z!!
	hp_indicator.scale.x = smaller_scale
	hp_indicator.scale.y = smaller_scale
	hp_indicator.position.x = lerp(mesh.bound_min.x, mesh.bound_max.x, 0.5)
	hp_indicator.position.z = lerp(mesh.bound_min.y, mesh.bound_max.y, 0.5)
	hp_indicator.position.y = BreakableGrid.CELL_SIZE + 0.01 # offset to combat z-fighting


func set_hp(hp: int) -> void:
	if hp <= 0:
		return
	
	# TODO: this should be set by an accesibility option
	hp_indicator.visible = hp > 1

	# TODO: handle hp over 9 properly
	hp = min(hp, 9)
	var texture_path: String = "%s/%s/%d.png" % [hp_texture_base_path, current_hp_skin, hp]

	hp_indicator.material_override.set_shader_parameter("Texture", load(texture_path))

func set_key_block() -> void:
	# hp_indicator.material_override.set_shader_parameter("Texture", load("res://visuals/textures/powerups/KEY.png"))
	mesh.material_override.set_shader_parameter("Color", Vector3.ONE)


func set_color(color: Vector3) -> void:
	mesh.material_override.set_shader_parameter("Color", color)

func set_material(type: BreakableBlock.BlockType) -> void:
	if type == BreakableBlock.BlockType.NORMAL:
		mesh.material_override = normal_material.duplicate()
	elif type == BreakableBlock.BlockType.ICE:
		mesh.material_override = ice_material.duplicate()
	elif type == BreakableBlock.BlockType.METAL:
		mesh.material_override = metal_material.duplicate()


		
