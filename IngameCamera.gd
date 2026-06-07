extends Camera2D
class_name IngameCamera

var padding: float = 32.0

func _process(delta: float) -> void:
	var current_resolution: Vector2 = DisplayServer.window_get_size()

	# var min_square_size: Vector2 = Vector2(min(current_resolution.x, current_resolution.y), min(current_resolution.x, current_resolution.y))

	if current_resolution.x < current_resolution.y:
		zoom = Vector2.ONE * (current_resolution.x / (BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE + padding))
	else:
		zoom = Vector2.ONE * (current_resolution.y / (BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE + padding))


