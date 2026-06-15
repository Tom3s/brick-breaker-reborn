extends Node

var GRAVITY: float = 256.0

var DEBUG: bool = true

class GameContext extends Node:

	var balls: Array[Ball]
	var paddle: Paddle = Paddle.new()

	var screen_collision: Array[LineCollider]
	var death_barrier: LineCollider
	var blocks: Array[BreakableBlock]

	var broken_block_count: int = 0
	var nr_metal_blocks: int = 0

	var powerups: Array[Powerup]
	var active_powerups: Array[Powerup]

	# flags
	var FLAG_FIREBALL_ACTIVE: bool = false

	func set_flags() -> void:
		FLAG_FIREBALL_ACTIVE = false

		for powerup: Powerup in active_powerups:
			if powerup.type == Powerup.Type.FIRE_BALL:
				FLAG_FIREBALL_ACTIVE = true

	# debug strings
	var _DEBUG_ACTIVE_POWERUPS: String

	func _set_debug_strings() -> void:
		_DEBUG_ACTIVE_POWERUPS = "Active Effects: \n"
		for powerup: Powerup in active_powerups:
			var type: String = Powerup.Type.keys()[powerup.type].capitalize()
			_DEBUG_ACTIVE_POWERUPS += "- %s: %.2fs \n" % [type, powerup.time_left]
	
	func _get_debug_string() -> String:
		return _DEBUG_ACTIVE_POWERUPS
