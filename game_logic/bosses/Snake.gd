extends Node
class_name Snake

class Segment:
	var position: Vector2i
	var is_head: bool

	var block_ref: BreakableBlock

	static func create_segment(pos: Vector2i) -> Segment:
		var segment: Segment = Segment.new()
		segment.position = pos

		return segment

enum SnakeCell {
	NONE,
	FOOD,
	SEGMENT,
	HEAD,
	OTHER,
}


class SnakeGrid:
	static var FORBIDDEN_AFTER_ROW: int = 16
	
	var grid: Array[PackedInt32Array] = []

	func _init() -> void:
		grid.resize(BreakableGrid.GRID_SIZE.x)
		for array in grid:
			array.resize(BreakableGrid.GRID_SIZE.y)

		for x in BreakableGrid.GRID_SIZE.x:
			for y in range(FORBIDDEN_AFTER_ROW, BreakableGrid.GRID_SIZE.y):
				grid[x][y] = SnakeCell.OTHER
			

	func set_cell(pos: Vector2i, set_to: SnakeCell) -> void:
		grid[pos.x][pos.y] = int(set_to)
	
	func get_cell(pos: Vector2i) -> SnakeCell:
		return grid[pos.x][pos.y] as SnakeCell
	
	func remove_cell(pos: Vector2i) -> void:
		grid[pos.x][pos.y] = 0


class Navigator extends Node:
	var next_step: Vector2i = Vector2i.ZERO

	func calc_next_step(grid: SnakeGrid, foods: Array[Food], head: Vector2i) -> void:
		# init alg
		var look_dirs: Array[Vector2i] = [
			Vector2i.UP,
			Vector2i.DOWN,
			Vector2i.LEFT,
			Vector2i.RIGHT,
		]


		var sorted_foods: Array[Food] = foods.filter(func(f: Food) -> bool: return !f.eaten)
		if sorted_foods.size() == 0:
			return

		# TODO: can use .bind() here to pass head
		sorted_foods.sort_custom(func(a: Food, b: Food) -> bool:
			# a < b
			return Navigator.wrapped_taxicab_dist(head, a.position) < Navigator.wrapped_taxicab_dist(head, b.position) 
		)

		var target_food: Vector2i = sorted_foods.front().position

		var queue: Array[Vector2i] = [
			head
		]

		# IMPORTANT:
		# from[i] is a direction
		# it represents what direction the previous move was
		# to get previous location, you must -from[i] from current location
		var from: Array[PackedVector2Array] = []
		from.resize(BreakableGrid.GRID_SIZE.x)

		for array in from:
			array.resize(BreakableGrid.GRID_SIZE.y)
			array.fill(Vector2.ZERO) 

		var used: Array[PackedInt32Array] = []
		used.resize(BreakableGrid.GRID_SIZE.x)
		for array in used:
			array.resize(BreakableGrid.GRID_SIZE.y)
			array.fill(0)
		
		used[head.x][head.y] = 1

		var found_food: Vector2i = Vector2i.MIN

		var _iter: int = 0

		while true:
			# take all of queue with minial but equal dists
			# TODO: can use .bind() here to pass target_food
			queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				# a < b
				return Navigator.wrapped_taxicab_dist(target_food, a) < Navigator.wrapped_taxicab_dist(target_food, b) 
			)

			var min_dist: int = Navigator.wrapped_taxicab_dist(head, queue.front())
			var push_neighbors_for: Array[Vector2i] = []
			while queue.size() && Navigator.wrapped_taxicab_dist(head, queue.front()) == min_dist:
				push_neighbors_for.push_back(queue.pop_front())
			
			for pos in push_neighbors_for:
				if found_food != Vector2i.MIN:
					break
				
				for dir in look_dirs:
					var neighbor_pos: Vector2i = Snake.wrap_position(pos + dir)

					if grid.get_cell(neighbor_pos) == SnakeCell.NONE && used[neighbor_pos.x][neighbor_pos.y] == 0:
						queue.push_back(neighbor_pos)
						used[neighbor_pos.x][neighbor_pos.y] = 1
						from[neighbor_pos.x][neighbor_pos.y] = Vector2(dir)
					
					elif grid.get_cell(neighbor_pos) == SnakeCell.FOOD:
						from[neighbor_pos.x][neighbor_pos.y] = Vector2(dir)
						found_food = neighbor_pos
						break
			
			if found_food != Vector2i.MIN:
				break
			
			_iter += 1
			if _iter > 10000 || queue.size() == 0:
				LoggerMogyi.log(self, "No path found for food. Aborting!", LoggerMogyi.Severity.ERROR)
				next_step = Vector2i.MIN
				return

		# retrace route
		var path: Array[Vector2i] = []
		var current_path_pos: Vector2i = found_food

		while current_path_pos != head:
			path.push_back(Vector2i(from[current_path_pos.x][current_path_pos.y]))
			current_path_pos -= Vector2i(from[current_path_pos.x][current_path_pos.y])
			current_path_pos = Snake.wrap_position(current_path_pos)

		next_step = path.back()
	
	static func wrapped_taxicab_dist(a: Vector2i, b: Vector2i) -> int:
		var tl: Vector2i = a
		var br: Vector2i = b

		if a.x > b.x:
			tl.x = b.x
			br.x = a.x

		if a.y > b.y:
			tl.y = b.y
			br.y = a.y

		if br.x - tl.x > (BreakableGrid.GRID_SIZE.x / 2):
			tl.x += BreakableGrid.GRID_SIZE.x
		
		if br.y - tl.y > ((BreakableGrid.GRID_SIZE.y - SnakeGrid.FORBIDDEN_AFTER_ROW) / 2):
			tl.y += (BreakableGrid.GRID_SIZE.y - SnakeGrid.FORBIDDEN_AFTER_ROW)
		
		return abs(a.x - b.x) + abs(a.y - b.y) 






