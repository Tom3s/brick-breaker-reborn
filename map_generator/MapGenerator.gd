extends Node
class_name MapGenerator

var temp_texture: PackedVector3Array
var final_texture: PackedVector3Array
var rng: RNG

func _init() -> void:
	# set the base level texture size
	temp_texture.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)
	final_texture.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)
	used.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)
	LoggerMogyi.log(self, "Texture initialized with size: %d" % temp_texture.size())

	rng = RNG.new()
	rng._seed = 9223372036854775807

func clear_temp_texture() -> void:
	temp_texture.clear()
	temp_texture.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)

func clear_final_texture() -> void:
	final_texture.clear()
	final_texture.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)

func set_color(x: int, y: int, new_color: Vector3) -> void:
	if temp_texture.size() == 0:
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

	temp_texture[index] = new_color

func get_color(x: int, y: int) -> Vector3:
	if final_texture.size() == 0:
		LoggerMogyi.log(self, "Trying to get map_generator color when the texture is not yet initalized! Returing 0", LoggerMogyi.Severity.ERROR)
		return Vector3.ZERO

	var index: int = BreakableGrid.GRID_SIZE * y + x
	return final_texture[index]

func add_random_noise() -> void:
	for i in temp_texture.size():
		temp_texture[i] = Vector3(rng.get_float(), rng.get_float(), rng.get_float())
	
	LoggerMogyi.log(self, "Random noise added to instance %s" % self)

func add_random_grayscale_noise() -> void:
	for i in temp_texture.size():
		temp_texture[i] = Vector3.ONE * rng.get_float()
	
	LoggerMogyi.log(self, "Random grayscale noise added to instance %s" % self)

func add_voronoi_noise() -> void:
	var voronoi: VoronoiNoise = VoronoiNoise.new()
	voronoi.init_array()
	voronoi.generate_points(rng)

	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			temp_texture[index] = voronoi.sample(x, y, BreakableGrid.GRID_SIZE) * Vector3.ONE

func add_perlin_noise() -> void:
	var perlin: PerlinNoise = PerlinNoise.new()
	perlin.init_array()
	perlin.generate_points(rng)

	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			temp_texture[index] = perlin.sample(x, y, BreakableGrid.GRID_SIZE) * Vector3.ONE


func add_circle(cx: int, cy: int, radius: float) -> void:
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			if Vector2(x, y).distance_to(Vector2(cx, cy)) <= radius:
				temp_texture[index] = Vector3.ONE

func treshold_grayscale(treshold: float) -> void:
	for i in temp_texture.size():
		temp_texture[i] = Vector3.ONE if temp_texture[i].x >= treshold else Vector3.ZERO 

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
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x
			var dither_treshold: float = BAYER_MATRIX[y%4][x%4] * mult

			temp_texture[index] = Vector3.ONE if temp_texture[index].x >= dither_treshold else Vector3.ZERO 



func slice_x(from: int, to: int) -> void:
	# TODO: add bound checks
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			if x < from || x >= to:
				temp_texture[index] = Vector3.ZERO

func slice_y(from: int, to: int) -> void:
	# TODO: add bound checks
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			if y < from || y >= to:
				var index: int = y * (BreakableGrid.GRID_SIZE) + x
				temp_texture[index] = Vector3.ZERO

func invert() -> void:
	for i in temp_texture.size():
		temp_texture[i] = Vector3.ONE - temp_texture[i] 

func mirror_x() -> void:
	for x in (BreakableGrid.GRID_SIZE / 2):
		for y in BreakableGrid.GRID_SIZE:
			var from: int =  y * (BreakableGrid.GRID_SIZE) + x
			var to: int =  y * (BreakableGrid.GRID_SIZE) + (BreakableGrid.GRID_SIZE - x - 1)

			var temp: Vector3 = temp_texture[to]
			temp_texture[to] = temp_texture[from]
			temp_texture[from] = temp

func mirror_y() -> void:
	for x in BreakableGrid.GRID_SIZE:
		for y in (BreakableGrid.GRID_SIZE / 2):
			var from: int =  y * (BreakableGrid.GRID_SIZE) + x
			var to: int =  (BreakableGrid.GRID_SIZE - y - 1) * (BreakableGrid.GRID_SIZE) + x

			var temp: Vector3 = temp_texture[to]
			temp_texture[to] = temp_texture[from]
			temp_texture[from] = temp

func copy_texture_to_final() -> void:
	for i in temp_texture.size():
		if temp_texture[i] != Vector3.ZERO:
			final_texture[i] = temp_texture[i]

