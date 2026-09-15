extends Node
class_name BlockGrid

class Cell:
	var data: Array[BreakableBlock] = []

	func _init() -> void:
		data = []

var cells: Array[Cell]

func _init() -> void:
	cells.resize(BreakableGrid.GRID_SIZE.x * BreakableGrid.GRID_SIZE.y)
	for i in cells.size():
		cells[i] = Cell.new()

func add_block(block: BreakableBlock) -> void:
	var min_index: Vector2 = floor((block.a + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	var max_index: Vector2 = ceil((block.b + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)

	min_index = min_index.max(Vector2.ZERO)
	max_index = max_index.min(Vector2(BreakableGrid.GRID_SIZE))

	for x in range(min_index.x, max_index.x):
		for y in range(min_index.y, max_index.y):
			var index: int = y * BreakableGrid.GRID_SIZE.x + x
			cells[index].data.push_back(block)

func remove_block(block: BreakableBlock) -> void:
	var min_index: Vector2 = floor((block.a + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	var max_index: Vector2 = ceil((block.b + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	for x in range(min_index.x, max_index.x):
		for y in range(min_index.y, max_index.y):
			var index: int = y * BreakableGrid.GRID_SIZE.x + x
			cells[index].data.erase(block)

func get_blocks_for_circle(pos: Vector2, r: float) -> Array[BreakableBlock]:
	# var result: Array[BreakableBlock] = []
	var result: Dictionary[BreakableBlock, bool]

	var min_index: Vector2 = floor((pos - (Vector2.ONE * r) + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	var max_index: Vector2 = ceil((pos + (Vector2.ONE * r) + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	
	min_index = min_index.max(Vector2.ZERO)
	max_index = max_index.min(Vector2(BreakableGrid.GRID_SIZE))

	for x in range(min_index.x, max_index.x):
		for y in range(min_index.y, max_index.y):
			var index: int = y * BreakableGrid.GRID_SIZE.x + x
			# result.cells[index].data.erase(block)
			for block: BreakableBlock in cells[index].data:
				result[block] = true

	return result.keys()

func get_blocks_for_pos(pos: Vector2) -> Array[BreakableBlock]:
	var indexV: Vector2 = floor((pos + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)

	if indexV.x < 0 || indexV.y < 0 || \
		indexV.x > BreakableGrid.GRID_SIZE.x || \
		indexV.y > BreakableGrid.GRID_SIZE.y:

		return []

	return cells[indexV.y * BreakableGrid.GRID_SIZE.x + indexV.x].data

func get_blocks_for_aabb(a: Vector2, b: Vector2) -> Array[BreakableBlock]:
	# LoggerMogyi.log(self, "Unimplemented get_blocks_for_aabb()", LoggerMogyi.Severity.ERROR)
	var result: Dictionary[BreakableBlock, bool]

	var min_index: Vector2 = floor((a + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	var max_index: Vector2 = ceil((b + (Vector2(BreakableGrid.GRID_SIZE) * BreakableGrid.CELL_SIZE / 2)) / BreakableGrid.CELL_SIZE)
	
	min_index = min_index.max(Vector2.ZERO)
	max_index = max_index.min(Vector2(BreakableGrid.GRID_SIZE))

	for x in range(min_index.x, max_index.x):
		for y in range(min_index.y, max_index.y):
			var index: int = y * BreakableGrid.GRID_SIZE.x + x
			# result.cells[index].data.erase(block)
			for block: BreakableBlock in cells[index].data:
				result[block] = true

	return result.keys()