var initial_size: int = 8
var segments: Array[Segment] = []

var grid: SnakeGrid = SnakeGrid.new()

class Food:
	var position: Vector2i
	var block_ref: BreakableBlock
	var eaten: bool = false

var foods: Array[Food] = []

var navigator: Navigator = Navigator.new()

var direction: Vector2i = Vector2i.ZERO

var is_dead: bool = false

var last_move: float = 0.0
# lower this to speed up snake
var move_treshold: float = 1.0 / 6

func init_snake() -> void:
	for i in initial_size:
		segments.push_back(
			Segment.create_segment(
				Vector2i(
					initial_size - i,
					10 # spawn height
				)
			)
		)
	
	for segment in segments:
		grid.set_cell(segment.position, SnakeCell.SEGMENT)

var _LOOP_LIMIT: int = 1000
func spawn_random_food(rng: RandomNumberGenerator) -> void:
	var x: int = int(rng.randf() * BreakableGrid.GRID_SIZE.x)
	var y: int = int(rng.randf() * BreakableGrid.GRID_SIZE.y)

	var _iter: int = 0
	while grid.get_cell(Vector2i(x, y)) != SnakeCell.NONE:
		x = int(rng.randf() * BreakableGrid.GRID_SIZE.x)
		y = int(rng.randf() * SnakeGrid.FORBIDDEN_AFTER_ROW)

		_iter += 1
		if _iter >= _LOOP_LIMIT:
			LoggerMogyi.log(self, "Exceeded loop_limit for spawning food. Aborting", LoggerMogyi.Severity.ERROR)
			return
	
	spawn_food_at(Vector2i(x, y))

func spawn_food_at(pos: Vector2i) -> void:
	var food: Food = Food.new()
	food.position = pos
	grid.set_cell(pos, SnakeCell.FOOD)
	foods.push_back(food)

func move() -> void:
	grid.set_cell(segments[0].position, SnakeCell.SEGMENT)

	grid.remove_cell(segments.back().position)

	for i in range(segments.size() - 1, 0, -1):
		segments[i].position = segments[i - 1].position

		segments[i].position = wrap_position(segments[i].position)

	
	segments[0].position += direction
	segments[0].position = wrap_position(segments[0].position)

	grid.set_cell(segments[0].position, SnakeCell.HEAD)

func grow() -> void:
	var tail_pos: Vector2i = segments.back().position
	var last_segment: Segment = Segment.create_segment(tail_pos)

	move()

	segments.push_back(last_segment)
	grid.set_cell(last_segment.position, SnakeCell.SEGMENT)

	# foods.erase(segments[0].position)
	for food in foods:
		if food.position == segments[0].position:
			food.eaten = true
			return

### returns true if snake has grown
func update() -> bool:
	var next_cell: Vector2i = segments[0].position + direction

	next_cell = wrap_position(next_cell)

	if grid.get_cell(next_cell) == SnakeCell.FOOD:
		grow()
		return true
		
	elif grid.get_cell(next_cell) == SnakeCell.NONE:
		move()
	elif grid.get_cell(next_cell) == SnakeCell.SEGMENT:
		cut_snake_at(next_cell)

	else:
		pass

	return false

static func wrap_position(pos: Vector2i) -> Vector2i:
	var result: Vector2i
	result.x = (pos.x + BreakableGrid.GRID_SIZE.x) % BreakableGrid.GRID_SIZE.x
	result.y = (pos.y + SnakeGrid.FORBIDDEN_AFTER_ROW) % SnakeGrid.FORBIDDEN_AFTER_ROW

	return result

func calculate_nav_grid() -> void:
	navigator.calc_next_step(
		grid, foods, segments.front().position
	)

func set_nav_direction() -> void:
	direction = navigator.next_step

var SNAKE_CUT_FOOD_CHANCE: float = 0.3

func cut_snake_at(cut_pos: Vector2i, rng: RandomNumberGenerator = RandomNumberGenerator.new()) -> Array[BreakableBlock]:
	var cut_index: int = segments.find_custom(
		func(a: Segment) -> bool:
			return a.position == cut_pos
	)

	if cut_index == 0:
		is_dead = true

	if cut_index == -1:
		LoggerMogyi.log(self, "No segment of snake found at %v. Skipping" % cut_pos)
		return []
	
	var _cut_blocks: Array[BreakableBlock] = [segments[cut_index].block_ref]
	# skip exact cut, it wont pawn food
	for i in range(cut_index + 1, segments.size()):
		var segment: Segment = segments[i]

		_cut_blocks.push_back(segment.block_ref)

		if rng.randf() < SNAKE_CUT_FOOD_CHANCE:
			spawn_food_at(segment.position)
		else:
			grid.set_cell(segment.position, SnakeCell.NONE)
	
	grid.set_cell(cut_pos, SnakeCell.NONE)


	
	segments.resize(cut_index)

	return _cut_blocks

var FOOD_LIMIT: int = 5

func refill_food(rng: RandomNumberGenerator) -> void:
	purge_stale_food()
	
	while foods.size() < FOOD_LIMIT:
		spawn_random_food(rng)
	
func purge_stale_food() -> void:
	for food in foods:
		if food.eaten:
			grid.set_cell(food.position, SnakeCell.NONE)
	
	foods = foods.filter(func(f: Food) -> bool: return !f.eaten)

func mark_food_as_eaten(pos: Vector2i) -> void:
	for food in foods:
		if food.position == pos:
			food.eaten = true
			# return

func get_head_block() -> BreakableBlock:
	if !is_dead:
		return segments.front().block_ref
	return null
