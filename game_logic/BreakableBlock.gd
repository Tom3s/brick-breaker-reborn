extends Node
class_name BreakableBlock

enum BlockType {
	NORMAL,
	METAL,
	ICE,
}


var pos_on_grid: Vector2i = Vector2i.ZERO

# we gotta rework size to points
var size: Vector2i = Vector2i.ONE
var color: Vector3 = Vector3.ONE

# points are local
var points: PackedVector2Array

# local bounds
var bound_min: Vector2
var bound_max: Vector2


# dont remove!!
# global bounds
# used for debug draw and quadtree collision
var a: Vector2
var b: Vector2

var collision: Array[LineCollider]

var type: BlockType = BlockType.NORMAL

# var broken: bool = false
var health: int = 1

# TODO: this is just temporary
var asset_ref: Node

var has_powerup: bool = false
var powerup: Powerup

signal just_broken(type: BlockType)

func _process(delta: float) -> void:
	if is_broken():
		if asset_ref.has_method("hide"):
			asset_ref.hide()


func prepare_collision() -> void:
	fill_points_from_size()

	for i in points.size():
		var p1: Vector2 = _get_collision_vertex_position(points[i])
		var p2: Vector2 = _get_collision_vertex_position(points[(i + 1) % points.size()])

		var line: LineCollider = LineCollider.new()
		line.set_points(p2, p1)
		collision.push_back(line)


func _get_collision_vertex_position(local_vertex_pos: Vector2) -> Vector2:

	var grid_unit_size: Vector2 = BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE

	var vertex_pos: Vector2 = Vector2(pos_on_grid) * BreakableGrid.CELL_SIZE + local_vertex_pos - (grid_unit_size / 2)

	return vertex_pos

func get_origin() -> Vector2:
	return a.lerp(b, 0.5)

func hit_block(context: Global.GameContext, ball: Ball) -> void:
	# broken = true
	health -= ball.get_damage(context, self)
	
	if is_broken(): just_broken.emit(type)

	if type == BlockType.NORMAL:
		asset_ref.set_hp(health)

func hit_block_laser(context: Global.GameContext) -> void:
	health -= context.get_laser_damage()

	# TODO: this signal is used for sound
	# might be too loud for laserbeam
	# if is_broken(): just_broken.emit(type)

	asset_ref.set_hp(health)

func hit_block_dmg(damage: int) -> void:
	health -= damage

	asset_ref.set_hp(health)

func is_broken() -> bool:
	return health <= 0

func reflects_ball(context: Global.GameContext) -> bool:
	return !(type == BlockType.ICE && context.FLAG_FIREBALL_ACTIVE)

func is_pos_inside(pos: Vector2) -> bool:
	if pos.x < a.x: return false
	if pos.x > b.x: return false
	if pos.y < a.y: return false
	if pos.y > b.y: return false

	return true

func _sdBox(p: Vector2, b: Vector2) -> float:
	var d: Vector2 = abs(p) - b
	# return length(max(d,0.0)) + min(max(d.x,d.y),0.0)
	return (Vector2(max(d.x, 0.0), max(d.y, 0.0)) + Vector2(min(max(d.x, d.y), 0.0), min(max(d.x, d.y), 0.0))).length()


func collides_with_circle(pos: Vector2, r: float) -> bool:

	var dist: float = _sdBox(pos - get_origin(), (b - a) / 2)

	return dist < r

func set_visuals() -> void:
	asset_ref.set_material(type)

func fill_points_from_size() -> void:
	var p1: Vector2 = Vector2.ZERO
	var p2: Vector2 = Vector2(BreakableGrid.CELL_SIZE * size.x, 0)
	var p3: Vector2 = Vector2(BreakableGrid.CELL_SIZE * size.x, BreakableGrid.CELL_SIZE * size.y)
	var p4: Vector2 = Vector2(0, BreakableGrid.CELL_SIZE * size.y)

	points.append_array([p1, p2, p3, p4])

	# make it *wiggly* :3
	# for i in points.size():
	# 	points[i] += Vector2(
	# 		randf_range(-10, 10),
	# 		randf_range(-10, 10),
	# 	)
	
	for point in points:
		bound_min.x = min(bound_min.x, point.x)
		bound_min.y = min(bound_min.y, point.y)
		bound_max.x = max(bound_max.x, point.x)
		bound_max.y = max(bound_max.y, point.y)

	a = _get_collision_vertex_position(bound_min)
	b = _get_collision_vertex_position(bound_max)