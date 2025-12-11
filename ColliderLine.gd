@tool
extends Node2D
class_name ColliderLine

@onready var debug_point1: Node2D = %DebugPoint1
@onready var debug_point2: Node2D = %DebugPoint2
@onready var debug_line: Polygon2D = %DebugLine
@onready var debug_normal: Polygon2D = %DebugNormal

@export
var show_debug: bool = false

var tangent: Vector2
var normal: Vector2

func _ready() -> void:
	tangent = (debug_point2.global_position - debug_point1.global_position).normalized()
	normal = tangent.rotated(PI / 2)

func _process(delta: float) -> void:
	if show_debug:
		tangent = (debug_point2.global_position - debug_point1.global_position).normalized()
		normal = tangent.rotated(PI / 2)

		var points: PackedVector2Array
		
		points.append(debug_point1.global_position + normal)
		points.append(debug_point1.global_position - normal)
		points.append(debug_point2.global_position - normal)
		points.append(debug_point2.global_position + normal)

		debug_line.polygon = points


		var normal_points: PackedVector2Array

		var half_point: Vector2 = lerp(debug_point1.global_position, debug_point2.global_position, 0.5)

		normal_points.append(half_point.move_toward(debug_point1.global_position, 1.0))
		normal_points.append(half_point.move_toward(debug_point2.global_position, 1.0))
		normal_points.append(half_point + normal * 16)

		debug_normal.polygon = normal_points


func set_moving_towards(moving_towards: bool) -> void:
	if moving_towards:
		debug_line.color = Color.from_string("ff220067", Color.WHITE)
	else:
		debug_line.color = Color.from_string("0088ff67", Color.WHITE)