func copy_texture_to_final_bound(from_x: int, from_y: int, to_x: int, to_y: int) -> void:
	for y in range(from_y, to_y):
		for x in range(from_x, to_x):
			var i: int = y * BreakableGrid.GRID_SIZE + x
			if temp_texture[i] != Vector3.ZERO:
				final_texture[i] = temp_texture[i]


func convert_with_horizontal_merge(max_merge: int = BreakableGrid.GRID_SIZE) -> Array[BreakableBlock]:
	var result: Array[BreakableBlock]

	var making_block: bool = false
	var block_size: int = 0
	var block_pos: Vector2i

	for y in BreakableGrid.GRID_SIZE:
		for x in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x
			var val: float = final_texture[index].x

			if val == 1:
				if !making_block:
					block_pos = Vector2i(x, y)
				making_block = true
				block_size += 1
			
			if val == 0 || x >= (BreakableGrid.GRID_SIZE - 1) || block_size >= max_merge:
				if making_block:
					var block: BreakableBlock = BreakableBlock.new()
					block.size = Vector2i(block_size, 1)
					block.pos_on_grid = block_pos
					block.health = 4 - min(block_size, 3)
					block.prepare_collision()
					if rng.get_float() < .05:
						block.has_powerup = true
						block.powerup = Powerup.new()
						block.powerup.type = Powerup.Type.BALL_MULTIPLY

					result.push_back(block)


				block_size = 0
				making_block = false
	
	return result

# TODO: this is placeholder. Implement proper merging after the fact
func convert_with_vertical_merge(max_merge: int = BreakableGrid.GRID_SIZE) -> Array[BreakableBlock]:
	var result: Array[BreakableBlock]

	var making_block: bool = false
	var block_size: int = 0
	var block_pos: Vector2i

	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x
			var val: float = final_texture[index].x

			if val == 1:
				if !making_block:
					block_pos = Vector2i(x, y)
				making_block = true
				block_size += 1
			
			if val == 0 || y == (BreakableGrid.GRID_SIZE - 1) || block_size >= max_merge:
				if making_block:
					var block: BreakableBlock = BreakableBlock.new()
					block.size = Vector2i(1, block_size)
					block.pos_on_grid = block_pos
					block.health = 3 - min(block_size, 2)
					block.prepare_collision()
					if rng.get_float() < .05:
						block.has_powerup = true
						block.powerup = Powerup.new()
						block.powerup.type = Powerup.Type.BALL_MULTIPLY

					result.push_back(block)


				block_size = 0
				making_block = false
	
	return result

var used: Array[bool] 
func convert_with_chance_merge(
	chance_x: float = 0.0, 
	chance_y: float = 0.0, 
	max_merge_x: int = BreakableGrid.GRID_SIZE, 
	max_merge_y: int = BreakableGrid.GRID_SIZE,
) -> Array[BreakableBlock]:
	var result: Array[BreakableBlock]
	# used.resize(BreakableGrid.GRID_SIZE * BreakableGrid.GRID_SIZE)

	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			var index: int = y * (BreakableGrid.GRID_SIZE) + x

			if used[index]:
				continue
			
			var val: float = final_texture[index].x
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
				if !expanded_x && rng.get_float() <= chance_x && (x + block_size.x) < BreakableGrid.GRID_SIZE && block_size.x < max_merge_x:
					for y2 in block_size.y:
						var check_index: int = (y + y2) * BreakableGrid.GRID_SIZE + (x + block_size.x)
						if final_texture[check_index].x == 1 && used[check_index] == false:
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
						var change_index: int = (y + y2) * BreakableGrid.GRID_SIZE + (x + block_size.x)
						used[change_index] = true
					block_size.x += 1
				else:
					expanded_x = true

				# try to expand vertically
				# check if the expansion is possible
				var can_expand_y: bool = true
				if !expanded_y && rng.get_float() <= chance_y && (y + block_size.y) < BreakableGrid.GRID_SIZE && block_size.y < max_merge_y:
					for x2 in block_size.x:
						var check_index: int = (y + block_size.y) * BreakableGrid.GRID_SIZE + (x + x2)
						if final_texture[check_index].x == 1 && used[check_index] == false:
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
						var change_index: int = (y + block_size.y) * BreakableGrid.GRID_SIZE + (x + x2)
						used[change_index] = true
					block_size.y += 1
				else:
					expanded_y = true
			

			# create block after expansion
			var block: BreakableBlock = BreakableBlock.new()
			block.size = block_size
			block.pos_on_grid = Vector2(x, y)
			# block.health = 3 - min(block_size, 2)
			block.prepare_collision()
			if rng.get_float() < .05:
				block.has_powerup = true
				block.powerup = Powerup.new()
				block.powerup.type = Powerup.Type.BALL_MULTIPLY

			result.push_back(block)
	
	return result
