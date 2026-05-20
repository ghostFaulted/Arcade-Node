extends Area2D

@export var fall_speed: float = 250.0
var type: String = "none"

func _process(delta: float) -> void:
	global_position.y += fall_speed * delta
