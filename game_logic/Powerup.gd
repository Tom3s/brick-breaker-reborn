extends Node
class_name Powerup

enum Type {
	NONE,
	BALL_MULTIPLY,
	FIRE_BALL,
}

var ball_multiply_value: int = 3

var fire_ball_max_time: float = 15.0

var type: Type = Type.NONE



var position: Vector2
var velocity: Vector2

var start_velocity: float = 128.0

var asset: Node3D

var grace_distance: float = 16.0

var infinite: bool = true

var time_left: float = 0.0

func randomize_velocity() -> void:
	velocity = Vector2(randf_range(-0.5, 0.5), -1).normalized()
	velocity *= start_velocity

func move(delta: float) -> void:
	velocity += Vector2.DOWN * Global.GRAVITY * delta

	position += velocity * delta

func collide_with_paddle(paddle: Paddle) -> bool:
	var line: LineCollider = paddle.line

	var p1: Vector2 = line.p1 + paddle.position
	var p2: Vector2 = line.p2 + paddle.position

	if p1.x < position.x || p2.x > position.x:
		return false
	
	if abs(position.y - p1.y) < grace_distance:
		return true
	
	return false

func activate_powerup(context: Global.GameContext) -> void:
	if type == Type.NONE:
		return
	
	if type == Type.BALL_MULTIPLY:
		var original_ball_count: int = context.balls.size()

		for ball_index in original_ball_count:
			var ball: Ball = context.balls[ball_index]

			for i in ball_multiply_value:
				if i == 0:
					continue
				
				var new_ball: Ball = Ball.new()
				new_ball.released = true

				new_ball.position = ball.position
				new_ball.velocity = ball.velocity.rotated(
					float(i) / ball_multiply_value * 2 * PI
				)

				context.balls.push_back(new_ball)
	
	elif type == Type.FIRE_BALL:
		time_left = fire_ball_max_time
		infinite = false
		
		context.active_powerups.push_back(self)



