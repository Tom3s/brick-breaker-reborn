@tool
extends Node2D
class_name _generator_test

@export_tool_button("init")
var _init_lambda := func() -> void: initialize()


@export_tool_button("Refresh Texture")
var _refresh_lambda := func() -> void: display_texture()

@export
var seed: int = 0

@onready var test_texture: TextureRect = %TestTexture

var map_generator: MapGenerator

func _ready() -> void:
	initialize()

# var current_angle: float = 0.0
func initialize() -> void:
	# print(range(5, 0, 0))

	map_generator = MapGenerator.new()
	map_generator.rng._seed = seed
	# map_generator.add_uv_to_color()
	map_generator.add_rectangle(0, 0, BreakableGrid.GRID_SIZE.x, BreakableGrid.GRID_SIZE.y)
	map_generator.add_gradient_to_color(Vector3.ZERO, Vector3.ONE, 1)


	# map_generator.add_voronoi_noise()
	# map_generator.add_perlin_noise()
	# map_generator.add_random_grayscale_noise()
	# map_generator.dither_grayscale(1.0)
	# map_generator.treshold_grayscale(0.5)
	# map_generator.copy_texture_to_final_bound(0, 0, 10, 24)
	# map_generator.mirror_x()
	# map_generator.copy_texture_to_final_bound(22, 0, 32, 24)
	map_generator.copy_texture_to_final()

	display_texture()

# func _process(delta: float) -> void:
# 	current_angle += delta

# 	initialize()

func display_texture() -> void:
	# test_texture.texture = Texture
	# var image: Image = Image.create_empty(BreakableGrid.GRID_SIZE.x, BreakableGrid.GRID_SIZE.y, false, Image.FORMAT_RGBF)
	var image: Image = Image.create_empty(BreakableGrid.GRID_SIZE.x, BreakableGrid.GRID_SIZE.y, false, Image.FORMAT_RGBF)
	for x in BreakableGrid.GRID_SIZE.x:
		for y in BreakableGrid.GRID_SIZE.y:
			image.set_pixel(x, y, create_color((map_generator.get_color(x, y))))
	
	# image.

	test_texture.texture = ImageTexture.create_from_image(image)


func create_color(c: Vector3) -> Color:
	return Color(c.x, c.y, c.z)
