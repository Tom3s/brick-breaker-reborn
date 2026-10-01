extends WorldEnvironment

@onready var texture: TextureRect = %TextureRect


func draw_snake(snk: Snake) -> void:
	texture.snake = snk
	texture.queue_redraw()

