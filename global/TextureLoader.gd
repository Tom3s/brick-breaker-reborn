extends Node

var powerup: Dictionary[Powerup.Type, Texture]

func _init() -> void:
	load_powerup_textures()

func load_powerup_textures() -> void:
	for val: int in Powerup.Type.values():
		if val == 0: # NONE
			powerup[val] = null
			continue
		
		var key: String = Powerup.Type.keys()[val]

		var texture_loc: String = "res://visuals/textures/powerups/%s.png" % key
		powerup[val] = load(texture_loc)

		LoggerMogyi.log(self, "Loaded texture from %s" % texture_loc)
