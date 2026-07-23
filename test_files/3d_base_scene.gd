extends Node3D
# class_name # not requiered for test

@onready var ball_mesh_scene: PackedScene = preload("res://visuals/BallMesh.tscn")
@onready var block_mesh_scene: PackedScene = preload("res://visuals/BlockMesh.tscn")
@onready var powerup_asset_scene: PackedScene = preload("res://visuals/PowerupAsset.tscn")
@onready var gun_bullet_asset_scene: PackedScene = preload("res://visuals/GunBullet.tscn")

@onready var sfx_player: SFXPlayer = %SFXPlayer
# @onready var ball_mesh: MeshInstance3D = %BallMesh
@onready var ball_parent: Node3D = %Balls
@onready var powerup_parent: Node3D = %Powerups
@onready var paddle_mesh: MeshInstance3D = %PaddleMesh
@onready var laser_asset: LaserAsset = %LaserAsset
@onready var block_parent: Node3D = %Blocks
@onready var projectile_parent: Node3D = %Projectiles
@onready var mouse_input_handler: MouseInputHandler = %MouseInputHandler

@onready var debug_parent: Node3D = %Debug



# var ball: Ball = Ball.new()
# var balls: Array[Ball]
# var paddle: Paddle = Paddle.new()

# var screen_collision: Array[LineCollider]
# var death_barrier: LineCollider
# var blocks: Array[BreakableBlock]

# var broken_block_count: int = 0
# var nr_metal_blocks: int = 0

# var powerups: Array[Powerup]
var context: Global.GameContext

