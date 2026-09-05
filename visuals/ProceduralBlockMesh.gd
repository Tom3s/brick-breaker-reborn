@tool
extends MeshInstance3D
class_name ProceduralBlockMesh

@export
var points: PackedVector2Array = [
	Vector2(-BreakableGrid.CELL_SIZE, -BreakableGrid.CELL_SIZE),
	Vector2( BreakableGrid.CELL_SIZE, -BreakableGrid.CELL_SIZE),
	Vector2( BreakableGrid.CELL_SIZE,  BreakableGrid.CELL_SIZE),
	Vector2(-BreakableGrid.CELL_SIZE,  BreakableGrid.CELL_SIZE),
]

@export
var offset: float = 4.0

var n: int = points.size()

var BLOCK_HEIGHT: float = 32.0 # BreakableGrid.CELL_SIZE

@export_tool_button("Generate Mesh")
var _generate_button: Callable = create_mesh

class Vertex:
	var index: int
	var position: Vector3 
	var normal: Vector3 
	var direction: Vector3 

	func print_vertex() -> void:
		print(
			"i: %d, pos: %v, normal: %v, dir: %v" % [
				index,
				position,
				normal,
				direction
			]
		)


# func _ready() -> void:
# 	generate_vertices()


# create vertex, face, normal array here

func color_from_vec3(vec3: Vector3) -> Color:
	return Color(
		vec3.x,
		vec3.y,
		vec3.z,
		1.0
	)

func create_mesh() -> void:
	n = points.size()
	var vertices: Array[Vertex] = generate_vertices()

	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray() 
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	for vert in vertices:
		verts.push_back(vert.position - (vert.direction * offset))
		colors.push_back(color_from_vec3(vert.position))
		normals.push_back(vert.normal)
	
	indices.append_array(create_top_face_indices())
	var top_tri_count: int = indices.size()
	for i in top_tri_count:
		indices.push_back(indices[top_tri_count - 1 - i] + n)
	indices.append_array(create_side_face_indices())
	indices.append_array(create_top_bevel_indices())
	indices.append_array(create_bottom_bevel_indices())
	indices.append_array(create_corner_bevel_indices())

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_COLOR] = colors
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

# Ear clipping algorithm
# TODO: since vertices will get nudged slightly after triangulation
#   they might still end up clipping the outside in a concave way
#   especially if some points are ~collinear
func create_top_face_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()

	var remaining_vertices: Array[int]
	for i in points.size():
		remaining_vertices.append(i)
	

	var current_pointer: int = 0
	var _failsafe: int = 0
	while remaining_vertices.size() > 3:
		_failsafe += 1
		if _failsafe > 1000:
			LoggerMogyi.log(self, "Surpassed 1000 iterations! Loop might be infinite", LoggerMogyi.Severity.ERROR)
			break
		# wrap index around
		current_pointer %= remaining_vertices.size()

		var i: int = remaining_vertices[current_pointer]
		var l: int = remaining_vertices[(remaining_vertices.size() + current_pointer - 1) % remaining_vertices.size()]
		var r: int = remaining_vertices[(current_pointer + 1) % remaining_vertices.size()]

		var p: Vector2 = points[i]
		var pl: Vector2 = points[l]
		var pr: Vector2 = points[r]

		# concave -> skip
		if (p - pl).cross(pr - p) < 0:
			current_pointer += 1
			continue
		
		# other vertex inside this triangle
		var _skip_iteration: bool = false
		for ii in points.size():
			if ii == i || ii == l || ii == r:
				continue
			
			var check_vertex: Vector2 = points[ii]

			if Geometry2D.point_is_inside_triangle(check_vertex, p, pl, pr):
				current_pointer += 1
				_skip_iteration = true
				break
		
		if _skip_iteration: continue

		remaining_vertices.remove_at(current_pointer)
		indices.append_array([l, i, r])
		print("Added %d - %d - %d" % [i, l, r])

	indices.append_array(remaining_vertices)

	return indices

func create_bottom_face_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()

	# TODO: handle face creation for more indices
	# this only works for 4
	indices.append_array([7, 5, 4])
	indices.append_array([7, 6, 5])

	return indices

func create_side_face_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()

	for i in 2 * n:
		var p1: int = 2 * n + i
		var p2: int = 2 * n + (i + 1) % (2 * n)
		var p3: int = 4 * n + i
		var p4: int = 4 * n + (i + 1) % (2 * n)

		indices.append_array([p3, p2, p1])
		indices.append_array([p2, p3, p4])
	
	return indices

