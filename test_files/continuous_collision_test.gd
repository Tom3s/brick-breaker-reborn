@tool
extends Node2D

@onready var line_a: Marker2D = %LineA
@onready var line_b: Marker2D = %LineB
@onready var ball_pos_prev: Marker2D = %BallPosPrev
@onready var ball_pos_current: Marker2D = %BallPosCurrent

@export
var radius: float = 8.0

var line: LineCollider = LineCollider.new()

var ball: Ball = Ball.new()

func _ready() -> void:
	_set_points()

var prev_a: Vector2
var prev_b: Vector2

var debug_calls: Array[Callable] = []

func _process(delta: float) -> void:
	# if line_a.global_position != prev_a || line_b.global_position != prev_b:
	_set_points()
	_set_ball()

	var result := line.collide_with_ball(ball)

	if result.collided:
		debug_calls.push_back(
			func() -> void:
				draw_circle(result.contact_point, 3, Color.CYAN) 
		)

		debug_calls.push_back(
			func() -> void:
				draw_circle(
					result.position, ball.radius,
					Color.YELLOW,
					false
				)
				# print(result.position)
		)

	# line.debug_visual.draw_debug()
	queue_redraw()

	prev_a = line_a.global_position
	prev_b = line_b.global_position

func _draw() -> void:
	draw_line(
		line.p1,
		line.p2,
		Color.PINK
	)

	draw_line(
		(line.p1 + line.p2) / 2,
		((line.p1 + line.p2) / 2) + line.normal * 10.0,
		Color.GREEN_YELLOW
	)

	draw_circle(
		ball.position, ball.radius,
		Color.RED,
		false
	)
	draw_circle(
		ball.position - ball.velocity, ball.radius,
		Color.RED,
		false
	)

	for debug_draw in debug_calls:
		debug_draw.call()

	debug_calls.clear()

func _set_points() -> void:
	line.set_points(line_a.global_position, line_b.global_position)

func _set_ball() -> void:
	ball.position = ball_pos_current.global_position
	ball.velocity = ball_pos_current.global_position - ball_pos_prev.global_position
	ball.radius = radius