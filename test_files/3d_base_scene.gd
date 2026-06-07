extends Node3D
# class_name # not requiered for test

@onready var ball_mesh_scene: PackedScene = preload("res://visuals/BallMesh.tscn")
@onready var block_mesh_scene: PackedScene = preload("res://visuals/BlockMesh.tscn")

# @onready var ball_mesh: MeshInstance3D = %BallMesh
@onready var ball_parent: Node3D = %Balls
@onready var paddle_mesh: MeshInstance3D = %PaddleMesh
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
	context.balls.push_back(Ball.new())
	ball_parent.add_child(ball_mesh_scene.instantiate())

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	# generate_map()
	var map_generator := MapGenerator.new()
	var SEED: int = randi()
	map_generator.rng._seed = SEED

	# map_generator.add_random_grayscale_noise()
	# map_generator.add_voronoi_noise()

	map_generator.add_circle(
		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE,
		map_generator.rng.get_float() * BreakableGrid.GRID_SIZE / 2,
		map_generator.rng.get_float() * 8,
	)

	map_generator.copy_texture_to_final()
	generate_map_from_array(map_generator.convert_with_chance_merge(1.0, .0))

	#region
	map_generator.add_perlin_noise()
	map_generator.treshold_grayscale(0.5)
	# map_generator.slice_y(0, 24)
	# map_generator.slice_x(0, 10)
	# generate_map_from_array(map_generator.convert_with_horizontal_merge(3))
	# map_generator.copy_texture_to_final_bound(0, 0, 10, 24)
	# map_generator.mirror_x()
	# map_generator.copy_texture_to_final_bound(22, 0, 32, 24)
	map_generator.copy_texture_to_final_bound(0, 0, 32, 24)

	# map_generator.copy_texture_to_final()
	generate_map_from_array(map_generator.convert_with_chance_merge(.0, 1.0))

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

	

func _process(delta: float) -> void:
	var safe_delta: float = min(delta, 1. / 60)
	if Global.DEBUG:
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
			ball.released = true
			context.balls.push_back(ball)

			ball.randomize_velocity()

	
	# handling blocks before balls
	# this is bc multiball powerup might rotate the balls 
	# velocity of out the play area
	# TODO: this might've been bc of delta becoming too high
	# investigate with safe_delta and move back if neccessary
	for block: BreakableBlock in context.blocks:
		if block.is_broken():
			continue
		
		for line: LineCollider in block.collision:

			for ball: Ball in context.balls:
				if ball.collide_with(line, block.type != BreakableBlock.BlockType.ICE):
					block.hit_block(ball)


			if block.is_broken():
				if block.has_powerup:
					block.has_powerup = false
					spawn_powerup(block)
				
				context.broken_block_count += 1
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
		var ball_mesh: MeshInstance3D = ball_parent.get_child(index)

		if ball.collide_with(context.death_barrier, false, false):	
			if context.balls.size() > 1:
				context.balls.erase(ball)
				ball_mesh.queue_free()
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
		ball.collide_with_paddle(context.paddle)

	
	# update powerups
	for powerup: Powerup in context.powerups:
		powerup.move(safe_delta)
		powerup.asset.position.x = powerup.position.x
		powerup.asset.position.z = powerup.position.y
		powerup.asset.position.y = 16.0 # TODO: remove magic number (this is ball.radius * 2)

		collide_with_screen(powerup)

		# powerup picked up logic
		# TODO: move to its own function
		if powerup.collide_with_paddle(context.paddle):
			powerup.activate_powerup(context)
			context.powerups.erase(powerup)
			debug_parent.remove_child(powerup.asset)
		
		if powerup.position.y > BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE * 1.5:
			context.powerups.erase(powerup)
			debug_parent.remove_child(powerup.asset)



	# if collided:
	# 	ball.boost()

	# ball_mesh.global_position.x = ball.position.x
	# ball_mesh.global_position.z = ball.position.y
	# ball_mesh.global_position.y = ball.radius
	for i in context.balls.size():
		var ball: Ball = context.balls[i]
		var ball_mesh: MeshInstance3D
		if ball_parent.get_child_count() > i: 
			ball_mesh = ball_parent.get_child(i)
		else:
			# NOTE: handling mesh creation here 
			# bc i want to separate logic from visuals
			ball_mesh = ball_mesh_scene.instantiate()
			ball_parent.add_child(ball_mesh)


		ball_mesh.global_position.x = ball.position.x
		ball_mesh.global_position.z = ball.position.y
		ball_mesh.global_position.y = ball.radius


	paddle_mesh.global_position.x = context.paddle.position.x
	paddle_mesh.global_position.z = context.paddle.position.y
	paddle_mesh.global_position.y = context.paddle.height / 2

func set_up_screen_collision() -> void:
	var screen_bounds: Vector2 = DisplayServer.window_get_size()

	var grid_unit_size: Vector2 = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
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

		block.asset_ref = block_mesh

		context.blocks.push_back(block)

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

	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 16
	mesh.mesh.height = 32
	debug_parent.add_child(mesh)

	powerup.asset = mesh

	context.powerups.push_back(powerup)
