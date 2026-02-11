extends Node

var GRAVITY: float = 256.0

var DEBUG: bool = true

class GameContext:
	var balls: Array[Ball]
	var paddle: Paddle = Paddle.new()

	var screen_collision: Array[LineCollider]
	var death_barrier: LineCollider
	var blocks: Array[BreakableBlock]

	var broken_block_count: int = 0
	var nr_metal_blocks: int = 0

	var powerups: Array[Powerup]
