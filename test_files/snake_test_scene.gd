extends Node2D

var snake: Snake = Snake.new()

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	snake.init_snake()

	# for i in 5:
	# 	snake.spawn_random_food(rng)
	snake.refill_food(rng)
	
	snake.direction = Vector2i.RIGHT

	snake.calculate_nav_grid()

var last_move: float = 0.0
var move_treshold: float = 0 # 1.0 / 10

func _process(delta: float) -> void:
	var grown: bool = false

	if snake.navigator.next_step != Vector2i.MIN:
		snake.set_nav_direction()
	else:
		move_treshold = 1 / 10.0

	if Input.is_action_just_pressed("debug_snake_up"):
		snake.direction = Vector2i.UP
		last_move = move_treshold

	elif Input.is_action_just_pressed("debug_snake_down"):
		snake.direction = Vector2i.DOWN
		last_move = move_treshold

	elif Input.is_action_just_pressed("debug_snake_left"):
		snake.direction = Vector2i.LEFT
		last_move = move_treshold

	elif Input.is_action_just_pressed("debug_snake_right"):
		snake.direction = Vector2i.RIGHT
		last_move = move_treshold
	
	if last_move >= move_treshold:
		grown = snake.update()
		last_move -= move_treshold
		snake.calculate_nav_grid()


	if grown:
		snake.refill_food(rng)
	

	last_move += delta

	queue_redraw()


var rect_size: int = 32
var checker_colors: Array[Color] = [
	Color.DARK_GRAY,
	Color.LIGHT_GRAY,
]

var cell_colors: Array[Color] = [
	Color.TRANSPARENT,
	Color.RED,
	Color.GREEN,
	Color.YELLOW,
	Color.DARK_BLUE,
]

func _draw() -> void:
	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var cell: Snake.SnakeCell = snake.grid.get_cell(Vector2i(x, y))

			if cell == Snake.SnakeCell.NONE:
				draw_rect(
					Rect2(
						x * rect_size,
						y * rect_size,
						rect_size, rect_size
					),
					checker_colors[(x + y) % 2]
				)
			
			else:
				draw_rect(
					Rect2(
						x * rect_size,
						y * rect_size,
						rect_size, rect_size
					),
					cell_colors[int(cell)]
				)
	
	
	# for x in BreakableGrid.GRID_SIZE.x:
	# 	for y in BreakableGrid.GRID_SIZE.y:
