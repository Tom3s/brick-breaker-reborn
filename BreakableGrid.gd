extends Node2D
class_name BreakableGrid

const CELL_SIZE: int = 32
const GRID_SIZE: int = 32

class Block:
	var size: int = 1 #TODO: implement larger blocks
	# maybe use more parameters for any shape

	var broken: bool = false



class Grid:
	static var grid_size: int = 32
	var blocks: Array[Block]




var grid: Grid = Grid.new()

func _ready() -> void:
	grid.blocks.resize(Grid.grid_size * Grid.grid_size)

