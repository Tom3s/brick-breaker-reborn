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

func initialize() -> void:
	# print(range(5, 0, 0))

	map_generator = MapGenerator.new()
	map_generator.rng._seed = seed
	map_generator.add_uv_to_color()

	# map_generator.add_voronoi_noise()
	map_generator.add_perlin_noise()
	map_generator.dither_grayscale(1.0)
	# map_generator.treshold_grayscale(0.5)
	# map_generator.copy_texture_to_final_bound(0, 0, 10, 24)
	# map_generator.mirror_x()
	# map_generator.copy_texture_to_final_bound(22, 0, 32, 24)
	map_generator.copy_texture_to_final()

	display_texture()

func display_texture() -> void:
	# test_texture.texture = Texture
	var image: Image = Image.create_empty(BreakableGrid.GRID_SIZE, BreakableGrid.GRID_SIZE, false, Image.FORMAT_RGBF)
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			image.set_pixel(x, y, create_color((map_generator.get_color(x, y))))
	
	# image.

	test_texture.texture = ImageTexture.create_from_image(image)


func create_color(c: Vector3) -> Color:
	return Color(c.x, c.y, c.z)