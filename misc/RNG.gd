extends Node
class_name RNG

var _seed: int = 0

func get_float() -> float:
	# seed is advanced forward, as its easy to get ~0.5 on the first iteration
	# _seed = (_seed * 6364136223846793005) + 1
	_seed = (_seed * 6364136223846793005) + 9754186451795953191

	var result: float = float(_seed) / 9223372036854775807
	result = (result + 1) / 2

	return result
