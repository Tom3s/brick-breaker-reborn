extends Node
class_name DebugVisual

enum Type {
	NONE,
	LINE_2D,
}

var type: Type

var data: Variant

func _init(new_type: Type, new_data: Variant) -> void:
	type = new_type
	data = new_data

func draw_debug() -> void:
	if type == Type.LINE_2D:
		# LoggerMogyi.log(self, "Drawing at %v" % points[0])
		var actual_data: LineCollider = data as LineCollider
		var p1: Vector3 = Vector3(
			actual_data.p1.x,
			BreakableGrid.CELL_SIZE / 2.0,
			actual_data.p1.y,
		)
		var p2: Vector3 = Vector3(
			actual_data.p2.x,
			BreakableGrid.CELL_SIZE / 2.0,
			actual_data.p2.y,
		)
		var normal: Vector3 = Vector3 (
			actual_data.normal.x,
			0,
			actual_data.normal.y,
		)
		DebugDraw3D.draw_line(
			p1,
			p2, 
			Color.PINK
		)
		DebugDraw3D.draw_line(
			(p1 + p2) / 2,
			((p1 + p2) / 2) + normal * 10.0,
			Color.GREEN_YELLOW
		)

static func draw_rectangle(p1: Vector2, p2: Vector2, color: Color = Color.LIGHT_YELLOW) -> void:
	var d1: Vector3 = Vector3(
		p1.x,
		0,
		p1.y,
	)
	var d2: Vector3 = Vector3(
		p2.x,
		BreakableGrid.CELL_SIZE / 2.0,
		p2.y,
	)

	DebugDraw3D.draw_aabb_ab(
		d1, d2,
		color
	)

static func draw_rectangle_timed(p1: Vector2, p2: Vector2, color: Color = Color.LIGHT_YELLOW, time: float = 0) -> void:
	var d1: Vector3 = Vector3(
		p1.x,
		0,
		p1.y,
	)
	var d2: Vector3 = Vector3(
		p2.x,
		BreakableGrid.CELL_SIZE / 2.0,
		p2.y,
	)

	DebugDraw3D.draw_aabb_ab(
		d1, d2,
		color,
		time
	)

	# LoggerMogyi.log(null, "Drawing Rectangle at %v - %v" % [d1, d2])