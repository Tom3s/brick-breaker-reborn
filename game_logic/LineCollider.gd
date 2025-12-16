extends Node
class_name LineCollider

var p1: Vector2
var p2: Vector2

var tangent: Vector2
var normal: Vector2

func _ready() -> void:
	calculate_normals()


func calculate_normals() -> void:
	tangent = (p2 - p1).normalized()
	normal = tangent.rotated(PI / 2)

func set_points(p1_new: Vector2, p2_new: Vector2) -> void:
	p1 = p1_new
	p2 = p2_new

	calculate_normals()