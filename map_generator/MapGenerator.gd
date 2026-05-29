extends Node
class_name MapGenerator

var color_texture: PackedVector3Array

func _init() -> void:
	# set the base level texture size
	color_texture.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)

func set_color(x: int, y: int, new_color: Vector3) -> void:
	if color_texture.size() == 0:
		return

	# bound check
	if (x < 0 || x >= BreakableGrid.GRID_SIZE):
		return

	if (y < 0 || y >= BreakableGrid.GRID_SIZE):
		return
	
	# using colors as (x, y, z) where each component is [0.0, 1.0]
	if (new_color.x < 0.0 || new_color.x > 1.0) || \
		(new_color.y < 0.0 || new_color.y > 1.0) || \
		(new_color.z < 0.0 || new_color.z > 1.0):
		return

	var index: int = BreakableGrid.GRID_SIZE * y + x

	color_texture[index] = new_color

