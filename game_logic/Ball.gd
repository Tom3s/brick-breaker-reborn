extends Node
class_name Ball

@export
var radius: float = 16.0

@export
var target_velocity: float = 512.0

@export
var deceleration: float = 8.0

@export
var speed_up_factor: float = 2.0



var position: Vector2
var velocity: Vector2

func randomize_velocity() -> void:
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity *= target_velocity

## Approches target_velocity and moves the ball with factor `delta`
func move(delta: float) -> void:
	if velocity.length() > target_velocity:
		velocity = velocity.normalized() * (velocity.length() - deceleration)
	else:
		velocity = velocity.normalized() * target_velocity
	
	position += velocity * delta

## Will set the velocity to `target_velocity * speed_up_factor`
func boost() -> void:
	velocity = velocity.normalized() * target_velocity * speed_up_factor


func collide_with(line: LineCollider, boost_on_collision: bool = true) -> void:

	# TODO: collider line should abstract p1 and p2, use them instead of accessing debug point coordinates
	var p1: Vector2 = line.p1
	var p2: Vector2 = line.p2

	var moving_towards_line: bool = velocity.dot(line.normal) < 0

	# idfk what im doing here, but it's dot product magic
	# for more info see: https://youtu.be/nXrEX6j-Mws?si=8GdqyyBu0hQkDFsm&t=224
	var distance_from_line: float = (position - p1).dot(line.normal)

	if distance_from_line < 0:
		return
	
	distance_from_line = abs(distance_from_line)

	var case: float = (position - p1).dot(line.tangent)

	var current_normal: Vector2 = line.normal

	if case < 0:
		distance_from_line = (position - p1).length()
		current_normal = (position - p1).normalized()
	elif case > (p1 - p2).length():
		distance_from_line = (position - p2).length()
		current_normal = (position - p2).normalized()

	if (distance_from_line < radius):
		var speed_along_normal: float = velocity.dot(current_normal)

		if speed_along_normal <= 0:
			var correction: float = radius - distance_from_line

			position += current_normal * correction * 2

			velocity *= -1
			var angle: float = velocity.angle_to(current_normal)
			velocity = velocity.rotated(2 * angle) # TODO: set proper speed, this relies on the collision speed up logic

			# collided = true
			if boost_on_collision:
				boost()


func collide_with_paddle(paddle: Paddle, boost_on_collision: bool = true) -> void:
	var line: LineCollider = paddle.line

	var p1: Vector2 = line.p1 + paddle.position
	var p2: Vector2 = line.p2 + paddle.position

	var moving_towards_line: bool = velocity.dot(line.normal) < 0
	if !moving_towards_line:
		return 

	var distance_from_line: float = (position - p1).dot(line.normal)
	if distance_from_line < 0:
		return 

	var case: float = (position - p1).dot(line.tangent)

	if case < 0 || case > (p1 - p2).length():
		return 

	var t: float = case / (p1 - p2).length()

	var reflection_angle: float = lerpf(paddle.reflection_angle, -paddle.reflection_angle, t)

	if (distance_from_line < radius):
		var speed_along_normal: float = velocity.dot(line.normal)

		if speed_along_normal <= 0:
			var correction: float = radius - distance_from_line

			position += line.normal * correction * 2
			velocity = Vector2.UP.rotated(reflection_angle)

			if boost_on_collision:
				boost()
	
	return 
