extends Node3D
# class_name # not requiered for test

@onready var block_mesh_scene: PackedScene = preload("res://visuals/BlockMesh.tscn")

@onready var ball_mesh: MeshInstance3D = %BallMesh
@onready var paddle_mesh: MeshInstance3D = %PaddleMesh
@onready var block_parent: Node3D = %Blocks
@onready var mouse_input_handler: MouseInputHandler = %MouseInputHandler


var ball: Ball = Ball.new()
var paddle: Paddle = Paddle.new()

var screen_collision: Array[LineCollider]
var death_barrier: LineCollider
var blocks: Array[BreakableBlock]

func _ready() -> void:
	# ball.randomize_velocity()

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	for i in 50:
		var block: BreakableBlock = BreakableBlock.new()

		block.pos_on_grid = Vector2i(randi_range(0, BreakableGrid.GRID_SIZE - 1), randi_range(0, BreakableGrid.GRID_SIZE / 2))
		block.size = Vector2i(randi_range(1, 5), randi_range(1, 5))
		block.prepare_collision()


		var block_mesh: BlockMesh = block_mesh_scene.instantiate()
		block_parent.add_child(block_mesh)
		block_mesh.set_visual_scale(block.size * BreakableGrid.CELL_SIZE)
		var final_pos: Vector2 = block.get_origin()
		block_mesh.global_position.x = final_pos.x
		block_mesh.global_position.z = final_pos.y
		block_mesh.global_position.y = BreakableGrid.CELL_SIZE / 2

		block.asset_ref = block_mesh

		blocks.push_back(block)


	mouse_input_handler.mouse_moved.connect(handle_mouse_movement)
	mouse_input_handler.release_ball_pressed.connect(release_ball)

	handle_mouse_movement(Vector2.ZERO)

	# paddle.collider_line.debug_set_up = false
	paddle.set_line(ball.radius)


func _process(delta: float) -> void:
	if !ball.released:
		ball.set_position(paddle.position + Vector2.UP * ball.radius * 2)
	else:
		ball.move(delta)

	# handle collision
	# check for death first
	if ball.collide_with(death_barrier, false):
		on_death()

	# var collided: bool = false

	for line in screen_collision:
		ball.collide_with(line)
	

	for block: BreakableBlock in blocks:
		if block.broken:
			continue
		
		for line: LineCollider in block.collision:
			if ball.collide_with(line):
				block.hit_block()

			if block.broken:
				break
			
	
	ball.collide_with_paddle(paddle)

	

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
