extends Node
class_name LineCollider

var p1: Vector2
var p2: Vector2

var tangent: Vector2
var normal: Vector2

var debug_visual: DebugVisual

class LineBallCollisionResult:
	var collided: bool = false
	var position: Vector2
	var velocity: Vector2

	var contact_point: Vector2
	var contact_distance: float

# func _ready() -> void:
# 	calculate_normals()
func _init() -> void:
	calculate_normals()
	

func calculate_normals() -> void:
	tangent = (p2 - p1).normalized()
	normal = tangent.rotated(- PI / 2)
	# rotating in negative trigo direction bc 2D coordinates 
	# go downwards. This caused all lines to be flipped
	debug_visual = DebugVisual.new(
		DebugVisual.Type.LINE_2D,
		self,
	)

func set_points(p1_new: Vector2, p2_new: Vector2) -> void:
	p1 = p1_new
	p2 = p2_new

	calculate_normals()

# func get_debug_visual(offset: Vector2) -> DebugVisual:

func collide_with_ball(ball: Ball) -> LineBallCollisionResult:
	var result: LineBallCollisionResult = LineBallCollisionResult.new()

	var ball_pos: Vector2 = ball.position
	var ball_prev: Vector2 = ball.position - ball.velocity

	# d = (x2 - x1) * (y - y1) - (y2 - y1) * (x - x_1)
	# var curr_side: float = (p2.x - p1.x) * (ball_pos.y - p1.y) - (p2.y - p1.y) * (ball_pos.x - p1.x)
	# if curr_side > 0:
	# 	return result

	if ball.velocity.cross(p2 - p1) > 0:
		return result

	var prev_side: float = (p2.x - p1.x) * (ball_prev.y - p1.y) - (p2.y - p1.y) * (ball_prev.x - p1.x)
	if prev_side > 0:
		return result

	var intersect_point: Vector2 = Geometry2D.line_intersects_line(
		p1, p2 - p1,
		ball.position, ball.velocity
	)


	result.collided = intersect_point != null

	if result.collided:
		var intersect_angle: float = (ball_pos - ball_prev).angle_to(p2 - p1)
		if intersect_angle > PI / 2:
			intersect_angle = PI - intersect_angle
		
		intersect_angle = (PI / 2) - intersect_angle

		var leg: float = ball.radius * tan(intersect_angle)

		var contact_point: Vector2 = (p2 - p1).normalized() * leg + intersect_point

		# var t: float = inverse_lerp(p1, p2, contact_point)
		var t: float = _inv_lerp_vec2(p1, p2, contact_point)

		# if t < 0.0 || t > 1.0:
		# 	result.collided = false
		# 	return result

		# collides on line
		if t >= 0.0 && t <= 1.0:
			result.contact_point = contact_point

			var ball_pos_at_contact: Vector2 = (contact_point + normal * ball.radius)

			if (ball_pos_at_contact - ball_prev).length() > ball.velocity.length():
				result.collided = false
				return result

			var error_since_contact: Vector2 = ball_pos - ball_pos_at_contact

			var reflected_error: Vector2 = _reflect(error_since_contact, normal)

			result.position = ball_pos_at_contact + reflected_error
			result.velocity = (result.position - ball_pos_at_contact).normalized() * ball.velocity.length()
			result.contact_distance = (contact_point - ball_prev).length()

			return result
		elif t > 1.0:
			var dist_from_end: float = (contact_point - p2).length()
			if dist_from_end > ball.radius:
				result.collided = false
				return result
			
			result.contact_point = p2

			var t_contact: float = Geometry2D.segment_intersects_circle(
				ball_prev, ball_pos,
				p2, ball.radius
			)

			if t_contact == -1:
				result.collided = false
				return result
			
			var ball_pos_at_contact: Vector2 = (ball_pos - ball_prev) * t_contact + ball_prev
			
			var error_since_contact: Vector2 = ball_pos - ball_pos_at_contact

			var reflected_error: Vector2 = _reflect(error_since_contact, (ball_pos_at_contact - p2).normalized())

			result.position = ball_pos_at_contact + reflected_error
			result.velocity = (result.position - ball_pos_at_contact).normalized() * ball.velocity.length()
			result.contact_distance = (contact_point - ball_prev).length()

			return result

		elif t < 0.0:
			var dist_from_end: float = (contact_point - p1).length()
			if dist_from_end > ball.radius:
				result.collided = false
				return result
			
			result.contact_point = p1

			var t_contact: float = Geometry2D.segment_intersects_circle(
				ball_prev, ball_pos,
				p1, ball.radius
			)

			if t_contact == -1:
				result.collided = false
				return result
			
			var ball_pos_at_contact: Vector2 = (ball_pos - ball_prev) * t_contact + ball_prev
			
			var error_since_contact: Vector2 = ball_pos - ball_pos_at_contact

			var reflected_error: Vector2 = _reflect(error_since_contact, (ball_pos_at_contact - p1).normalized())

			result.position = ball_pos_at_contact + reflected_error
			result.velocity = (result.position - ball_pos_at_contact).normalized() * ball.velocity.length()
			result.contact_distance = (contact_point - ball.prev).length()

			return result



	

	return result

# public static float InverseLerp(Vector2 a, Vector2 b, Vector2 value)
# {
#     Vector2 ab = b - a;
#     Vector2 av = value - a;
    
#     float abSquared = ab.sqrMagnitude;
#     if (abSquared == 0f)
#     {
#         return 0f; // a and b are the same point
#     }
    
#     // Project av onto ab, find ratio
#     return Vector2.Dot(av, ab) / abSquared;
# }
func _inv_lerp_vec2(from: Vector2, to: Vector2, value: Vector2) -> float:
	var ab: Vector2 = to - from
	var av: Vector2 = value - from

	var ab_squared: float = ab.length_squared()
	if is_equal_approx(ab_squared, 0.0):
		return 0
	
	return av.dot(ab) / ab_squared

func _reflect(p: Vector2, n: Vector2) -> Vector2:
	return p - 2 * (p.dot(n)) * n