extends MeshInstance3D
class_name PowerupAsset

@onready var label: Label3D = %PowerupLabel
@onready var texture_small: MeshInstance3D = %PowerupSpriteSmall

func set_visuals(powerup: Powerup) -> void:
	if powerup.type == Powerup.Type.BALL_MULTIPLY:
		label.text = str(powerup.ball_multiply_value)