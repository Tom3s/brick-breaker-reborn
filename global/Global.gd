extends Node

var GRAVITY: float = 256.0

var DEBUG: bool = true

var DEBUG_DRAW_VISIBLE: bool = true

const BALL_LIMIT: int = 350

const LEVEL_COUNT: int = 8

const DEFAULT_BALL_RADIUS: int = 16.0 # 12.0

var PLAYER_SENSITIVITY: float = 2.0 # 0.75 # 0.65

var GRACE_COOLDOWN: float = 25.0
var GRACE_POWERUP_TRESHOLD: float = 20.0
var GRACE_BLOCK_BREAK_TRESHOLD: float = 12.0
# var GRACE_COOLDOWN: float = 1.0
# var GRACE_POWERUP_TRESHOLD: float = 500.0
# var GRACE_BLOCK_BREAK_TRESHOLD: float = 5.0

var STALE_BALL_HIT_TRESHOLD: int = 4

class Level:
	var blocks: Array[BreakableBlock]

	var block_grid: BlockGrid
	
	var completed: bool = false
	var unlocked: bool = false
	var key_enabled: bool = false

	var boss_level: bool = true
	var snake: Snake
	var rng: RandomNumberGenerator

enum BossType {
	NONE,
	SNAKE,
}

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

	var gun_cooldown: float = 0.0

	var BALL_POWERUP_SLOTS: int = 2
	var ball_powerups: Array[Powerup]
	var ball_power_active: bool = false

	var projectiles: Array[Projectile]

	var time_since_last_powerup: float = 0.0 
	var time_since_grace_powerup: float = 0.0 
	var time_block_broken: float = 0.0 

	var win: bool = false

	func _init() -> void:
		# block_bitmap.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
		for i in LEVEL_COUNT:
			var level: Level = Level.new()

			level.block_grid = BlockGrid.new()
			levels.push_back(level)
		
		paddle = Paddle.new()

	func add_block_array(blocks: Array[BreakableBlock], level_index: int = current_level) -> void:
		for block in blocks:
			add_block(block, level_index)

	func add_block(block: BreakableBlock, level_index: int) -> void:
		levels[level_index].blocks.push_back(block)
		levels[level_index].block_grid.add_block(block)


	func remove_block(block: BreakableBlock, level_index: int = current_level) -> void:
		if is_boss_level():
			# TODO: check boss type
			# !has_powerup => it's snake segment
			# has_powerup => it's food
			if block.type != BreakableBlock.BlockType.SNAKE_FOOD:
				var blocks_to_remove: Array[BreakableBlock] = levels.back().snake.cut_snake_at(
					block.pos_on_grid, 
					levels.back().rng
				)
				for block_to_remove in blocks_to_remove:
					levels[level_index].blocks.erase(block_to_remove)
					levels[level_index].block_grid.remove_block(block_to_remove)

				# snake was cut
				if blocks_to_remove.size() && !levels.back().snake.is_dead:
					levels.back().snake.get_head_block().hit_block_dmg(1)
				# cut snake can also create foods/blocks 
				for food: Snake.Food in levels.back().snake.foods:
					if food.block_ref == null:
						var new_block: BreakableBlock = _create_block_for_food(food)
						food.block_ref = new_block
						add_block(new_block, LEVEL_COUNT - 1)
			else:
				levels.back().snake.mark_food_as_eaten(block.pos_on_grid)
				pass

		# TODO: handling memory from here, might wanna move it
		levels[level_index].blocks.erase(block)
		levels[level_index].block_grid.remove_block(block)

		
		levels[level_index].completed = levels[level_index].blocks.is_empty()
		if !is_boss_level():
			levels[level_index].unlocked = levels[level_index].unlocked || levels[level_index].blocks.filter(
				func(b: BreakableBlock) -> bool:
					return b.type != BreakableBlock.BlockType.METAL
			).is_empty()
	
	func update_block_pos(block: BreakableBlock, new_pos: Vector2i, level_index: int = current_level) -> void:
		levels[level_index].block_grid.remove_block(block)
		block.pos_on_grid = new_pos
		block.prepare_collision()
		levels[level_index].block_grid.add_block(block)


	func get_blocks_for_circle(pos: Vector2, r: float) -> Array[BreakableBlock]:
		return levels[current_level].block_grid.get_blocks_for_circle(pos, r)
	
	func get_blocks_for_pos(pos: Vector2) -> Array[BreakableBlock]:
		return levels[current_level].block_grid.get_blocks_for_pos(pos)

	func get_blocks_for_aabb(a: Vector2, b: Vector2) -> Array[BreakableBlock]:
		return levels[current_level].block_grid.get_blocks_for_aabb(a, b)
	

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

		if current_level >= 2:
			levels[current_level - 2].completed = true
		
		if is_boss_level():
			levels[current_level - 1].completed = true

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
		
		if ball_powerups.size() >= 1:
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
		elif ball_powerups[0].type == Powerup.Type.MINE_BALL:
			return Ball.Type.MINE
		
		return Ball.Type.NONE

	func enable_key() -> void:
		levels[current_level].key_enabled = true

	func activate_key() -> void:
		if current_level == LEVEL_COUNT - 1:
			return

		if levels[current_level].key_enabled:
			levels[current_level].unlocked = true

	func get_can_key_be_used() -> bool:
		if current_level == LEVEL_COUNT - 1:
			return false
		
		return levels[current_level].key_enabled && !levels[current_level].unlocked

	func update_grace_timers(delta: float) -> void:
		time_block_broken += delta
		time_since_grace_powerup += delta
		time_since_last_powerup += delta
	
	func should_spawn_grace_powerup() -> bool:
		if time_since_grace_powerup <= Global.GRACE_COOLDOWN:
			return false
		
		if time_since_last_powerup > Global.GRACE_POWERUP_TRESHOLD:
			return true
		
		if time_block_broken > Global.GRACE_BLOCK_BREAK_TRESHOLD:
			return true
		
		return false
	
	func set_fun_graces() -> void:
		Global.GRACE_COOLDOWN = 1.0 / 20
		Global.GRACE_POWERUP_TRESHOLD = 0.0
		Global.STALE_BALL_HIT_TRESHOLD = 1
		Powerup.grace_powerups = Powerup.fun_grace_powerups

	func init_snake_boss(seed: int = randi()) -> void:
		var boss_level: Global.Level = levels.back()
		boss_level.boss_level = true
		boss_level.rng = RandomNumberGenerator.new()
		boss_level.rng.seed = seed

		var snake_boss: Snake = Snake.new()
		snake_boss.init_snake()

		snake_boss.refill_food(boss_level.rng)

		for food in snake_boss.foods:
			var block: BreakableBlock = _create_block_for_food(food)

			food.block_ref = block

			add_block(block, LEVEL_COUNT - 1)

		snake_boss.direction = Vector2i.RIGHT
		snake_boss.calculate_nav_grid()

		var is_head: bool = true
		for segment in snake_boss.segments:
			var block: BreakableBlock = _create_block_for_segment(segment)
			if is_head:	
				block.type = BreakableBlock.BlockType.METAL
				block.color = Vector3(0.525, 0.688, 0.71)
				# block.health = Vector2i.MAX.x - 1
				block.health = 100 # snake health hp

			segment.block_ref = block

			add_block(block, LEVEL_COUNT - 1)

			is_head = false
		
		boss_level.snake = snake_boss

	func _create_block_for_segment(segment: Snake.Segment) -> BreakableBlock:
		var block: BreakableBlock = BreakableBlock.new()
		block.color = Vector3(0.165, 0.471, 0.51)
		block.type = BreakableBlock.BlockType.NORMAL
		block.pos_on_grid = segment.position

		# TODO: multi-health snake boss
		# block.health = 1

		block.prepare_collision()

		return block

	func _create_block_for_food(food: Snake.Food) -> BreakableBlock:
		var block: BreakableBlock = BreakableBlock.new()
		block.color = Vector3(0.74, 0.111, 0.121)
		block.type = BreakableBlock.BlockType.SNAKE_FOOD
		block.pos_on_grid = food.position

		block.has_powerup = true
		block.powerup = Powerup.new()
		block.powerup.type = Powerup.get_weighted_powerup(levels.back().rng.randf())

		# TODO: multi-health snake food
		# block.health = 1

		block.prepare_collision()

		return block

	func is_boss_level() -> bool:
		return current_level == LEVEL_COUNT - 1

	### return true if snake position was updated
	func update_snake_boss(delta: float) -> bool:
		var snake: Snake = levels.back().snake
		var grown: bool = false
		var moved: bool = false

		if snake.navigator.next_step != Vector2i.MIN:
			snake.set_nav_direction()
		# else:
		# 	move_treshold = 1 / 10.0

		if snake.last_move >= snake.move_treshold:
			grown = snake.update()
			snake.last_move -= snake.move_treshold
			if snake.foods.size() != 0:
				snake.calculate_nav_grid()

			for segment in snake.segments:
				if segment.block_ref == null:
					segment.block_ref = _create_block_for_segment(segment)
					add_block(segment.block_ref, current_level)
				else:
					update_block_pos(
						segment.block_ref,
						segment.position,
						current_level
					)

			moved = true
		
		for food in snake.foods:
			if food.eaten:
				remove_block(food.block_ref)
		
		# if grown:
			# remove_block(grown.block_ref)
		snake.refill_food(levels.back().rng)

		for food in snake.foods:
			if food.block_ref == null:
				var block: BreakableBlock = _create_block_for_food(food)
				food.block_ref = block
				add_block(block, LEVEL_COUNT - 1)
		
		snake.purge_stale_food()

		snake.last_move += delta

		return moved

	# flags
	var LASER_ACTIVE: bool = false
	var LASER_COOLDOWN: float = 0.0
	var GUN_ACTIVE: bool = false
	var TUNNEL_ACTIVE: bool = false

	func set_flags() -> void:
		LASER_ACTIVE = false
		LASER_COOLDOWN = -1.0
		GUN_ACTIVE = false
		TUNNEL_ACTIVE = false

		for powerup: Powerup in active_powerups:
			if powerup.type == Powerup.Type.LASER:
				LASER_ACTIVE = powerup.laser_shots_left != powerup.laser_max_shots
				LASER_COOLDOWN = max(powerup.time_left, LASER_COOLDOWN)
			elif powerup.type == Powerup.Type.GUN:
				GUN_ACTIVE = true
			elif powerup.type == Powerup.Type.TUNNEL:
				TUNNEL_ACTIVE = true
		

	# debug strings
	var _DEBUG_ACTIVE_POWERUPS: String
	var _DEBUG_BALL_SLOTS: String
	var _DEBUG_ACTIVE_NR_BALLS: String
	var _DEBUG_CURRENT_LEVEL: String
	var _DEBUG_CURRENT_KEY_STATUS: String
	var _DEBUG_CURRENT_LEVEL_COMPLETE: String
	var _DEBUG_SNAKE_HEALTH: String

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

		if is_boss_level() && !win:
			_DEBUG_SNAKE_HEALTH = "Snake HP: %d/30" % levels[current_level].snake.segments.front().block_ref.health
	
	func _get_debug_string() -> String:
		return "%s\n%s\n%s\n%s\n%s\n%s\n%s" % [
			_DEBUG_ACTIVE_NR_BALLS, 
			_DEBUG_BALL_SLOTS,
			_DEBUG_CURRENT_LEVEL,
			_DEBUG_CURRENT_LEVEL_COMPLETE,
			_DEBUG_CURRENT_KEY_STATUS,
			_DEBUG_SNAKE_HEALTH,
			_DEBUG_ACTIVE_POWERUPS,
		]
	
	# this function only exists, so that later Skills can influence this value
	static func get_laser_damage() -> int:
		return 5

	static func get_gun_damage() -> int:
		return 1
