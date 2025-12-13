extends Node2D
# class_name # not requiered for test

class Ball:
	var radius: float = 16.0
	var position: Vector2
	var velocity: Vector2
	
	var target_velocity: float = 512.0
	
	var deceleration: float = 8.0
	
	var speed_up_factor: float = 2.0


@onready var collider_line_scene: PackedScene = preload("res://ColliderLine.tscn")
@onready var breakable_block_scene: PackedScene = preload("res://BreakableBlock.tscn")

@onready var ball_sprite: Sprite2D = %BallSprite
@onready var line_parent: Node2D = %Lines
@onready var block_parent: Node2D = %Blocks

var ball: Ball = Ball.new()

func _ready() -> void:
	ball.velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	ball.velocity *= ball.target_velocity

	# screen_bounds = DisplayServer.window_get_size()
	set_up_screen_collision()

	for i in 20:
		var block: BreakableBlock = breakable_block_scene.instantiate()

		block.pos_on_grid = Vector2i(randi_range(0, BreakableGrid.GRID_SIZE - 1), randi_range(0, BreakableGrid.GRID_SIZE - 1))
		block.size = Vector2i(randi_range(1, 5), randi_range(1, 5))
		block_parent.add_child(block)
		block.prepare_collision()



func _process(delta: float) -> void:
	if ball.velocity.length() > ball.target_velocity:
		ball.velocity = ball.velocity.normalized() * (ball.velocity.length() - ball.deceleration)
	else:
		ball.velocity = ball.velocity.normalized() * ball.target_velocity
	
	ball.position += ball.velocity * delta

	# handle collision
	var collided: bool = false

	for collider_line in line_parent.get_children():
		collided = collided || handle_line_collision(collider_line)
	
	for block in block_parent.get_children():
		for collider_line: ColliderLine in block.line_parent.get_children():
			collided = collided || handle_line_collision(collider_line)

	

	if collided:
		ball.velocity = ball.velocity.normalized() * ball.target_velocity * ball.speed_up_factor

	ball_sprite.global_position = ball.position

func set_up_screen_collision() -> void:
	var screen_bounds: Vector2 = DisplayServer.window_get_size()

	# var p1: Vector2 = Vector2(-screen_bounds.x / 2, -screen_bounds.y / 2)
	# var p2: Vector2 = Vector2(screen_bounds.x / 2, -screen_bounds.y / 2)
	# var p3: Vector2 = Vector2(screen_bounds.x / 2, screen_bounds.y / 2)
	# var p4: Vector2 = Vector2(-screen_bounds.x / 2, screen_bounds.y / 2)

	var grid_unit_size: Vector2 = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE
	var p1: Vector2 = Vector2(-grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p2: Vector2 = Vector2(grid_unit_size.x / 2, -grid_unit_size.y / 2)
	var p3: Vector2 = Vector2(grid_unit_size.x / 2, grid_unit_size.y / 2)
	var p4: Vector2 = Vector2(-grid_unit_size.x / 2, grid_unit_size.y / 2)

	var line: ColliderLine = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p1, p2)

	line = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p2, p3)

	line = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p3, p4)

	line = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p4, p1)




# func handle_screen_collision() -> bool:
# 	var collided: bool = false
# 	# collision on Y
# 	if ball.velocity.y > 0:
# 		if ball.position.y + ball.radius > screen_bounds.y / 2:
# 			ball.velocity.y *= -1
# 			ball.position.y -= screen_bounds.y / 2 - (ball.position.y + ball.radius)
# 			collided = true
# 	else:
# 		if ball.position.y - ball.radius < -screen_bounds.y / 2:
# 			ball.velocity.y *= -1
# 			ball.position.y +=  -screen_bounds.y / 2 - (ball.position.y - ball.radius)
# 			collided = true
	
# 	# collision on X
# 	if ball.velocity.x > 0:
# 		if ball.position.x + ball.radius > screen_bounds.x / 2:
# 			ball.velocity.x *= -1
# 			ball.position.x -= screen_bounds.x / 2 - (ball.position.x + ball.radius)
# 			collided = true
# 	else:
# 		if ball.position.x - ball.radius < -screen_bounds.x / 2:
# 			ball.velocity.x *= -1
# 			ball.position.x +=  -screen_bounds.x / 2 - (ball.position.x - ball.radius)
# 			collided = true
	
# 	return collided

func handle_line_collision(line: ColliderLine) -> bool:
	var collided: bool = false

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
			ball.velocity = ball.velocity.rotated(2 * angle)

			collided = true
		



	# print(distance_from_line)

	return collided
