extends Node2D

const BrickScene = preload("res://scenes/entities/Brick.tscn")
@export var columns: int = 7
@export var rows: int = 4

@export var margin_top: float = 150.0
@export var gap: Vector2 = Vector2(10.0, 10.0)

const BRICK_SIZE = Vector2(64.0, 32.0)

func _ready() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var total_width = (columns * BRICK_SIZE.x) + ((columns - 1) * gap.x)
	var start_x = (screen_size.x - total_width) / 2.0
	var start_center_x = start_x + (BRICK_SIZE.x / 2.0)
	var start_center_y = margin_top + (BRICK_SIZE.y / 2.0)
	
	for r in range(rows):
		for c in range(columns):
			var brick = BrickScene.instantiate()
			var pos_x = start_center_x + c * (BRICK_SIZE.x + gap.x)
			var pos_y = start_center_y + r * (BRICK_SIZE.y + gap.y)
			brick.position = Vector2(pos_x, pos_y)
			add_child(brick)
