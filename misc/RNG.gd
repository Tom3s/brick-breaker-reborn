extends Node
class_name RNG

var _seed: int = 0

func get_float() -> float:
	var result: float = float(_seed) / 9223372036854775807
	result = (result + 1) / 2

	_seed = (_seed * 6364136223846793005) + 1

	print(result)

	return result
