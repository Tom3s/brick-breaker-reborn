extends Node
class_name QuadTree

const TRESHOLD: int = 1

class TreeNode:
	var p1: Vector2
	var p2: Vector2
	
	var data: Array[BreakableBlock] = []

	var nodes: Array[TreeNode] = [
		null,
		null,
		null,
		null,
	]

	static func create_node(p1: Vector2, p2: Vector2) -> TreeNode:
		var node: TreeNode = TreeNode.new()
		node.p1 = p1
		node.p2 = p2
		return node


	func add_block(block: BreakableBlock) -> void:
		if data.size() < TRESHOLD || abs(p1.x - p2.x) <= BreakableGrid.CELL_SIZE:
			# LoggerMogyi.log(null, "Points for adding forcefully %v - %v" % [p1, p2])
			data.push_back(block)
			return 
		
		if nodes[0] == null:
			_split()
		
		for node: TreeNode in nodes:
			if node.block_collides_aabb(block):
				node.add_block(block)

	func draw_ball_collision(ball: Ball) -> void:
		if !ball_collides_aabb(ball):
			return

		if nodes[0] == null: 
			draw_color = Color.RED
			return

		for node: TreeNode in nodes:
			node.draw_ball_collision(ball)


	func ball_collides_aabb(ball: Ball) -> bool:
		if ball.position.x - ball.radius > p2.x: return false
		if ball.position.x + ball.radius <= p1.x: return false
		if ball.position.y - ball.radius > p2.y: return false
		if ball.position.y + ball.radius <= p1.y: return false

		return true

	func block_collides_aabb(block: BreakableBlock) -> bool:
		if block.a.x > p2.x: return false
		if block.b.x <= p1.x: return false
		if block.a.y > p2.y: return false
		if block.b.y <= p1.y: return false

		return true
		
	func _split() -> void:
		# var mid: Vector2 = floor((((p1 + p2) / 2 ) / Vector2(BreakableGrid.GRID_SIZE))) * BreakableGrid.CELL_SIZE
		var mid: Vector2 = (p1 + p2) / 2
		mid += Vector2(BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE)
		mid /= Vector2.ONE * BreakableGrid.CELL_SIZE
		mid = floor(mid)
		mid *= Vector2.ONE * BreakableGrid.CELL_SIZE
		mid -= Vector2(BreakableGrid.GRID_SIZE * BreakableGrid.CELL_SIZE)

		LoggerMogyi.log(null, "Split at middle: %v - %v - %v" % [p1, mid, p2])


		if mid == p1:
			mid += Vector2.ONE * BreakableGrid.CELL_SIZE

		nodes = [
			# top left
			TreeNode.create_node(
				p1, mid 
			),
			# top right
			TreeNode.create_node(
				Vector2(mid.x, p1.y),
				Vector2(p2.x, mid.y),
			),
			# bottom left
			TreeNode.create_node(
				Vector2(p1.x, mid.y),
				Vector2(mid.x, p2.y),
			),
			# bottom right
			TreeNode.create_node(
				mid,
				p2,
			),
		]
	
	var draw_color: Color = Color.LIGHT_YELLOW
	func draw_debug(color: Color = Color.LIGHT_YELLOW) -> void:
		DebugVisual.draw_rectangle(
			p1, p2, draw_color
		)

		draw_color = Color.LIGHT_YELLOW # reset draw color for next frame
		if nodes[0] == null:
			return 

		for node: TreeNode in nodes:
			node.draw_debug()
		
	
	func free_memory() -> void:
		pass
		



var root: TreeNode

# static func create_quad_tree(p1: Vector2, p2: Vector2, blocks: Array[BreakableBlock] = []) -> QuadTree:

# 	return QuadTree.new()