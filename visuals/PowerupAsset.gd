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
	
	if powerup.type == Powerup.Type.FIRE_BALL:
		label.visible = false
		texture_small.visible = false
		texture_big.visible = true
