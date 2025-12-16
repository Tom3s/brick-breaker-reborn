extends Node2D
# class_name # not requiered for test

class BallClass:
	var radius: float = 16.0
	var position: Vector2
	var velocity: Vector2
	
	var target_velocity: float = 512.0
	
	var deceleration: float = 8.0
	
	var speed_up_factor: float = 2.0


@onready var collider_line_scene: PackedScene = preload("res://ColliderLine.tscn")
@onready var breakable_block_scene: PackedScene = preload("res://BreakableBlock.tscn")

@onready var ball_sprite: Sprite2D = %BallSprite
@onready var paddle_sprite: Sprite2D = %PaddleSprite
@onready var block_parent: Node2D = %Blocks
@onready var mouse_input_handler: MouseInputHandler = %MouseInputHandler


var ball: Ball = Ball.new()
var paddle: Paddle = Paddle.new()

var screen_collision: Array[LineCollider]
var blocks: Array[BreakableBlock]

func _ready() -> void:
	ball.randomize_velocity()

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	for i in 50:
		var block: BreakableBlock = BreakableBlock.new()

		block.pos_on_grid = Vector2i(randi_range(0, BreakableGrid.GRID_SIZE - 1), randi_range(0, BreakableGrid.GRID_SIZE / 2))
		block.size = Vector2i(randi_range(1, 5), randi_range(1, 5))
		block.prepare_collision()

		var block_sprite: Sprite2D = Sprite2D.new()
		block_parent.add_child(block_sprite)
		block_sprite.texture = PlaceholderTexture2D.new()
		block_sprite.texture.size = block.size * BreakableGrid.CELL_SIZE
		block_sprite.global_position = block.get_origin()

		block.asset_ref = block_sprite

		blocks.push_back(block)


	mouse_input_handler.mouse_moved.connect(handle_mouse_movement)

	handle_mouse_movement(Vector2.ZERO)

	# paddle.collider_line.debug_set_up = false
	paddle.set_line(ball.radius)


func _process(delta: float) -> void:
	ball.move(delta)

	# handle collision
	var collided: bool = false

	for line in screen_collision:
		ball.collide_with(line)
	
	# for block in block_parent.get_children():
	# 	for collider_line: ColliderLine in block.line_parent.get_children():
	# 		if block.broken:
	# 			continue
	# 		block.broken = handle_line_collision(collider_line)
	# 		collided = collided || block.broken
	for block: BreakableBlock in blocks:
		if block.broken:
			continue
		
		for line: LineCollider in block.collision:
			if ball.collide_with(line):
				block.hit_block()

			if block.broken:
				print("Block was broken")
				break
			
	
	ball.collide_with_paddle(paddle)

	

	if collided:
		ball.boost()

	ball_sprite.global_position = ball.position
	paddle_sprite.global_position = paddle.position

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
	line.set_points(p3, p4)
	screen_collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p4, p1)
	screen_collision.push_back(line)




func handle_line_collision(line: ColliderLine) -> bool:
	var collided: bool = false

	# TODO: collider line should abstract p1 and p2, use them instead of accessing debug point coordinates
	var p1: Vector2 = line.debug_point1.global_position
	var p2: Vector2 = line.debug_point2.global_position

	var moving_towards_line: bool = ball.velocity.dot(line.normal) < 0

	line.set_moving_towards(moving_towards_line)

	# idfk what im doing here, but it's dot product magic
	# for more info see: https://youtu.be/nXrEX6j-Mws?si=8GdqyyBu0hQkDFsm&t=224
	var distance_from_line: float = (ball.position - p1).dot(line.normal)

	if distance_from_line < 0:
		return collided
	
	distance_from_line = abs(distance_from_line)

	var case: float = (ball.position - p1).dot(line.tangent)

	var current_normal: Vector2 = line.normal

	if case < 0:
		distance_from_line = (ball.position - p1).length()
		current_normal = (ball.position - p1).normalized()
	elif case > (p1 - p2).length():
		distance_from_line = (ball.position - p2).length()
		current_normal = (ball.position - p2).normalized()

	if (distance_from_line < ball.radius):
		var speed_along_normal: float = ball.velocity.dot(current_normal)

		if speed_along_normal <= 0:
			var correction: float = ball.radius - distance_from_line

			ball.position += current_normal * correction * 2

			ball.velocity *= -1
			var angle: float = ball.velocity.angle_to(current_normal)
			ball.velocity = ball.velocity.rotated(2 * angle) # TODO: set proper speed, this relies on the collision speed up logic

			collided = true
		
	return collided


func handle_mouse_movement(movement: Vector2) -> void:
	paddle.move(movement)
