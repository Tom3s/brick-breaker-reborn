extends Node2D

func _ready() -> void:
	var array: Array

	array.push_back("hey")

	for str: String in array:
		array.push_back("hey2")

		print(str)
