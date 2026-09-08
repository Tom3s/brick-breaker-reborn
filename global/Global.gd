extends Node

var GRAVITY: float = 256.0

var DEBUG: bool = true

var DEBUG_DRAW_VISIBLE: bool = true

const BALL_LIMIT: int = 350

const LEVEL_COUNT: int = 10

const DEFAULT_BALL_RADIUS: int = 16.0 # 12.0

var PLAYER_SENSITIVITY: float = 0.75 # 0.65

class Level:
	var blocks: Array[BreakableBlock]
	# var block_bitmap: Array[BreakableBlock]
	var quad_tree: QuadTree
	
	var completed: bool = false
	var unlocked: bool = false
	var key_enabled: bool = false

class GameContext extends Node:

	signal ball_powerup_activated(type: Powerup.Type)
	signal ball_powerup_deactivated(type: Powerup.Type)

	var balls: Array[Ball]
	var paddle: Paddle

	var screen_collision: Array[LineCollider]
	var screen_a: Vector2
	var screen_b: Vector2
	var top_barrier: LineCollider
	var death_barrier: LineCollider

	var levels: Array[Level]
	var current_level: int = 0

	var broken_block_count: int = 0
	var nr_metal_blocks: int = 0

	var powerups: Array[Powerup]
	var active_powerups: Array[Powerup]

	var BALL_POWERUP_SLOTS: int = 2
	var ball_powerups: Array[Powerup]
	var ball_power_active: bool = false

	var projectiles: Array[Projectile]

	func _init() -> void:
		# block_bitmap.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
		for i in LEVEL_COUNT:
			var level: Level = Level.new()
			# level.block_bitmap.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
			level.quad_tree = QuadTree.create_node(
				-(BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE) / 2,
				(BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE) / 2,
			)
			levels.push_back(level)
		
		paddle = Paddle.new()

	func add_block_array(blocks: Array[BreakableBlock], level_index: int = current_level) -> void:
		for block in blocks:
			add_block(block, level_index)

	func add_block(block: BreakableBlock, level_index: int) -> void:
		levels[level_index].blocks.push_back(block)
		levels[level_index].quad_tree.add_block(block)


	func remove_block(block: BreakableBlock, level_index: int = current_level) -> void:
		# TODO: handling memory from here, might wanna move it
		levels[level_index].blocks.erase(block)
		levels[level_index].quad_tree.remove_block(block)

		
		levels[level_index].completed = levels[level_index].blocks.is_empty()
	

	func get_blocks_for_circle(pos: Vector2, r: float) -> Array[BreakableBlock]:
		return levels[current_level].quad_tree.get_blocks_for_circle(pos, r)
	
	func get_blocks_for_pos(pos: Vector2) -> Array[BreakableBlock]:
		return levels[current_level].quad_tree.get_blocks_for_pos(pos)

	func get_blocks_for_aabb(a: Vector2, b: Vector2) -> Array[BreakableBlock]:
		return levels[current_level].quad_tree.get_blocks_for_aabb(a, b)
	

	func is_current_level_complete() -> bool:
		return levels[current_level].completed

	func is_death_barrier_active() -> bool:
		return current_level == 0 || levels[current_level - 1].completed

	func next_level() -> void:
		current_level += 1
		LoggerMogyi.log(self, "Changed level to %d" % current_level)
		if current_level >= LEVEL_COUNT:
			LoggerMogyi.log(self, "Completed All Levels!!")
			current_level = LEVEL_COUNT - 1
			return
		
		balls = balls.filter(func(b: Ball) -> bool:
			if b.velocity.y > 0 || b.position.y > BreakableGrid.GRID_SIZE.y * 2:
				b.asset_ref.queue_free()
				return false
			return true
		)
		for ball: Ball in balls:
			ball.position.y += BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE
		
		for powerup: Powerup in powerups:
			powerup.asset.queue_free()
		powerups.clear()
	
	func prev_level() -> void:
		current_level -= 1
		LoggerMogyi.log(self, "Changed level to %d" % current_level)
		if current_level < 0:
			LoggerMogyi.log(self, "Can't go back on first level")
			current_level = 0
			return
		
		# TODO: not needed, as backtracking only happens on your last ball
		# balls = balls.filter(func(b: Ball) -> bool:
		# 	if b.velocity.y < 0:
		# 		b.asset_ref.queue_free()
		# 		return false
		# 	return true
		# )
		for ball: Ball in balls:
			ball.position.y -= BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE
		
		# powerups don't need clearing, as player can still catch them in the previous level
		# powerups.clear()
		for powerup: Powerup in powerups:
			powerup.position.y -= BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE

	func get_current_blocks() -> Array[BreakableBlock]:
		return levels[current_level].blocks

	func add_ball_powerup(powerup: Powerup) -> void:
		if ball_powerups.size() < BALL_POWERUP_SLOTS:
			ball_powerups.push_back(powerup)

	func activate_ball_power() -> void:
		if ball_power_active && ball_powerups.size() >= 2:
			ball_powerups.remove_at(0)
		
		ball_power_active = true

	func update_ball_powerup(delta: float) -> void:
		if ball_powerups.size() < 1:
			return
		
		ball_powerups[0].update(delta)

		if ball_powerups[0].time_left <= 0:
			ball_powerup_deactivated.emit(ball_powerups[0].type)
			ball_powerups.remove_at(0)
			ball_power_active = false

	func get_active_ball_powerup() -> Ball.Type:
		if !ball_power_active:
			return Ball.Type.NORMAL
		
		# return ball_powerups[0].type
		if ball_powerups[0].type == Powerup.Type.FIRE_BALL:
			return Ball.Type.FIRE
		elif ball_powerups[0].type == Powerup.Type.ICE_BALL:
			return Ball.Type.ICE
		
		return Ball.Type.NONE

	func enable_key() -> void:
		levels[current_level].key_enabled = true

	func activate_key() -> void:
		if levels[current_level].key_enabled:
			levels[current_level].unlocked = true



	# flags
	var LASER_ACTIVE: bool = false
	var LASER_COOLDOWN: float = 0.0
	var GUN_ACTIVE: bool = false

	func set_flags() -> void:
		LASER_ACTIVE = false
		LASER_COOLDOWN = -1.0
		GUN_ACTIVE = false

		for powerup: Powerup in active_powerups:
			if powerup.type == Powerup.Type.LASER:
				LASER_ACTIVE = true
				LASER_COOLDOWN = max(powerup.time_left, LASER_COOLDOWN)
			elif powerup.type == Powerup.Type.GUN:
				GUN_ACTIVE = true
		

	# debug strings
	var _DEBUG_ACTIVE_POWERUPS: String
	var _DEBUG_BALL_SLOTS: String
	var _DEBUG_ACTIVE_NR_BALLS: String
	var _DEBUG_CURRENT_LEVEL: String
	var _DEBUG_CURRENT_KEY_STATUS: String
	var _DEBUG_CURRENT_LEVEL_COMPLETE: String

	func _set_debug_strings() -> void:
		_DEBUG_ACTIVE_POWERUPS = "Active Effects: \n"
		for powerup: Powerup in active_powerups:
			var type: String = Powerup.Type.keys()[powerup.type].capitalize()
			_DEBUG_ACTIVE_POWERUPS += "- %s: %.2fs \n" % [type, powerup.time_left]
		
		_DEBUG_BALL_SLOTS = "Ball Slots: "
		for powerup: Powerup in ball_powerups:
			var type: String = Powerup.Type.keys()[powerup.type].capitalize()
			_DEBUG_BALL_SLOTS += "%s: %.2fs |" % [type, powerup.time_left]

		_DEBUG_ACTIVE_NR_BALLS = "Nr Balls: %d" % balls.size()
		_DEBUG_CURRENT_LEVEL = "Current Level: %d" % current_level
		_DEBUG_CURRENT_KEY_STATUS = "KEY picked up: %s / Used: %s" % [str(levels[current_level].key_enabled), str(levels[current_level].unlocked)]
		
		_DEBUG_CURRENT_LEVEL_COMPLETE = "Current Level Complete: %s" % str(levels[current_level].completed)
	
	func _get_debug_string() -> String:
		return "%s\n%s\n%s\n%s\n%s\n%s" % [
			_DEBUG_ACTIVE_NR_BALLS, 
			_DEBUG_BALL_SLOTS,
			_DEBUG_CURRENT_LEVEL,
			_DEBUG_CURRENT_LEVEL_COMPLETE,
			_DEBUG_CURRENT_KEY_STATUS,
			_DEBUG_ACTIVE_POWERUPS,
		]
	
	# this function only exists, so that later Skills can influence this value
	static func get_laser_damage() -> int:
		return 3

	static func get_gun_damage() -> int:
		return 100