extends Node
class_name MapGenerator

var color_texture: PackedVector3Array
var rng: RNG

func _init() -> void:
	# set the base level texture size
	color_texture.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)
	LoggerMogyi.log(self, "Texture initialized with size: %d" % color_texture.size())

	rng = RNG.new()
	rng._seed = 9223372036854775807

func set_color(x: int, y: int, new_color: Vector3) -> void:
	if color_texture.size() == 0:
		LoggerMogyi.log(self, "Trying to set map_generator color when the texture is not yet initalized! Skipping", LoggerMogyi.Severity.WARNING)
		return

	# bound check
	if (x < 0 || x >= BreakableGrid.GRID_SIZE):
		LoggerMogyi.log(self, "Trying to set invalid x texture index: %d" % x, LoggerMogyi.Severity.WARNING)
		return

	if (y < 0 || y >= BreakableGrid.GRID_SIZE):
		LoggerMogyi.log(self, "Trying to set invalid y texture index: %d" % y, LoggerMogyi.Severity.WARNING)
		return
	
	# using colors as (x, y, z) where each component is [0.0, 1.0]
	if (new_color.x < 0.0 || new_color.x > 1.0) || \
		(new_color.y < 0.0 || new_color.y > 1.0) || \
		(new_color.z < 0.0 || new_color.z > 1.0):
		LoggerMogyi.log(self, "Trying to set invalid new_color: %v" % new_color, LoggerMogyi.Severity.WARNING)
		return

	var index: int = BreakableGrid.GRID_SIZE * y + x

	color_texture[index] = new_color

func get_color(x: int, y: int) -> Vector3:
	if color_texture.size() == 0:
		LoggerMogyi.log(self, "Trying to get map_generator color when the texture is not yet initalized! Returing 0", LoggerMogyi.Severity.ERROR)
		return Vector3.ZERO

	var index: int = BreakableGrid.GRID_SIZE * y + x
	return color_texture[index]

func add_random_noise() -> void:
	for i in color_texture.size():
		color_texture[i] = Vector3(rng.get_float(), rng.get_float(), rng.get_float())
	
	LoggerMogyi.log(self, "Random noise added to instance %s" % self)

func add_random_grayscale_noise() -> void:
	for i in color_texture.size():
		color_texture[i] = Vector3.ONE * rng.get_float()
	
	LoggerMogyi.log(self, "Random grayscale noise added to instance %s" % self)

func add_voronoi_noise() -> void:
	var voronoi: VoronoiNoise = VoronoiNoise.new()
	voronoi.init_array()
	voronoi.generate_points(rng)

	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			color_texture[index] = voronoi.sample(x, y, BreakableGrid.GRID_SIZE) * Vector3.ONE

func treshold_grayscale(treshold: float) -> void:
	for i in color_texture.size():
		color_texture[i] = Vector3.ONE if color_texture[i].x >= treshold else Vector3.ZERO 