func create_top_bevel_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()

	for i in n:
		var p1: int = i
		var p2: int = (i + 1) % n
		var p3: int = 2 * n + 2 * i
		var p4: int = 2 * n + 2 * i + 1

		indices.append_array([p3, p2, p1])
		indices.append_array([p2, p3, p4])
	
	return indices

func create_bottom_bevel_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()

	for i in n:
		var p1: int = i + n
		var p2: int = (i + 1) % n + n
		var p3: int = 4 * n + 2 * i
		var p4: int = 4 * n + 2 * i + 1

		indices.append_array([p1, p2, p3])
		indices.append_array([p4, p3, p2])
	
	return indices

func create_corner_bevel_indices() -> PackedInt32Array:
	var indices: PackedInt32Array = PackedInt32Array()

	for i in n:
		var p1: int = i
		var p2: int = 2 * n + (2 * n - 1 + 2 * i) % (2 * n)
		var p3: int = 2 * n + 2 * i
		var p4: int = n + i
		var p5: int = 4 * n + (2 * n - 1 + 2 * i) % (2 * n)
		var p6: int = 4 * n + 2 * i

		indices.append_array([p1, p2, p3])
		indices.append_array([p6, p5, p4])
	
	return indices


func generate_vertices() -> Array[Vertex]:

	# generate top vertices
	var top_vertices: Array[Vertex]
	# generate top vertices
	var bottom_vertices: Array[Vertex]
	for i in points.size():
		var p: Vector2 = points[i]
		var pl: Vector2 = points[(i + n - 1) % n]
		var pr: Vector2 = points[(i + 1) % n]
		var vertex: Vertex = Vertex.new()
		vertex.position = Vector3(
			p.x,
			BLOCK_HEIGHT,
			p.y,
		)
		vertex.normal = Vector3.UP

		var dir2D: Vector2 = ((p - pl).normalized() + (p - pr).normalized()).normalized()
		if ((p - pl).cross(p - pr) > 0):
			dir2D = -dir2D
		vertex.direction = Vector3(
			dir2D.x,
			0.0,
			dir2D.y,
		)
		
		# no index
		top_vertices.push_back(vertex)

		var vertex2: Vertex = Vertex.new()
		vertex2.position = Vector3(
			p.x,
			0.0,
			p.y,
		)
		vertex2.normal = Vector3.DOWN
		vertex2.direction = vertex.direction

		# no index
		bottom_vertices.push_back(vertex2)

	var upper_row: Array[Vertex]
	var lower_row: Array[Vertex]

	for i in n:
		# var index: int = int(((i + 1) / 2) % n)
		var index: int = i
		var p: Vector2 = points[index]
		var p2: Vector2 = points[(index + 1) % n]

		var tangent: Vector2 = (p2 - p).normalized()
		var normal3D: Vector3 = Vector3(
			tangent.y, 0.0, -tangent.x
		)

		var v1: Vertex = Vertex.new()
		v1.position = Vector3(
			p.x,
			BLOCK_HEIGHT,
			p.y,
		)
		v1.normal = normal3D
		
		var v2: Vertex = Vertex.new()
		v2.position = Vector3(
			p2.x,
			BLOCK_HEIGHT,
			p2.y,
		)
		v2.normal = normal3D

		v1.direction = Vector3.UP.rotated(
			normal3D, - PI / 4
		)
		v2.direction = Vector3.UP.normalized().rotated(
			normal3D, PI / 4
		)

		# no index
		upper_row.push_back(v1)
		upper_row.push_back(v2)

		var v3: Vertex = Vertex.new()
		v3.position = Vector3(
			p.x,
			0.0,
			p.y,
		)
		v3.normal = normal3D
		var v4: Vertex = Vertex.new()
		v4.position = Vector3(
			p2.x,
			0.0,
			p2.y,
		)
		v4.normal = normal3D

		v3.direction = Vector3.DOWN.normalized().rotated(
			normal3D, PI / 4
		)
		v4.direction = Vector3.DOWN.normalized().rotated(
			normal3D, - PI / 4
		)

		# no index
		lower_row.push_back(v3)
		lower_row.push_back(v4)
	
	
	var final_vertices: Array[Vertex]

	for vert in top_vertices:
		vert.index = final_vertices.size()
		final_vertices.push_back(vert)
	
	for vert in bottom_vertices:
		vert.index = final_vertices.size()
		final_vertices.push_back(vert)

	for vert in upper_row:
		vert.index = final_vertices.size()
		final_vertices.push_back(vert)

	for vert in lower_row:
		vert.index = final_vertices.size()
		final_vertices.push_back(vert)

	# for vert in final_vertices:
	# 	vert.print_vertex()
	
	return final_vertices

# func 
