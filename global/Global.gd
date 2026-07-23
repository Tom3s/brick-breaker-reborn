extends Node

var GRAVITY: float = 256.0

var DEBUG: bool = true

const BALL_LIMIT: int = 350

const LEVEL_COUNT: int = 10

class Level:
	var blocks: Array[BreakableBlock]
	var block_bitmap: Array[BreakableBlock]
	
	var completed: bool = false

class GameContext extends Node:

	signal fireball_activated()
	signal fireball_deactivated()

	var balls: Array[Ball]
	var paddle: Paddle = Paddle.new()

	var screen_collision: Array[LineCollider]
	var death_barrier: LineCollider
	# var blocks: Array[BreakableBlock]
	# var block_bitmap: Array[BreakableBlock]
	var levels: Array[Level]
	var current_level: int = 0

	var broken_block_count: int = 0
	var nr_metal_blocks: int = 0

	var powerups: Array[Powerup]
	var active_powerups: Array[Powerup]

	var projectiles: Array[Projectile]

	func _init() -> void:
		# block_bitmap.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
		for i in LEVEL_COUNT:
			var level: Level = Level.new()
			level.block_bitmap.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
			levels.push_back(level)

	func add_block_array(blocks: Array[BreakableBlock], level_index: int = current_level) -> void:
		for block in blocks:
			add_block(block, level_index)

	func add_block(block: BreakableBlock, level_index: int) -> void:
		levels[level_index].blocks.push_back(block)

		for x in block.size.x:
			for y in block.size.y:
				var actual_x: int = block.pos_on_grid.x + x
				var actual_y: int = block.pos_on_grid.y + y

				levels[level_index].block_bitmap[actual_x + BreakableGrid.GRID_SIZE.x * actual_y] = block


	func remove_block(block: BreakableBlock, level_index: int = current_level) -> void:
		# TODO: handling memory from here, might wanna move it
		levels[level_index].blocks.erase(block)

		for x in block.size.x:
			for y in block.size.y:
				var actual_x: int = block.pos_on_grid.x + x
				var actual_y: int = block.pos_on_grid.y + y

				levels[level_index].block_bitmap[actual_x + BreakableGrid.GRID_SIZE.x * actual_y] = null
		
		levels[level_index].completed = levels[level_index].blocks.is_empty()
	
	func get_block_at(x: int, y: int) -> BreakableBlock:
		# LoggerMogyi.log(self, "Getting block at (%.3f, %.3f)" % [x, y])

		if y < 0 || y >= BreakableGrid.GRID_SIZE.y:
			return null

		if x < 0 || x >= BreakableGrid.GRID_SIZE.x:
			return null
		
		return levels[current_level].block_bitmap[y * BreakableGrid.GRID_SIZE.x + x]

	func is_current_level_complete() -> bool:
		return levels[current_level].completed

	# flags
	var FLAG_FIREBALL_WAS_ACTIVE: bool = false
	var FLAG_FIREBALL_ACTIVE: bool = false
	var LASER_ACTIVE: bool = false
	var LASER_COOLDOWN: float = 0.0
	var GUN_ACTIVE: bool = false

	func set_flags() -> void:
		FLAG_FIREBALL_ACTIVE = false
		LASER_ACTIVE = false
		LASER_COOLDOWN = -1.0
		GUN_ACTIVE = false

		for powerup: Powerup in active_powerups:
			if powerup.type == Powerup.Type.FIRE_BALL:
				FLAG_FIREBALL_ACTIVE = true
			elif powerup.type == Powerup.Type.LASER:
				LASER_ACTIVE = true
				LASER_COOLDOWN = max(powerup.time_left, LASER_COOLDOWN)
			elif powerup.type == Powerup.Type.GUN:
				GUN_ACTIVE = true
		
		if FLAG_FIREBALL_ACTIVE != FLAG_FIREBALL_WAS_ACTIVE:
			if FLAG_FIREBALL_ACTIVE:
				fireball_activated.emit()
			else:
				fireball_deactivated.emit()

		FLAG_FIREBALL_WAS_ACTIVE = FLAG_FIREBALL_ACTIVE

	# debug strings
	var _DEBUG_ACTIVE_POWERUPS: String
	var _DEBUG_ACTIVE_NR_BALLS: String
	var _DEBUG_CURRENT_LEVEL: String
	var _DEBUG_CURRENT_LEVEL_COMPLETE: String

	func _set_debug_strings() -> void:
		_DEBUG_ACTIVE_POWERUPS = "Active Effects: \n"
		for powerup: Powerup in active_powerups:
			var type: String = Powerup.Type.keys()[powerup.type].capitalize()
			_DEBUG_ACTIVE_POWERUPS += "- %s: %.2fs \n" % [type, powerup.time_left]
		
		_DEBUG_ACTIVE_NR_BALLS = "Nr Balls: %d" % balls.size()
		_DEBUG_CURRENT_LEVEL = "Current Level: %d" % current_level
		_DEBUG_CURRENT_LEVEL_COMPLETE = "Current Level Complete: %s" % str(levels[current_level].completed)
	
	func _get_debug_string() -> String:
		return "%s\n%s\n%s\n%s" % [
			_DEBUG_ACTIVE_NR_BALLS, 
			_DEBUG_CURRENT_LEVEL,
			_DEBUG_CURRENT_LEVEL_COMPLETE,
			_DEBUG_ACTIVE_POWERUPS,
		]
	
	# this function only exists, so that later Skills can influence this value
	static func get_laser_damage() -> int:
		return 3

	static func get_gun_damage() -> int:
		return 100