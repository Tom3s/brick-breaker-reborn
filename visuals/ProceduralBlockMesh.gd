@tool
extends MeshInstance3D
class_name ProceduralBlockMesh

@export
var bevel_size: int = 4:
	set(new_value):
		bevel_size = new_value
		add_mesh()

@export
var normal_deviation: float = 0.1:
	set(new_value):
		normal_deviation = new_value
		add_mesh()

var base_vertices: PackedVector2Array = [
		Vector2(-BreakableGrid.CELL_SIZE, -BreakableGrid.CELL_SIZE),
		Vector2(BreakableGrid.CELL_SIZE, -BreakableGrid.CELL_SIZE),
		Vector2(BreakableGrid.CELL_SIZE, BreakableGrid.CELL_SIZE),
		Vector2(-BreakableGrid.CELL_SIZE, BreakableGrid.CELL_SIZE),
	]

class Vertex:
	var index: int
	var pos: Vector3
	var direction: Vector3
	var normal: Vector3

func _ready() -> void:
	add_mesh()

func add_mesh() -> void:
	var top_vertices: Array[Vertex] = get_vertices_in_plane(BreakableGrid.CELL_SIZE)
	var bottom_vertices: Array[Vertex] = get_vertices_in_plane(0.0)

	var meshData: Array  = []
	meshData.resize(ArrayMesh.ARRAY_MAX)

	var vertices: PackedVector3Array

	for vertex: Vertex in top_vertices:
		vertices.push_back(vertex.pos - bevel_size * vertex.direction)

	for vertex: Vertex in bottom_vertices:
		vertices.push_back(vertex.pos - bevel_size * vertex.direction)
	
	# for i in base_vertices.size():


	print(vertices)
	
	meshData[ArrayMesh.ARRAY_VERTEX] = vertices
	# var indices := getVertexIndexArray(
	# 	vertices,
	# 	widthSegments,
	# 	lengthSegments,
	# 	lengthMultiplier,
	# 	clockwise
	# )
	var indices: PackedInt32Array = [
		0, 1, 2,
		0, 2, 3,
		4, 6, 5,
		4, 7, 6, 
	]
	meshData[ArrayMesh.ARRAY_INDEX] = indices
	# meshData[ArrayMesh.ARRAY_TEX_UV] = getUVArray(
	# 	widthSegments,
	# 	lengthSegments,
	# 	lengthMultiplier
	# )
	var normals: PackedVector3Array = []

	for vertex: Vertex in top_vertices:
		normals.push_back(vertex.normal.lerp(vertex.direction, normal_deviation))
	for vertex: Vertex in bottom_vertices:
		normals.push_back(vertex.normal.lerp(vertex.direction, normal_deviation))

	meshData[ArrayMesh.ARRAY_NORMAL] = normals

	# if clear:
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshData)

func get_vertices_in_plane(height: float, normal_deviation: float = 0.1) -> Array[Vertex]:
	var vertices: Array[Vertex] = []
	for i in base_vertices.size():
		var vertex: Vector2 = base_vertices[i]
		var new_vertex: Vertex = Vertex.new()
		new_vertex.index = i
		new_vertex.pos = Vector3(
			vertex.x,
			height,
			vertex.y,
		)

		var prev_vertex: Vector2 = base_vertices[(i + base_vertices.size() - 1) % base_vertices.size()]
		var next_vertex: Vector2 = base_vertices[(i + 1) % base_vertices.size()]
		
		var dir1: Vector3 = convert_vector((vertex - prev_vertex).normalized())
		var dir2: Vector3 = convert_vector((next_vertex - vertex).normalized())

		var normal: Vector3 = dir2.cross(dir1)

		var direction: Vector3 = dir1.lerp(dir2, 0.5).rotated(normal, PI / 2).normalized()

		print(direction)

		new_vertex.direction = direction

		# new_vertex.pos -= bevel_size * new_vertex.direction

		new_vertex.normal = normal

		vertices.push_back(new_vertex)
	
	return vertices

func convert_vector(v: Vector2) -> Vector3:
	return Vector3(
		v.x, 0, v.y,
	)
