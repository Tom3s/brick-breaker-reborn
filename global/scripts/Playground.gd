@tool
extends EditorScript
class_name Playground

func _run() -> void:
	# var iters: int = 20
	# var n: int = 3

	# for i in n * 2:
	# 	print(int(((i + 1) / 2) % n))
	# 	#help
	# var block: ProceduralBlockMesh = ProceduralBlockMesh.new()
	# block.generate_vertices()

	var line := LineCollider.new()
	line.set_points(Vector2.ZERO, Vector2.RIGHT)

	print(line.normal)
