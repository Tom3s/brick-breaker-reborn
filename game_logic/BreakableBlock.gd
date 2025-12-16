extends Node
class_name BreakableBlock

var pos_on_grid: Vector2i = Vector2i.ZERO

# TODO: implement larger blocks
var size: Vector2i = Vector2i.ONE

var collision: Array[LineCollider]

# TODO: set this to a counter for multi layered block
# TODO: maybe add immunities, so certain blocks need certain damage type to be broken
var broken: bool = false

# TODO: this is just temporary
var asset_ref: Node

func _process(delta: float) -> void:
	if broken:
		if asset_ref.has_method("hide"):
			asset_ref.hide()

func prepare_collision() -> void:
	var p1: Vector2 = _get_collision_vertex_position(Vector2.ZERO)
	var p2: Vector2 = _get_collision_vertex_position(Vector2(0, BreakableGrid.CELL_SIZE * size.y))
	var p3: Vector2 = _get_collision_vertex_position(Vector2(BreakableGrid.CELL_SIZE * size.x, BreakableGrid.CELL_SIZE * size.y))
	var p4: Vector2 = _get_collision_vertex_position(Vector2(BreakableGrid.CELL_SIZE * size.x, 0))

	var line: LineCollider = LineCollider.new()
	line.set_points(p1, p2)
	collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p2, p3)
	collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p3, p4)
	collision.push_back(line)

	line = LineCollider.new()
	line.set_points(p4, p1)
	collision.push_back(line)

func _get_collision_vertex_position(local_vertex_pos: Vector2) -> Vector2:

	var grid_unit_size: Vector2 = Vector2.ONE * BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE

	var vertex_pos: Vector2 = Vector2(pos_on_grid) * BreakableGrid.CELL_SIZE + local_vertex_pos - (grid_unit_size / 2)

	return vertex_pos

func get_origin() -> Vector2:
	var p1: Vector2 = _get_collision_vertex_position(Vector2.ZERO)
	var p3: Vector2 = _get_collision_vertex_position(Vector2(BreakableGrid.CELL_SIZE * size.x, BreakableGrid.CELL_SIZE * size.y))

	return p1.lerp(p3, 0.5)

func hit_block() -> void:
	broken = true
	
	if asset_ref.has_method("hide"):
		asset_ref.hide()