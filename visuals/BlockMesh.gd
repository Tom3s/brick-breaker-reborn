extends MeshInstance3D
class_name BlockMesh

var base_size: Vector3 = Vector3.ONE * 2.0

func set_visual_scale(size: Vector2) -> void:
	scale.x = size.x / base_size.x
	scale.z = size.y / base_size.z

	scale.y = BreakableGrid.CELL_SIZE / base_size.y