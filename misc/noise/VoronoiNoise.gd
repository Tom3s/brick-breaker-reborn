extends Node
class_name VoronoiNoise

var grid_size: int = 5
var points: PackedVector2Array
var jitter: float = 0.75

func init_array() -> void:
	points.resize((grid_size + 2) * (grid_size + 2))

func generate_points(rng: RNG) -> void:
	for x in grid_size + 2:
		for y in grid_size + 2:
			var index: int = y * (grid_size + 2) + x

			var point: Vector2 = Vector2(rng.get_float(), rng.get_float())
			point -= Vector2.ONE / 2
			point *= jitter
			point += Vector2.ONE / 2

			points[index] = point


func sample(x: float, y: float, bounds: float) -> float:
	var actual_x: float = remap(x + 0.5, 0, bounds, 0, grid_size) + 1 # offset by padding and to middle of pixel
	var actual_y: float = remap(y + 0.5, 0, bounds, 0, grid_size) + 1 # offset by padding and to middle of pixel

	# LoggerMogyi.log(self, "Converted (%f, %f) to (%f, %f)" % [x, y, actual_x, actual_y])

	var index_x: int = actual_x
	var index_y: int = actual_y

	var min_distance: float = 2.0
	for i in range(-1, 2):
		for j in range(-1, 2):
			var index: int = (index_y + j) * (grid_size + 2) + (index_x + i)
			var ref_point: Vector2 = points[index]
			ref_point.x += index_x + i
			ref_point.y += index_y + j

			# LoggerMogyi.log(self, "Reference point location %v" % ref_point)

			min_distance = min(min_distance, ref_point.distance_to(Vector2(actual_x, actual_y)))
	
	return min_distance # *  1.41421356237 # 1 / (sqrt(2) / 2) = sqrt(2)