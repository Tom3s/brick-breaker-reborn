extends Node2D
class_name BreakableBlock

var pos_on_grid: Vector2i = Vector2i.ZERO

# TODO: implement larger blocks
var size: Vector2i = Vector2i.ONE

@onready var collider_line_scene: PackedScene = preload("res://ColliderLine.tscn")

@onready var line_parent: Node2D = %Lines

var broken: bool = false

func _process(delta: float) -> void:
	if broken:
		line_parent.hide()

func prepare_collision() -> void:
	var p1: Vector2 = _get_collision_vertex_position(Vector2.ZERO)
	var p2: Vector2 = _get_collision_vertex_position(Vector2(0, BreakableGrid.CELL_SIZE * size.y))
	var p3: Vector2 = _get_collision_vertex_position(Vector2(BreakableGrid.CELL_SIZE * size.x, BreakableGrid.CELL_SIZE * size.y))
	var p4: Vector2 = _get_collision_vertex_position(Vector2(BreakableGrid.CELL_SIZE * size.x, 0))

	var line: ColliderLine = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p1, p2)

	line = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p2, p3)

	line = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p3, p4)

	line = collider_line_scene.instantiate()
	line_parent.add_child(line)
	line.set_points(p4, p1)

func _get_collision_vertex_position(local_vertex_pos: Vector2) -> Vector2:

	var grid_unit_size: Vector2 = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE

	var vertex_pos: Vector2 = Vector2(pos_on_grid) * BreakableGrid.CELL_SIZE + local_vertex_pos - (grid_unit_size / 2)

	return vertex_pos
