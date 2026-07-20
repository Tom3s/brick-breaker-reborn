extends Node3D
# class_name # not requiered for test

@onready var ball_mesh_scene: PackedScene = preload("res://visuals/BallMesh.tscn")
@onready var block_mesh_scene: PackedScene = preload("res://visuals/BlockMesh.tscn")
@onready var powerup_asset_scene: PackedScene = preload("res://visuals/PowerupAsset.tscn")

@onready var sfx_player: SFXPlayer = %SFXPlayer
# @onready var ball_mesh: MeshInstance3D = %BallMesh
@onready var ball_parent: Node3D = %Balls
@onready var powerup_parent: Node3D = %Powerups
@onready var paddle_mesh: MeshInstance3D = %PaddleMesh
@onready var laser_asset: LaserAsset = %LaserAsset
@onready var block_parent: Node3D = %Blocks
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

	# generate_map()
	var map_generator := MapGenerator.new()
	var SEED: int = randi()
	map_generator.rng._seed = SEED
	map_generator.fill_color(Vector3(.3, .0, .9))

	# map_generator.add_random_grayscale_noise()
	# map_generator.add_voronoi_noise()

	# map_generator.add_circle(
	# 	map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
	# 	map_generator.rng.get_float() * BreakableGrid.GRID_SIZE / 2,
	# 	map_generator.rng.get_float() * 8,
	# )
	# for i in 2:
	map_generator.add_rectangle(
		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
	)
	map_generator.slice_y(0, 18)
	map_generator.copy_texture_to_final()
	generate_map_from_array(map_generator.convert_with_chance_merge(0.5, 1.0, 3, 2, BreakableBlock.BlockType.ICE))	
	map_generator.mirror_x()
	map_generator.copy_texture_to_final()
	generate_map_from_array(map_generator.convert_with_chance_merge(0.5, 1.0, 3, 2, BreakableBlock.BlockType.ICE))	
	map_generator.clear_temp_texture()


	#region
	map_generator.add_uv_to_color()
	map_generator.add_perlin_noise()
	# # map_generator.treshold_grayscale(0.5)
	map_generator.dither_grayscale()
	# map_generator.slice_y(0, 24)
	# # map_generator.slice_x(0, 10)
	# # generate_map_from_array(map_generator.convert_with_horizontal_merge(3))
	# # map_generator.copy_texture_to_final_bound(0, 0, 10, 24)
	# # map_generator.mirror_x()
	# # map_generator.copy_texture_to_final_bound(22, 0, 32, 24)
	map_generator.copy_texture_to_final_bound(0, 0, 32, 22)

	# # map_generator.copy_texture_to_final()
	generate_map_from_array(map_generator.convert_with_chance_merge(.5, .5))

	# map_generator.clear_final_texture()
	# map_generator.clear_temp_texture()
	# map_generator.add_voronoi_noise()
	# map_generator.invert()
	# map_generator.treshold_grayscale(0.7)
	# map_generator.slice_y(0, 20)
	# map_generator.slice_x(10, 22)
	# map_generator.copy_texture_to_final()

	# # generate_map_from_array(map_generator.convert_with_vertical_merge(2))
	# generate_map_from_array(map_generator.convert_with_chance_merge(.0, .7))


	#endregion

	# for i in 4:
	# 	map_generator.add_circle(
	# 		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
	# 		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE / 2,
	# 		map_generator.rng.get_float() * 8,
	# 	)
	
	# generate_map_from_array(map_generator.convert_with_horizontal_merge(1))
	

	mouse_input_handler.mouse_moved.connect(handle_mouse_movement)
	mouse_input_handler.release_ball_pressed.connect(release_ball)

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
	# check for death first
	# if ball.collide_with(death_barrier, false, false):
	# 	on_death()
	var index: int = 0
	# for i in context.balls.size():
	while index < context.balls.size():
		var ball: Ball = context.balls[index]

		if ball.collide_with(context.death_barrier, false, false):	
			if context.balls.size() > 1:
				# ball_parent.remove_child(ball.asset_ref)
				ball.asset_ref.queue_free()
				context.balls.erase(ball)
				index -= 1
			else:
				on_death()
		
		index += 1


	# var collided: bool = false

	for line in context.screen_collision:
		# ball.collide_with(line, true)
		for ball: Ball in context.balls:
			ball.collide_with(line, true)

	

	
	
	if are_breakable_blocks_remaining():
		# TODO: change blocks to breakable if only non-breakable remain
		# on_board_clear()
		# return
		pass
	
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
			for y: int in BreakableGrid.GRID_SIZE:
				var x: int = floorf((context.paddle.position.x + (grid_unit_size.x / 2)) / BreakableGrid.CELL_SIZE)
				var block: BreakableBlock = context.get_block_at(x, y)

				if block == null:
					continue

				block.hit_block_laser(context)

				if block != null && block.is_broken():
					if block.has_powerup:
						block.has_powerup = false
						spawn_powerup(block)
					
					context.broken_block_count += 1

					block.asset_ref.queue_free()
					context.remove_block(block)
			
			sfx_player.play_laser_shot()

	
	for powerup: Powerup in disable_effect_queue:
		context.active_powerups.erase(powerup)

	# update powerups
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
		
		if powerup.position.y > BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE * 1.5:
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


	paddle_mesh.global_position.x = context.paddle.position.x
	paddle_mesh.global_position.z = context.paddle.position.y
	paddle_mesh.global_position.y = context.paddle.height / 2

	laser_asset.visible = context.LASER_ACTIVE
	# laser_asset.%Beam.material_override.set_shader_parameter("TimeLeft", context.LASER_COOLDOWN)
	laser_asset.set_visual(context.LASER_COOLDOWN)


var grid_unit_size: Vector2
func set_up_screen_collision() -> void:
	# var screen_bounds: Vector2 = DisplayServer.window_get_size()

	grid_unit_size = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var p1: Vector2 = Vector2(-grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p2: Vector2 = Vector2(grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p3: Vector2 = Vector2(grid_unit_size.x / 2, grid_unit_size.y / 2)
	var p4: Vector2 = Vector2(-grid_unit_size.x / 2, grid_unit_size.y / 2)

	var line: LineCollider = LineCollider.new()
	line.set_points(p1, p2)
	context.screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p2, p3)
	context.screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p4, p1)
	context.screen_collision.push_back(line)

	# This is the death barrier
	context.death_barrier = LineCollider.new()
	context.death_barrier.set_points(p3, p4)


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
	var nr_cols: int = BreakableGrid.GRID_SIZE - 4

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

func generate_map_from_array(blocks: Array[BreakableBlock]) -> void:
	for block in blocks:
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
		# context.blocks.push_back(block)
		context.add_block(block)

func on_board_clear() -> void:
	# TODO: this resets the ball. shouldn't use death entrypoint for this tho
	on_death()

	context.broken_block_count = 0
	generate_map()

func are_breakable_blocks_remaining() -> bool:
	return context.broken_block_count >= context.blocks.size() - context.nr_metal_blocks

func collide_with_screen(powerup: Powerup) -> void:
	var grid_unit_size: Vector2 = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
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
