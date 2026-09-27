extends MarginContainer
class_name PowerupIconsUI

@onready var default_icon: TextureRect = %DefaultIcon
@onready var icons: HBoxContainer = %Icons

var powerups: Array[Powerup] = []

func add_powerup(powerup: Powerup) -> void:
	var new_icon: TextureRect = default_icon.duplicate()

	powerups.push_back(powerup)
	icons.add_child(new_icon)

	new_icon.material = new_icon.material.duplicate()

	var texture: Texture = TextureLoader.powerup[powerup.type]
	new_icon.material.set_shader_parameter("sdf_texture", texture)
	new_icon.material.set_shader_parameter("icon_left", powerup.get_time_normalized())

	new_icon.show()

func update_powerups() -> void:
	for index in powerups.size():
		var icon: TextureRect = icons.get_child(index)
		var powerup: Powerup = powerups[index]

		if powerup.get_time_normalized() < 0.0:
			icon.queue_free()
			continue

		icon.material.set_shader_parameter("icon_left", powerup.get_time_normalized())

	powerups = powerups.filter(func(pow: Powerup) -> bool:
		return pow.get_time_normalized() >= 0.0
	)
