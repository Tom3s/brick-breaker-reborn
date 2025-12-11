extends Sprite2D
class_name PrimitiveBall

@export
var radius: float = 8.0
var pos: Vector2
var velocity: Vector2
@export
var target_velocity: float = 512.0
@export
var deceleration: float = 16.0
@export
var speed_up_factor: float = 2.5

var screen_bounds: Vector2

func _ready() -> void:
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() #TODO: uniform randomization
	# note: uniform distribution might not be necessary as later the ball control will be different
	velocity *= target_velocity

	screen_bounds = DisplayServer.window_get_size()
	print(get_script().resource_path.get_file(), " Screen resolution: ", screen_bounds)

func _process(delta: float) -> void:
	if velocity.length() > target_velocity:
		velocity = velocity.normalized() * (velocity.length() - deceleration)
	else:
		velocity = velocity.normalized() * target_velocity
	
	pos += velocity * delta

	# handle collision
	var collided: bool = false
	# collision on Y
	if velocity.y > 0:
		if pos.y + radius > screen_bounds.y / 2:
			velocity.y *= -1
			pos.y -= screen_bounds.y / 2 - (pos.y + radius)
			collided = true
	else:
		if pos.y - radius < -screen_bounds.y / 2:
			velocity.y *= -1
			pos.y +=  -screen_bounds.y / 2 - (pos.y - radius)
			collided = true
	
	# collision on X
	if velocity.x > 0:
		if pos.x + radius > screen_bounds.x / 2:
			velocity.x *= -1
			pos.x -= screen_bounds.x / 2 - (pos.x + radius)
			collided = true
	else:
		if pos.x - radius < -screen_bounds.x / 2:
			velocity.x *= -1
			pos.x +=  -screen_bounds.x / 2 - (pos.x - radius)
			collided = true

	if collided:
		velocity = velocity.normalized() * target_velocity * speed_up_factor

	global_position = pos

	# TODO: fine tune this
	# target_velocity += delta * 8