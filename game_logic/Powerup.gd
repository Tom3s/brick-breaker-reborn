extends Node
class_name Powerup

var ball_mesh_scene: PackedScene = load("res://visuals/BallMesh.tscn")

enum Type {
	NONE,
	BALL_MULTIPLY,
	FIRE_BALL,
	LASER,
	GUN,
	KEY,
	ICE_BALL,
	MINE_BALL,
	TUNNEL,
}

# static var weights: PackedInt32Array = [
# 	0,
# 	0,
# 	0,
# 	0,
# 	0,
# 	0,
# 	0,
# 	0,
# 	1,
# ]
static var weights: PackedInt32Array = [
	0, # NONE - should always be 0
	3, # BALL_MULTIPLY
	6, # FIRE_BALL
	1, # LASER
	4, # GUN
	0, # KEY - should always be 0
	6, # ICE_BALL
	4, # MINE_BALL
	2, # TUNNEL
]

var ball_multiply_value: int = 3

var fire_ball_max_time: float = 15.0

var ice_ball_max_time: float = 15.0
var mine_ball_max_time: float = 15.0
static var ice_ball_radius: float = BreakableGrid.CELL_SIZE * 4
static var mine_ball_radius: float = BreakableGrid.CELL_SIZE * 4

var laser_max_shots: int = 3
var laser_cooldown: float = 1.0
var laser_shots_left: int = 0
var laser_shot: bool = false

var gun_max_time: float = 10.0
var tunnel_max_time: float = 10.0

# TODO: move this to ball damage calculation
static var mine_ball_damage: int = 3


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

	var p1: Vector2 = line.p1
	var p2: Vector2 = line.p2

	if p1.x > position.x || p2.x < position.x:
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
				
				if context.balls.size() >= Global.BALL_LIMIT:
					return
				
				var new_ball: Ball = Ball.new()
				new_ball.asset_ref = ball_mesh_scene.instantiate()

				new_ball.released = true

				new_ball.position = ball.position
				new_ball.velocity = ball.velocity.rotated(
					float(i) / ball_multiply_value * 2 * PI
				)

				context.balls.push_back(new_ball)
	
	elif type == Type.FIRE_BALL:
		time_left = fire_ball_max_time
		infinite = false

		context.add_ball_powerup(self)
	
	elif type == Type.ICE_BALL:
		time_left = ice_ball_max_time
		infinite = false
		
		context.add_ball_powerup(self)
	
	elif type == Type.MINE_BALL:
		time_left = mine_ball_max_time
		infinite = false
		
		context.add_ball_powerup(self)
	
	elif type == Type.LASER:
		time_left = laser_cooldown
		laser_shots_left = laser_max_shots

		context.active_powerups.push_back(self)
	
	elif type == Type.GUN:
		time_left = gun_max_time

		context.active_powerups.push_back(self)

	elif type == Type.TUNNEL:
		time_left = tunnel_max_time

		context.active_powerups.push_back(self)
	
	elif type == Type.KEY:
		context.enable_key()

func update(delta: float) -> void:
	time_left -= delta

	if type == Type.LASER:
		if time_left < 0.0 && laser_shots_left > 0:
			time_left = laser_cooldown
			laser_shots_left -= 1
			laser_shot = true
		else:
			laser_shot = false

static func get_weighted_powerup(n: float) -> Type:
	var total_weight: int
	for w in weights:
		total_weight += w
	
	var partial_weight: float = n * total_weight
	var current_weight: int = 0

	for i in weights.size():
		current_weight += weights[i]
		if current_weight > partial_weight:
			LoggerMogyi.log(null, "Selected %s with (%d/%d) for %.3f" % [
				Type.keys()[i].capitalize(),
				partial_weight,
				total_weight,
				n
			])
			return i as Type
	
	return Type.NONE