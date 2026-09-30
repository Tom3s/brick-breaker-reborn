extends TextureRect

var snake: Snake

var rect_size: int = 32
var offset: Vector2i = Vector2i(128, 64)
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
	if snake == null:
		return

	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var cell: Snake.SnakeCell = snake.grid.get_cell(Vector2i(x, y))

			if cell == Snake.SnakeCell.NONE:
				draw_rect(
					Rect2(
						x * rect_size + offset.x,
						y * rect_size + offset.y,
						rect_size, rect_size
					),
					checker_colors[(x + y) % 2]
				)
			
			else:
				draw_rect(
					Rect2(
						x * rect_size + offset.x,
						y * rect_size + offset.y,
						rect_size, rect_size
					),
					cell_colors[int(cell)]
				)
