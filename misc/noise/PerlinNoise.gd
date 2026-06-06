extends Node
class_name PerlinNoise

var grid_size: int = 8
var points: PackedVector2Array

func init_array() -> void:
	points.resize(grid_size * grid_size)

func generate_points(rng: RNG) -> void:
	for x in grid_size:
		for y in grid_size:
			var index: int = y * grid_size + x

			var point: Vector2 = Vector2(rng.get_float(), rng.get_float()) * 2 - Vector2.ONE
			point = point.normalized()

			points[index] = point

func sample(x: float, y: float, bounds: float) -> float:
	var actual_x: float = remap(x + 0.5, 0, bounds, 0, grid_size - 1)
	var actual_y: float = remap(y + 0.5, 0, bounds, 0, grid_size - 1)

	# LoggerMogyi.log(self, "Converted (%f, %f) to (%f, %f)" % [x, y, actual_x, actual_y])


	var index_x: int = actual_x
	var index_y: int = actual_y

	var offset_x: float = actual_x - index_x
	var offset_y: float = actual_y - index_y

	var ref_p1: Vector2 = points[index_y * (grid_size - 1) + index_x]
	var ref_p2: Vector2 = points[index_y * (grid_size - 1) + index_x + 1]
	var ref_p3: Vector2 = points[(index_y + 1) * (grid_size - 1) + index_x]
	var ref_p4: Vector2 = points[(index_y + 1) * (grid_size - 1) + index_x + 1]

	var for_dot: Vector2 = Vector2(x, y).normalized()

	var p1: float = for_dot.dot(ref_p1)
	var p2: float = for_dot.dot(ref_p2)
	var p3: float = for_dot.dot(ref_p3)
	var p4: float = for_dot.dot(ref_p4)	

	# LoggerMogyi.log(self, "Dot products: %f, %f, %f, %f" % [p1, p2, p3, p4])

	var result: float = \
		lerp(
			lerp(p1, p2, offset_x),
			lerp(p3, p4, offset_x),
			offset_y
		)
	
	# LoggerMogyi.log(self, "Result of perlin sample at (%f, %f): %f" % [x, y, result])

	return (result + 1) / 2
	# return result

