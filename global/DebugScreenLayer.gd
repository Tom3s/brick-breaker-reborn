extends CanvasLayer
class_name DebugScreenLayer

@onready var label: Label = %Label

func set_text(text: String) -> void:
	label.text = text
