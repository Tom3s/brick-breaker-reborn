extends MeshInstance3D
class_name PowerupAsset

@onready var label: Label3D = %PowerupLabel
@onready var texture_small: MeshInstance3D = %PowerupSpriteSmall
@onready var texture_big: MeshInstance3D = %PowerupSpriteBig

func set_visuals(powerup: Powerup) -> void:
	if powerup.type == Powerup.Type.BALL_MULTIPLY:
		label.visible = true
		texture_small.visible = true
		texture_big.visible = false
		label.text = str(powerup.ball_multiply_value)
		return
	
	if powerup.type == Powerup.Type.KEY:
		get_surface_override_material(0).set_shader_parameter("Color", Color.from_string("b700e0", Color.PURPLE))
	
	# elif powerup.type == Powerup.Type.FIRE_BALL:
		# label.visible = false
		# texture_small.visible = false
		# texture_big.visible = true
	# 
	# elif powerup.type == Powerup.Type.LASER:
		# label.visible = false
		# texture_small.visible = false
		# texture_big.visible = true
	label.visible = false
	texture_small.visible = false
	texture_big.visible = true

	var texture_loc: String = "res://visuals/textures/powerups/%s.png" % Powerup.Type.keys()[powerup.type]

	texture_big.material_override = texture_big.material_override.duplicate()
	texture_big.material_override.set_shader_parameter("Texture", load(texture_loc))
