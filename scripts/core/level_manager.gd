extends Node

var current_level_index: int = 0

var levels = [
	[
		[2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
	],
	[
		[9, 1, 1, 9, 1, 1, 1, 9, 1, 1, 9],
		[9, 2, 2, 9, 2, 2, 2, 9, 2, 2, 9],
		[9, 1, 1, 9, 1, 1, 1, 9, 1, 1, 9],
		[1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1],
		[1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1]
	],
	[
		[9, 2, 1, 2, 9, 0, 9, 2, 1, 2, 9],
		[1, 2, 9, 2, 1, 1, 1, 2, 9, 2, 1],
		[9, 1, 2, 1, 9, 2, 9, 1, 2, 1, 9],
		[1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1],
		[0, 9, 0, 9, 0, 9, 0, 9, 0, 9, 0]
	],
]

func get_current_level_data() -> Array:
	if current_level_index >= 0 and current_level_index < levels.size():
		return levels[current_level_index]
	return levels[0]

func has_next_level() -> bool:
	return current_level_index < levels.size() - 1
