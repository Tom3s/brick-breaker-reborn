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
	var top_positions: PackedVector3Array = get_vector3_in_plane(BreakableGrid.CELL_SIZE)
	var bottom_positions: PackedVector3Array = get_vector3_in_plane(0.0)

	print(top_positions)

	var meshData: Array  = []
	meshData.resize(ArrayMesh.ARRAY_MAX)

	var vertices: PackedVector3Array

	# var top_vertices: Array[Vertex] = get_vertices_in_plane(top_positions)
	# var bottom_vertices: Array[Vertex] = get_vertices_in_plane(bottom_positions)
	# for vertex: Vertex in top_vertices:
	# 	vertices.push_back(vertex.pos - bevel_size * vertex.direction)

	
	var final_vertices: Array[Vertex] = []
	final_vertices.append_array(get_vertices_in_plane(top_positions))
	final_vertices.append_array(get_vertices_in_plane(bottom_positions))
	
	for i in base_vertices.size():
		var temp_positions: PackedVector3Array = []

		temp_positions.push_back(top_positions[(i + 1) % top_positions.size()])
		temp_positions.push_back(top_positions[i])
		temp_positions.push_back(bottom_positions[i])
		temp_positions.push_back(bottom_positions[(i + 1) % bottom_positions.size()])

		final_vertices.append_array(get_vertices_in_plane(temp_positions))
	
	for vertex: Vertex in final_vertices:
		vertices.push_back(vertex.pos - bevel_size * vertex.direction)

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

	for i in base_vertices.size():
		for ii in 6:
			indices.push_back(indices[ii] + base_vertices.size() * (i + 2))
		
		

		
		
		

	print(indices)

	meshData[ArrayMesh.ARRAY_INDEX] = indices
	# meshData[ArrayMesh.ARRAY_TEX_UV] = getUVArray(
	# 	widthSegments,
	# 	lengthSegments,
	# 	lengthMultiplier
	# )
	var normals: PackedVector3Array = []

	for vertex: Vertex in final_vertices:
		normals.push_back(vertex.normal.lerp(vertex.direction, normal_deviation))

	meshData[ArrayMesh.ARRAY_NORMAL] = normals

	# if clear:
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshData)

func get_vertices_in_plane(base_positions: PackedVector3Array, flip_normals: bool = false) -> Array[Vertex]:
	var vertices: Array[Vertex] = []
	for i in base_positions.size():
		var vertex: Vector3 = base_positions[i]
		var new_vertex: Vertex = Vertex.new()

		new_vertex.pos = vertex

		var prev_vertex: Vector3 = base_positions[(i + base_positions.size() - 1) % base_positions.size()]
		var next_vertex: Vector3 = base_positions[(i + 1) % base_positions.size()]
		
		var dir1: Vector3 = (vertex - prev_vertex).normalized()
		var dir2: Vector3 = (next_vertex - vertex).normalized()

		var normal: Vector3 = dir2.cross(dir1)

		if flip_normals:
			normal *= -1

		var direction: Vector3 = dir1.lerp(dir2, 0.5).rotated(normal, PI / 2).normalized()

		# print(direction)

		new_vertex.direction = direction

		# new_vertex.pos -= bevel_size * new_vertex.direction

		new_vertex.normal = normal

		vertices.push_back(new_vertex)
	
	return vertices

func convert_vector(v: Vector2) -> Vector3:
	return Vector3(
		v.x, 0, v.y,
	)

func get_vector3_in_plane(height: float) -> PackedVector3Array:
	var vertices: PackedVector3Array = []
	for i in base_vertices.size():
		var vertex: Vector2 = base_vertices[i]
		vertices.push_back(Vector3(
				vertex.x,
				height,
				vertex.y,
			)
		)
	
	return vertices
