extends Node
class_name Paddle

@export
var size: float = 128.0
@export
var height: float = 16.0

var position: Vector2 = Vector2.ZERO
var desired_pos: Vector2 = Vector2.ZERO

# TODO: feels good, but might need more tweaking
var LERP_SPEED: float = 0.9 * 20
var LERP_LIMIT: float = 1.0


var reflection_angle: float = PI / 4

var line: LineCollider = LineCollider.new()


func _ready() -> void:
	set_line()

func set_line() -> void:
	line.set_points(
		position + Vector2(-size / 2 - Global.DEFAULT_BALL_RADIUS, -height / 2),
		position + Vector2(+size / 2 + Global.DEFAULT_BALL_RADIUS, -height / 2),
	)

func lerp_move(delta: float) -> void:
	# position.x += movement.x
	position.x = lerp(position.x, desired_pos.x, LERP_SPEED * delta)
	if abs(position.x - desired_pos.x) <= LERP_LIMIT:
		position.x = desired_pos.x



	position.y = (BreakableGrid.GRID_SIZE.y / 2 - 1) * BreakableGrid.CELL_SIZE

	set_line()

func move_desired_pos(movement: Vector2) -> void:
	desired_pos.x += movement.x * Global.PLAYER_SENSITIVITY

	var limits: float = BreakableGrid.GRID_SIZE.x * BreakableGrid.CELL_SIZE / 2 - (size / 2)

	if desired_pos.x > limits:
		desired_pos.x = limits
	elif desired_pos.x < - limits:
		desired_pos.x = - limits

func get_left_side() -> Vector2:
	return position - Vector2(size / 2, 0)

func get_right_side() -> Vector2:
	return position + Vector2(size / 2, 0)
