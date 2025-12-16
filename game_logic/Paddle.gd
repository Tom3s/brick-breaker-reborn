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

func set_line(radius: float = 0.0) -> void:
	line.set_points(
		Vector2(+size / 2 + radius, -height / 2),
		Vector2(-size / 2 - radius, -height / 2),
	)

func move(movement: Vector2) -> void:
	position.x += movement.x

	var limits: float = BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE / 2 - (size / 2)

	if position.x > limits:
		position.x = limits
	elif position.x < - limits:
		position.x = - limits

	position.y = (BreakableGrid.GRID_SIZE / 2 - 1) * BreakableGrid.CELL_SIZE
