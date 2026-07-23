extends Node
class_name MapGenerator

var temp_texture: PackedFloat32Array
var final_texture: PackedFloat32Array
var color_texture: PackedVector3Array
var rng: RNG

func _init() -> void:
	# set the base level texture size
	temp_texture.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
	final_texture.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
	color_texture.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
	used.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
	LoggerMogyi.log(self, "Texture initialized with size: %d" % temp_texture.size())

	rng = RNG.new()
	rng._seed = 9223372036854775807

func clear_temp_texture() -> void:
	temp_texture.clear()
	temp_texture.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)

func clear_final_texture() -> void:
	final_texture.clear()
	final_texture.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)

func clear_color_texture() -> void:
	color_texture.clear()
	color_texture.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)

func set_color(x: int, y: int, new_color: float) -> void:
	if temp_texture.size() == 0:
		LoggerMogyi.log(self, "Trying to set map_generator color when the texture is not yet initalized! Skipping", LoggerMogyi.Severity.WARNING)
		return

	# bound check
	if (x < 0 || x >= BreakableGrid.GRID_SIZE.x):
		LoggerMogyi.log(self, "Trying to set invalid x texture index: %d" % x, LoggerMogyi.Severity.WARNING)
		return

	if (y < 0 || y >= BreakableGrid.GRID_SIZE.y):
		LoggerMogyi.log(self, "Trying to set invalid y texture index: %d" % y, LoggerMogyi.Severity.WARNING)
		return
	
	# using colors as (x, y, z) where each component is [0.0, 1.0]
	if (new_color < 0.0 || new_color > 1.0):
		LoggerMogyi.log(self, "Trying to set invalid new_color: %v" % new_color, LoggerMogyi.Severity.WARNING)
		return

	var index: int = BreakableGrid.GRID_SIZE.x * y + x

	temp_texture[index] = new_color



func get_color(x: int, y: int) -> Vector3:
	if final_texture.size() == 0:
		LoggerMogyi.log(self, "Trying to get map_generator color when the texture is not yet initalized! Returing 0", LoggerMogyi.Severity.ERROR)
		return Vector3.ZERO

	var index: int = BreakableGrid.GRID_SIZE.x * y + x
	return final_texture[index] * color_texture[index]

# func add_random_noise() -> void:
# 	for i in temp_texture.size():
# 		temp_texture[i] = Vector3(rng.get_float(), rng.get_float(), rng.get_float())
	
# 	LoggerMogyi.log(self, "Random noise added to instance %s" % self)

func add_random_grayscale_noise() -> void:
	for i in temp_texture.size():
		temp_texture[i] = rng.get_float()
	
	LoggerMogyi.log(self, "Random grayscale noise added to instance %s" % self)

func add_voronoi_noise() -> void:
	var voronoi: VoronoiNoise = VoronoiNoise.new()
	voronoi.init_array()
	voronoi.generate_points(rng)

	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var index: int = y * BreakableGrid.GRID_SIZE.x + x

			temp_texture[index] = voronoi.sample(x, y, BreakableGrid.GRID_SIZE)

func add_perlin_noise() -> void:
	var perlin: PerlinNoise = PerlinNoise.new()
	perlin.init_array()
	perlin.generate_points(rng)

	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x

			temp_texture[index] = perlin.sample(x, y, BreakableGrid.GRID_SIZE)


func add_circle(cx: int, cy: int, radius: float) -> void:
	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x

			if Vector2(x, y).distance_to(Vector2(cx, cy)) <= radius:
				temp_texture[index] = 1.0

# TODO: check bounds and swap if x1 > x2 (or y1 > y2)
# this is now handled by thw sign(..) function, but might wanna pretty this up
func add_rectangle(x1: int, y1: int, x2: int, y2: int) -> void:
	for x in range(x1, x2, sign(x2 - x1)):
		for y in range(y1, y2, sign(y2 - y1)):
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x
			temp_texture[index] = 1.0

func treshold_grayscale(treshold: float) -> void:
	for i in temp_texture.size():
		temp_texture[i] = 1.0 if temp_texture[i] >= treshold else 0.0 

# var BAYER_MATRIX: Array[PackedFloat32Array] = [
# 	[ .0,  .5],
# 	[.75, .25],
# ]

var BAYER_MATRIX: Array[PackedFloat32Array] = [
	[00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0],
	[08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0],
	[02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0],
	[10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0]
];
func dither_grayscale(mult: float = 1.0) -> void:
	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x
			var dither_treshold: float = BAYER_MATRIX[y%4][x%4] * mult

			temp_texture[index] = 1.0 if temp_texture[index] >= dither_treshold else 0.0 



func slice_x(from: int, to: int) -> void:
	# TODO: add bound checks
	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x

			if x < from || x >= to:
				temp_texture[index] = 0.0

func slice_y(from: int, to: int) -> void:
	# TODO: add bound checks
	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			if y < from || y >= to:
				var index: int = y * (BreakableGrid.GRID_SIZE.x) + x
				temp_texture[index] = 0.0

func invert() -> void:
	for i in temp_texture.size():
		temp_texture[i] = 1.0 - temp_texture[i] 

func mirror_x() -> void:
	for x in (BreakableGrid.GRID_SIZE.x / 2):
		for y in BreakableGrid.GRID_SIZE.y:
			var from: int =  y * (BreakableGrid.GRID_SIZE.x) + x
			var to: int =  y * (BreakableGrid.GRID_SIZE.x) + (BreakableGrid.GRID_SIZE.x - x - 1)

			var temp: float = temp_texture[to]
			temp_texture[to] = temp_texture[from]
			temp_texture[from] = temp

