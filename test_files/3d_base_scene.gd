extends Node3D
# class_name # not requiered for test

@onready var block_mesh_scene: PackedScene = preload("res://visuals/BlockMesh.tscn")

@onready var ball_mesh: MeshInstance3D = %BallMesh
@onready var paddle_mesh: MeshInstance3D = %PaddleMesh
@onready var block_parent: Node3D = %Blocks
@onready var mouse_input_handler: MouseInputHandler = %MouseInputHandler

@onready var debug_parent: Node3D = %Debug

var ball: Ball = Ball.new()
var paddle: Paddle = Paddle.new()

var screen_collision: Array[LineCollider]
var death_barrier: LineCollider
var blocks: Array[BreakableBlock]

var broken_block_count: int = 0
var nr_metal_blocks: int = 0

var powerups: Array[Powerup]

func _ready() -> void:
	# ball.randomize_velocity()

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	generate_map()



	mouse_input_handler.mouse_moved.connect(handle_mouse_movement)
	mouse_input_handler.release_ball_pressed.connect(release_ball)

	handle_mouse_movement(Vector2.ZERO)

	# paddle.collider_line.debug_set_up = false
	paddle.set_line(ball.radius)

	

func _process(delta: float) -> void:
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

			powerups.push_back(powerup)
		


	if !ball.released:
		ball.set_position(paddle.position + Vector2.UP * ball.radius * 2)
	else:
		ball.move(delta)

	# handle collision
	# check for death first
	if ball.collide_with(death_barrier, false, false):
		on_death()

	# var collided: bool = false

	for line in screen_collision:
		ball.collide_with(line, true)
	

	for block: BreakableBlock in blocks:
		if block.is_broken():
			continue
		
		for line: LineCollider in block.collision:
			if ball.collide_with(line, block.type != BreakableBlock.BlockType.ICE):
				block.hit_block(ball)
				if block.has_powerup:
					block.has_powerup = false
					spawn_powerup(block)


			if block.is_broken():
				broken_block_count += 1
				break
	
	if are_breakable_blocks_remaining():
		# TODO: change blocks to breakable if only non-breakable remain
		on_board_clear()
		return
	
	ball.collide_with_paddle(paddle)

	
	# update powerups
	for powerup: Powerup in powerups:
		powerup.move(delta)
		powerup.asset.position.x = powerup.position.x
		powerup.asset.position.z = powerup.position.y
		powerup.asset.position.y = ball.radius * 2

		collide_with_screen(powerup)

		# powerup picked up logic
		# TODO: move to its own function
		if powerup.collide_with_paddle(paddle):
			powerups.erase(powerup)
			debug_parent.remove_child(powerup.asset)
		
		if powerup.position.y > BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE * 1.5:
			powerups.erase(powerup)
			debug_parent.remove_child(powerup.asset)



	# if collided:
	# 	ball.boost()

	ball_mesh.global_position.x = ball.position.x
	ball_mesh.global_position.z = ball.position.y
	ball_mesh.global_position.y = ball.radius
	paddle_mesh.global_position.x = paddle.position.x
	paddle_mesh.global_position.z = paddle.position.y
	paddle_mesh.global_position.y = paddle.height / 2

func set_up_screen_collision() -> void:
	var screen_bounds: Vector2 = DisplayServer.window_get_size()

	var grid_unit_size: Vector2 = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var p1: Vector2 = Vector2(-grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p2: Vector2 = Vector2(grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p3: Vector2 = Vector2(grid_unit_size.x / 2, grid_unit_size.y / 2)
	var p4: Vector2 = Vector2(-grid_unit_size.x / 2, grid_unit_size.y / 2)

	var line: LineCollider = LineCollider.new()
	line.set_points(p1, p2)
	screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p2, p3)
	screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p4, p1)
	screen_collision.push_back(line)

	# This is the death barrier
	death_barrier = LineCollider.new()
	death_barrier.set_points(p3, p4)


# TODO: I dont like this being alone with a signal. 
# might cause headache lter when debugging
func handle_mouse_movement(movement: Vector2) -> void:
	paddle.move(movement)


func release_ball() -> void:
	ball.randomize_velocity()
	ball.released = true

# Handle any logic for death
func on_death() -> void:
	ball.velocity = Vector2.ZERO
	ball.released = false

func generate_map() -> void:
	for child in block_parent.get_children():
		child.queue_free()
	blocks.clear()

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
				nr_metal_blocks += 1
			block.prepare_collision()

			if randf() < .3:
				block.has_powerup = true
				block.powerup = Powerup.new()

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

			blocks.push_back(block)

			total += block_size

func on_board_clear() -> void:
	# TODO: this resets the ball. shouldn't use death entrypoint for this tho
	on_death()

	broken_block_count = 0
	generate_map()

func are_breakable_blocks_remaining() -> bool:
	return broken_block_count >= blocks.size() - nr_metal_blocks

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

	powerups.push_back(powerup)