func _ready() -> void:
	context = Global.GameContext.new()
	# ball.randomize_velocity()
	var _new_ball: Ball = Ball.new()
	_new_ball.asset_ref = ball_mesh_scene.instantiate()
	context.balls.push_back(_new_ball)

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	for i in Global.LEVEL_COUNT:
		context.add_block_array(generate_sparse_map(), i)
		generate_block_assets(context.levels[i].blocks)
	
	display_blocks(context.levels[context.current_level].blocks)
	

	handle_mouse_movement(Vector2.ZERO)

	# paddle.collider_line.debug_set_up = false
	context.paddle.set_line(context.balls[0].radius)

	context.fireball_activated.connect(sfx_player.play_flame_ignite)
	context.fireball_deactivated.connect(sfx_player.play_flame_extinguish)

	# if DEBUG:
	DebugScreen.add_debug_line(func() -> String: return "FPS(d): %.2f" % _debug_fps)
	DebugScreen.add_debug_line(func() -> String: return "Frametime: %.3fms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000))
	DebugScreen.add_debug_line(context.balls[0]._get_ball_pos_debug)
	DebugScreen.add_debug_line(context._get_debug_string)

	%Playfield.mesh.size = 1024 / 32.0 * BreakableGrid.GRID_SIZE
	
var _debug_fps: float = 0.0
func _process(delta: float) -> void:
	_debug_fps = 1.0 / delta
	var safe_delta: float = min(delta, 1. / 60)

	context.set_flags()
	# delta *= .1
	# safe_delta *= .6

	if Global.DEBUG:
		context._set_debug_strings()
		
		if Input.is_action_just_pressed("debug_powerup"):
			var powerup: Powerup = Powerup.new()
			powerup.randomize_velocity()

			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = SphereMesh.new()
			mesh.mesh.radius = 16
			mesh.mesh.height = 32
			debug_parent.add_child(mesh)

			powerup.asset = mesh

			context.powerups.push_back(powerup)
		
		if Input.is_action_just_pressed("debug_ball"):
			var ball: Ball = Ball.new()
			ball.asset_ref = ball_mesh_scene.instantiate()
			ball.released = true
			context.balls.push_back(ball)

			ball.randomize_velocity()

	handle_mouse_movement(mouse_input_handler.accumulated_mouse_movement)
	mouse_input_handler.accumulated_mouse_movement = Vector2.ZERO
	
	if !context.balls[0].released && mouse_input_handler.action_just_pressed:
		release_ball()

	# handling blocks before balls
	# this is bc multiball powerup might rotate the ball's 
	# velocity of out the play area
	# TODO: this might've been bc of delta becoming too high
	# investigate with safe_delta and move back if neccessary
	# blocked by: bitmap optimization

	## for block: BreakableBlock in context.blocks:
	## 	if block.is_broken():
	## 		continue


	for ball: Ball in context.balls:
		if !ball.released:
			break # TODO: might be hacky

		var x_from: int = floorf((ball.position.x + (grid_unit_size.x / 2)) / BreakableGrid.CELL_SIZE)
		var y_from: int = floorf((ball.position.y + (grid_unit_size.y / 2)) / BreakableGrid.CELL_SIZE)
		var x_to: int = sign(ball.velocity.x)
		var y_to: int = sign(ball.velocity.y)

		x_to = x_to * 2 + x_from
		y_to = y_to * 2 + y_from

		# Cheeky ordering to fix [#044]
		# ball first checks in the direction of velocity
		# if that fails, falls back to grazing blocks
		var x_range: Array = range(x_from, x_to, sign(ball.velocity.x))
		x_range.push_back(x_from - sign(ball.velocity.x))
		var y_range: Array = range(y_from, y_to, sign(ball.velocity.y))
		y_range.push_back(y_from - sign(ball.velocity.y))

		for x: int in x_range:
			var block: BreakableBlock
			for y: int in y_range:
				block = context.get_block_at(x, y)
				if block == null:
					continue

				for line: LineCollider in block.collision:

					if ball.collide_with(line, block.reflects_ball(context)):
						block.hit_block(context, ball)


				if block.is_broken():
					break
			# TODO: use damage_block_and_clear()
			if block != null && block.is_broken():
				if block.has_powerup:
					block.has_powerup = false
					spawn_powerup(block)
				
				context.broken_block_count += 1

				block.asset_ref.queue_free()
				context.remove_block(block)
				break	


	# if !ball.released:
	if context.balls.size() == 1 && !context.balls[0].released:
		context.balls[0].set_position(context.paddle.position + Vector2.UP * context.balls[0].radius * 2)
	else:
		# ball.move(delta)
		for ball: Ball in context.balls:
			ball.move(safe_delta)

	# handle collision
	# check for death barrier first
	var index: int = 0
	while index < context.balls.size():
		var ball: Ball = context.balls[index]

		if ball.collide_with(context.death_barrier, false, false):	
			if context.is_death_barrier_active():
				if context.balls.size() > 1:
					# ball_parent.remove_child(ball.asset_ref)
					ball.asset_ref.queue_free()
					context.balls.erase(ball)
					index -= 1
				else:
					on_death()
			else:
				context.prev_level()
				display_blocks(context.levels[context.current_level].blocks)
				break
		
		index += 1
	
	var level_unlocked: bool = context.levels[context.current_level].unlocked
	for ball: Ball in context.balls:
		if ball.collide_with(context.top_barrier, !level_unlocked, !level_unlocked):
			if level_unlocked:
				context.next_level()
				display_blocks(context.levels[context.current_level].blocks)
				break



	# var collided: bool = false

	for line in context.screen_collision:
		# ball.collide_with(line, true)
		for ball: Ball in context.balls:
			ball.collide_with(line, true)

	

	
	
	if context.is_current_level_complete():
		# TODO: change blocks to breakable if only non-breakable remain
		# on_board_clear()
		# return
		context.next_level()
		display_blocks(context.levels[context.current_level].blocks)

	for ball: Ball in context.balls:
		if ball.collide_with_paddle(context.paddle):
			sfx_player.play_paddle_hit()

	
	# update active effects
	var disable_effect_queue: Array[Powerup]
	for powerup: Powerup in context.active_powerups:
		# powerup.time_left -= safe_delta
		powerup.update(safe_delta)
		if powerup.time_left <= 0.0:
			# LoggerMogyi.log(self, "Removing powerup: %s" % powerup.name)
			disable_effect_queue.push_back(powerup)
		
		if powerup.laser_shot:
			LoggerMogyi.log(self, "Laser is being shot!")
			for y: int in BreakableGrid.GRID_SIZE.y:
				var x: int = floorf((context.paddle.position.x + (grid_unit_size.x / 2)) / BreakableGrid.CELL_SIZE)
				var block: BreakableBlock = context.get_block_at(x, y)

				damage_block_and_clear(block, context.get_laser_damage())
			
			sfx_player.play_laser_shot()
	
	for powerup: Powerup in disable_effect_queue:
		context.active_powerups.erase(powerup)
	
	if context.GUN_ACTIVE && mouse_input_handler.action_just_pressed:
		LoggerMogyi.log(self, "Shooting with active GUN powerup")
		spawn_gun_projectiles()
		sfx_player.play_gun_shot()

	# update projectiles
	#
	# oooooooooo oooooooooo    ooooooo  ooooo ooooooooooo  oooooooo8 ooooooooooo ooooo ooooo       ooooooooooo  oooooooo8  
	#  888    888 888    888 o888   888o 888   888    88 o888     88 88  888  88  888   888         888    88  888         
	#  888oooo88  888oooo88  888     888 888   888ooo8   888             888      888   888         888ooo8     888oooooo  
	#  888        888  88o   888o   o888 888   888    oo 888o     oo     888      888   888      o  888    oo          888 
	# o888o      o888o  88o8   88ooo88   888  o888ooo8888 888oooo88     o888o    o888o o888ooooo88 o888ooo8888 o88oooo888  
	#                                 8o888                                                                                

	var proj_marked_for_remove: Array[Projectile] = []																					
	for projectile: Projectile in context.projectiles:
		projectile.move(safe_delta)

		if projectile.type == Projectile.Type.GUN_BULLET:
			# TODO: could make a function that turns {game world space} -> {grid index}
			var idx2: Vector2 = ((projectile.position + (grid_unit_size / 2)) / BreakableGrid.CELL_SIZE).floor()
			var block: BreakableBlock = context.get_block_at(idx2.x, idx2.y)

			if damage_block_and_clear(block, context.get_gun_damage()):
				proj_marked_for_remove.push_back(projectile)
	
	for projectile: Projectile in proj_marked_for_remove:
		projectile.asset_ref.queue_free()
		context.projectiles.erase(projectile)



	# https://patorjk.com/software/taag/#p=display&f=O8
	#
	# ooooo  oooo ooooo  oooooooo8 ooooo  oooo    o      ooooo        oooooooo8  
	#  888    88   888  888         888    88    888      888        888         
	#   888  88    888   888oooooo  888    88   8  88     888         888oooooo  
	#    88888     888          888 888    88  8oooo88    888      o         888 
	#     888     o888o o88oooo888   888oo88 o88o  o888o o888ooooo88 o88oooo888  
																			
													 

	# update powerup pickups
	for powerup: Powerup in context.powerups:
		powerup.move(safe_delta)
		powerup.asset.position.x = powerup.position.x
		powerup.asset.position.z = powerup.position.y
		powerup.asset.position.y = BreakableGrid.CELL_SIZE

		collide_with_screen(powerup)

		# powerup picked up logic
		# TODO: move to its own function
		if powerup.collide_with_paddle(context.paddle):
			powerup.activate_powerup(context)
			context.powerups.erase(powerup)
			powerup.asset.queue_free()
		
		if powerup.position.y > BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE * 1.5:
			context.powerups.erase(powerup)
			powerup.asset.queue_free()


	for i in context.balls.size():
		var ball: Ball = context.balls[i]
		
		if ball.asset_ref.get_parent() == null:
			ball_parent.add_child(ball.asset_ref)

			# TODO: hooking up sound player here
			ball.collided.connect(sfx_player.play_ball_hit)


		ball.asset_ref.global_position.x = ball.position.x
		ball.asset_ref.global_position.z = ball.position.y
		ball.asset_ref.global_position.y = ball.radius

		if context.FLAG_FIREBALL_ACTIVE:
			ball.asset_ref.set_flame(true)
			ball.asset_ref.set_flame_rotation(ball.velocity)
		else:
			ball.asset_ref.set_flame(false)

	for projectile: Projectile in context.projectiles:
		projectile.asset_ref.global_position.x = projectile.position.x
		projectile.asset_ref.global_position.z = projectile.position.y
		projectile.asset_ref.global_position.y = BreakableGrid.CELL_SIZE / 2.0

	paddle_mesh.global_position.x = context.paddle.position.x
	paddle_mesh.global_position.z = context.paddle.position.y
	paddle_mesh.global_position.y = context.paddle.height / 2

	laser_asset.visible = context.LASER_ACTIVE
	# laser_asset.%Beam.material_override.set_shader_parameter("TimeLeft", context.LASER_COOLDOWN)
	laser_asset.set_visual(context.LASER_COOLDOWN)


var grid_unit_size: Vector2
func set_up_screen_collision() -> void:
	# var screen_bounds: Vector2 = DisplayServer.window_get_size()

	grid_unit_size = BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var p1: Vector2 = Vector2(-grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p2: Vector2 = Vector2(grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p3: Vector2 = Vector2(grid_unit_size.x / 2, grid_unit_size.y / 2)
	var p4: Vector2 = Vector2(-grid_unit_size.x / 2, grid_unit_size.y / 2)

	var line: LineCollider = LineCollider.new()
	# line.set_points(p1, p2)
	# context.screen_collision.push_back(line)

	# This is the top barrier
	context.top_barrier = LineCollider.new()
	context.top_barrier.set_points(p1, p2)

	# This is the death barrier
	context.death_barrier = LineCollider.new()
	context.death_barrier.set_points(p3, p4)

	p3.y += grid_unit_size.y
	p4.y += grid_unit_size.y

	line = LineCollider.new()
	line.set_points(p2, p3)
	context.screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p4, p1)
	context.screen_collision.push_back(line)



# TODO: I dont like this being alone with a signal. 
# might cause headache later when debugging
func handle_mouse_movement(movement: Vector2) -> void:
	context.paddle.move(movement)


func release_ball() -> void:
	context.balls[0].randomize_velocity()
	context.balls[0].released = true

# Handle any logic for death
func on_death() -> void:
	context.balls[0].velocity = Vector2.ZERO
	context.balls[0].released = false
	LoggerMogyi.log(self, "Died")


# TODO: prune when map generator is ready
func generate_map() -> void:
	for child in block_parent.get_children():
		child.queue_free()
	context.blocks.clear()
	context.nr_metal_blocks = 0

	# have X rows where randomly sized (vertical scale) blocks sit next to eachother
	# there is a margin of 2 grid cells at the sides and top
	# TODO: no thorough documentation needed, as this is just a placeholder for now
	var nr_rows: int = 6
	var nr_cols: int = BreakableGrid.GRID_SIZE.x - 4

	for i in nr_rows:
		var total: int = 0
		while total < nr_cols:
			var block_size: int = randi_range(2, 5)

			if total + block_size > nr_cols:
				block_size = nr_cols - total

			var block: BreakableBlock = BreakableBlock.new()

			block.pos_on_grid = Vector2i(2 + total, 2 * i + 2)
			block.size = Vector2i(block_size, 2)
			block.health = randi_range(1, 3)
			if randf() < .4:
				block.type = BreakableBlock.BlockType.ICE
				block.health = 1
			if randf() < .2:
				block.type = BreakableBlock.BlockType.METAL
				block.health = 1
				context.nr_metal_blocks += 1
			block.prepare_collision()

			if randf() < .3:
				block.has_powerup = true
				block.powerup = Powerup.new()
				block.powerup.type = Powerup.Type.BALL_MULTIPLY

			var block_mesh: BlockMesh = block_mesh_scene.instantiate()
			block_parent.add_child(block_mesh)
			block_mesh.set_visual_scale(block.size * BreakableGrid.CELL_SIZE)
			var final_pos: Vector2 = block.get_origin()
			block_mesh.global_position.x = final_pos.x
			block_mesh.global_position.z = final_pos.y
			block_mesh.global_position.y = BreakableGrid.CELL_SIZE / 2
			block_mesh.set_material(block.type)
			block_mesh.set_hp(block.health)

			block.asset_ref = block_mesh

			context.blocks.push_back(block)

			total += block_size

func generate_sparse_map() -> Array[BreakableBlock]:
	var map_generator := MapGenerator.new()
	var SEED: int = randi()
	map_generator.rng._seed = SEED

	map_generator.add_uv_to_color()
	map_generator.add_perlin_noise()
	map_generator.treshold_grayscale(0.75)

	map_generator.copy_texture_to_final_bound(0, 0, 24, 26)

	return map_generator.convert_with_chance_merge(.5, .5)


# func generate_map_from_array(blocks: Array[BreakableBlock]) -> void:
# 	for block in blocks:
# 		var block_mesh: BlockMesh = block_mesh_scene.instantiate()
# 		block_parent.add_child(block_mesh)
# 		block_mesh.set_visual_scale(block.size * BreakableGrid.CELL_SIZE)
# 		var final_pos: Vector2 = block.get_origin()
# 		block_mesh.global_position.x = final_pos.x
# 		block_mesh.global_position.z = final_pos.y
# 		block_mesh.global_position.y = BreakableGrid.CELL_SIZE / 2
# 		block_mesh.set_material(block.type)
# 		block_mesh.set_hp(block.health)
# 		block_mesh.set_color(block.color)

# 		block.asset_ref = block_mesh

# 		block.just_broken.connect(sfx_player.play_block_hit)
# 		# context.blocks.push_back(block)
# 		context.add_block(block)

func generate_block_assets(blocks: Array[BreakableBlock]) -> void:
	for block: BreakableBlock in blocks:
		var block_mesh: BlockMesh = block_mesh_scene.instantiate()
		block_parent.add_child(block_mesh)
		block_mesh.set_visual_scale(block.size * BreakableGrid.CELL_SIZE)
		var final_pos: Vector2 = block.get_origin()
		block_mesh.global_position.x = final_pos.x
		block_mesh.global_position.z = final_pos.y
		block_mesh.global_position.y = BreakableGrid.CELL_SIZE / 2
		block_mesh.set_material(block.type)
		block_mesh.set_hp(block.health)
		block_mesh.set_color(block.color)

		block.asset_ref = block_mesh

		block.just_broken.connect(sfx_player.play_block_hit)

		block_parent.remove_child(block_mesh)

func display_blocks(blocks: Array[BreakableBlock]) -> void:
	for child in block_parent.get_children():
		block_parent.remove_child(child)
	
	for block: BreakableBlock in blocks:
		block_parent.add_child(block.asset_ref)

func on_board_clear() -> void:
	# TODO: this resets the ball. shouldn't use death entrypoint for this tho
	on_death()

	context.broken_block_count = 0
	generate_map()

# func are_breakable_blocks_remaining() -> bool:
# 	return context.broken_block_count >= context.blocks.size() - context.nr_metal_blocks

func collide_with_screen(powerup: Powerup) -> void:
	var grid_unit_size: Vector2 = BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var left: float = -grid_unit_size.x / 2
	var right: float = grid_unit_size.x / 2

	if powerup.position.x < left:
		powerup.position.x += (left - powerup.position.x) * 2
		powerup.velocity.x *= -1

	elif powerup.position.x > right:
		powerup.position.x -= (powerup.position.x - right) * 2
		powerup.velocity.x *= -1

func spawn_powerup(block: BreakableBlock) -> void:
	var powerup: Powerup = block.powerup
	powerup.position = block.get_origin()

	powerup.randomize_velocity()

	# var mesh: MeshInstance3D = MeshInstance3D.new()
	# mesh.mesh = SphereMesh.new()
	# mesh.mesh.radius = 16
	# mesh.mesh.height = 32
	# debug_parent.add_child(mesh)
	var asset: PowerupAsset = powerup_asset_scene.instantiate()
	powerup_parent.add_child(asset)
	asset.set_visuals(powerup)



	powerup.asset = asset

	context.powerups.push_back(powerup)

func spawn_gun_projectiles() -> void:
	var p: Projectile = Projectile.new()
	p.init_type(Projectile.Type.GUN_BULLET)
	p.position = context.paddle.get_left_side()
	var asset: Node3D = gun_bullet_asset_scene.instantiate()
	projectile_parent.add_child(asset)
	p.asset_ref = asset
	context.projectiles.push_back(p)

	p = Projectile.new()
	p.init_type(Projectile.Type.GUN_BULLET)
	p.position = context.paddle.get_right_side()
	p.position -= Vector2(0.001, 0) # otherwie it perfectly misses the blocks on the right sides
	asset = gun_bullet_asset_scene.instantiate()
	projectile_parent.add_child(asset)
	p.asset_ref = asset
	context.projectiles.push_back(p)

func damage_block_and_clear(block: BreakableBlock, damage: int) -> bool:
	if block == null:
		return false

	block.hit_block_dmg(damage)

	if block != null && block.is_broken():
		if block.has_powerup:
			block.has_powerup = false
			spawn_powerup(block)
		
		context.broken_block_count += 1

		block.asset_ref.queue_free()
		context.remove_block(block)

		return true
	
	return false
