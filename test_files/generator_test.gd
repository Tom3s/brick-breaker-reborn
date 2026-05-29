@tool
extends Node2D
class_name _generator_test

@export_tool_button("Refresh Texture")
var _refresh_lambda := func() -> void: display_texture()

@onready var test_texture: Sprite2D = %TestTexture

var map_generator: MapGenerator

func _ready() -> void:
	map_generator = MapGenerator.new()

	map_generator.add_random_grayscale_noise()

	map_generator.treshold_grayscale(randf())

	display_texture()

func display_texture() -> void:
	# test_texture.texture = Texture
	var image: Image = Image.create_empty(BreakableGrid.GRID_SIZE, BreakableGrid.GRID_SIZE, false, Image.FORMAT_RGBF)
	for x in BreakableGrid.GRID_SIZE:
		for y in BreakableGrid.GRID_SIZE:
			image.set_pixel(x, y, create_color((map_generator.get_color(x, y))))
	
	test_texture.texture = ImageTexture.create_from_image(image)


func create_color(c: Vector3) -> Color:
	return Color(c.x, c.y, c.z)