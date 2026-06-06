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

func add_perlin_noise() -> void:
	var perlin: PerlinNoise = PerlinNoise.new()
	perlin.init_array()
	perlin.generate_points(rng)

	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			color_texture[index] = perlin.sample(x, y, BreakableGrid.GRID_SIZE) * Vector3.ONE


func treshold_grayscale(treshold: float) -> void:
	for i in color_texture.size():
		color_texture[i] = Vector3.ONE if color_texture[i].x >= treshold else Vector3.ZERO 

func slice_x(from: int, to: int) -> void:
	# TODO: add bound checks
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			if x < from || x >= to:
				color_texture[index] = Vector3.ZERO

func slice_y(from: int, to: int) -> void:
	# TODO: add bound checks
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			if y < from || y >= to:
				var index: int = y * (BreakableGrid.GRID_SIZE) + x
				color_texture[index] = Vector3.ZERO

func invert() -> void:
	for i in color_texture.size():
		color_texture[i] = Vector3.ONE - color_texture[i] 

func convert_with_horizontal_merge() -> Array[BreakableBlock]:
	var result: Array[BreakableBlock]

	var making_block: bool = false
	var block_size: int = 0
	var block_pos: Vector2i

	for y in BreakableGrid.GRID_SIZE:
		for x in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x
			var val: float = color_texture[index].x

			if val == 1:
				if !making_block:
					block_pos = Vector2i(x, y)
				making_block = true
				block_size += 1
			
			elif val == 0 || y == 0: # val == 0
				if making_block:
					var block: BreakableBlock = BreakableBlock.new()
					block.size = Vector2i(block_size, 1)
					block.pos_on_grid = block_pos
					block.prepare_collision()
					if rng.get_float() < .3:
						block.has_powerup = true
						block.powerup = Powerup.new()
						block.powerup.type = Powerup.Type.BALL_MULTIPLY

					result.push_back(block)


				block_size = 0
				making_block = false
	
	return result