extends Node
class_name Paddle

@export
var size: float = 128.0
@export
var height: float = 16.0

var position: Vector2 = Vector2.ZERO


var reflection_angle: float = PI / 4

var line: LineCollider = LineCollider.new()


func _ready() -> void:
	set_line()

func set_line() -> void:
	line.set_points(
		position + Vector2(+size / 2 + Global.DEFAULT_BALL_RADIUS, -height / 2),
		position + Vector2(-size / 2 - Global.DEFAULT_BALL_RADIUS, -height / 2),
	)

func move(movement: Vector2) -> void:
	position.x += movement.x

	var limits: float = BreakableGrid.GRID_SIZE.x * BreakableGrid.CELL_SIZE / 2 - (size / 2)

	if position.x > limits:
		position.x = limits
	elif position.x < - limits:
		position.x = - limits

	position.y = (BreakableGrid.GRID_SIZE.y / 2 - 1) * BreakableGrid.CELL_SIZE

	set_line()

func get_left_side() -> Vector2:
	return position - Vector2(size / 2, 0)

func get_right_side() -> Vector2:
	return position + Vector2(size / 2, 0)
