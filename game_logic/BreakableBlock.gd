extends Node
class_name BreakableBlock

enum BlockType {
	NORMAL,
	METAL,
	ICE,
}


var pos_on_grid: Vector2i = Vector2i.ZERO

var size: Vector2i = Vector2i.ONE
var color: Vector3 = Vector3.ONE

var collision: Array[LineCollider]


var type: BlockType = BlockType.NORMAL

# var broken: bool = false
var health: int = 1

# TODO: this is just temporary
var asset_ref: Node

var has_powerup: bool = false
var powerup: Powerup

func _process(delta: float) -> void:
	if is_broken():
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

func hit_block(context: Global.GameContext, ball: Ball) -> void:
	# broken = true
	health -= ball.get_damage(context, self)
	
	if type == BlockType.NORMAL:
		asset_ref.set_hp(health)

	if is_broken() && asset_ref.has_method("hide"):
		asset_ref.hide()

func is_broken() -> bool:
	return health <= 0