func mirror_y() -> void:
	for x in BreakableGrid.GRID_SIZE.x:
		for y in (BreakableGrid.GRID_SIZE.y / 2):
			var from: int =  y * (BreakableGrid.GRID_SIZE.x) + x
			var to: int =  (BreakableGrid.GRID_SIZE.y - y - 1) * (BreakableGrid.GRID_SIZE.x) + x

			var temp: float = temp_texture[to]
			temp_texture[to] = temp_texture[from]
			temp_texture[from] = temp

func copy_texture_to_final() -> void:
	for i in temp_texture.size():
		if temp_texture[i] != 0.0:
			final_texture[i] = temp_texture[i]

func copy_texture_to_final_bound(from_x: int, from_y: int, to_x: int, to_y: int) -> void:
	if from_x < 0 || to_x > BreakableGrid.GRID_SIZE.x:
		LoggerMogyi.log(self, "X index %d, %d is out of bounds for GRID_SIZE %v" % [from_x, to_x, BreakableGrid.GRID_SIZE])
		return

	if from_x < 0 || to_x > BreakableGrid.GRID_SIZE.x:
		LoggerMogyi.log(self, "Y index %d, %d is out of bounds for GRID_SIZE %v" % [from_y, to_y, BreakableGrid.GRID_SIZE])
		return

	for y in range(from_y, to_y):
		for x in range(from_x, to_x):
			var i: int = y * BreakableGrid.GRID_SIZE.x + x
			if temp_texture[i] != 0.0:
				final_texture[i] = temp_texture[i]


var used: Array[bool] 
func convert_with_chance_merge(
	chance_x: float = 0.0, 
	chance_y: float = 0.0, 
	max_merge_x: int = BreakableGrid.GRID_SIZE.x, 
	max_merge_y: int = BreakableGrid.GRID_SIZE.y,
	block_type: BreakableBlock.BlockType = BreakableBlock.BlockType.NORMAL,
) -> Array[BreakableBlock]:
	var result: Array[BreakableBlock]
	# used.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)

	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x

			if used[index]:
				continue
			
			var val: float = final_texture[index]
			if val == 0:
				continue
			else:
				used[index] = true
			
			var block_size: Vector2 = Vector2.ONE

			var expanded_x: bool = false
			var expanded_y: bool = false

			while !expanded_x || !expanded_y:
				var can_expand_x: bool = true

				# try expanding horizontally
				# check if the expansion is possible
				if !expanded_x && rng.get_float() <= chance_x && (x + block_size.x) < BreakableGrid.GRID_SIZE.x && block_size.x < max_merge_x:
					for y2 in block_size.y:
						var check_index: int = (y + y2) * BreakableGrid.GRID_SIZE.x + (x + block_size.x)
						if final_texture[check_index] == 1 && used[check_index] == false:
							pass
						else:
							can_expand_x = false
							break
				else:
					expanded_x = true
					can_expand_x = false
				# expand if possible
				if can_expand_x:
					for y2 in block_size.y:
						var change_index: int = (y + y2) * BreakableGrid.GRID_SIZE.x + (x + block_size.x)
						used[change_index] = true
					block_size.x += 1
				else:
					expanded_x = true

				# try to expand vertically
				# check if the expansion is possible
				var can_expand_y: bool = true
				if !expanded_y && rng.get_float() <= chance_y && (y + block_size.y) < BreakableGrid.GRID_SIZE.y && block_size.y < max_merge_y:
					for x2 in block_size.x:
						var check_index: int = (y + block_size.y) * BreakableGrid.GRID_SIZE.x + (x + x2)
						if final_texture[check_index] == 1 && used[check_index] == false:
							pass
						else:
							can_expand_y = false
							break
				else:
					expanded_y = true
					can_expand_y = false
				
				# expand if possible
				if can_expand_y:
					for x2 in block_size.x:
						var change_index: int = (y + block_size.y) * BreakableGrid.GRID_SIZE.x + (x + x2)
						used[change_index] = true
					block_size.y += 1
				else:
					expanded_y = true
			

			# create block after expansion
			var block: BreakableBlock = BreakableBlock.new()
			block.size = block_size
			block.color = get_color(x, y)
			block.type = block_type
			block.pos_on_grid = Vector2(x, y)
			block.health = int(rng.get_float() * 3) + 1
			block.prepare_collision()
			if rng.get_float() < .05:
				block.has_powerup = true
				block.powerup = Powerup.new()

				block.powerup.type = Powerup.get_weighted_powerup(rng.get_float())

			result.push_back(block)
	
	return result

func add_uv_to_color() -> void:
	for y in BreakableGrid.GRID_SIZE.y:
		for x in BreakableGrid.GRID_SIZE.x:
			var index: int = y * (BreakableGrid.GRID_SIZE.x) + x
			color_texture[index].x = float(x) / BreakableGrid.GRID_SIZE.x
			color_texture[index].y = float(y) / BreakableGrid.GRID_SIZE.y
			color_texture[index].z = 0.0
	
	color_texture[0] = 0.001 * Vector3.ONE

func fill_color(new_color: Vector3) -> void:
	for i in color_texture.size():
		color_texture[i] = new_color
