extends Node
class_name Projectile

enum Type {
	NONE,
	GUN_BULLET,
}

static var GUN_BULLET_VELOCITY: Vector2 = Vector2.UP * BreakableGrid.GRID_SIZE.y * BreakableGrid.CELL_SIZE * 2

var type: Type = Type.NONE

var position: Vector2
var velocity: Vector2

var asset_ref: Node3D

func move(delta: float) -> void:
	position += velocity * delta

func init_type(init_type: Type) -> void:
	type = init_type

	if type == Type.GUN_BULLET:
		velocity = GUN_BULLET_VELOCITY