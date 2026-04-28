extends Node2D

const BrickScene = preload("res://scenes/entities/Brick.tscn")
@export var margin_top: float = 150.0
@export var gap: Vector2 = Vector2(2.0, 2.0)
const BRICK_SIZE = Vector2(64.0, 32.0)

func _ready() -> void:
	Events.layout_calculated.connect(_generate_level)
	
func _generate_level(play_area: Rect2, slider_y: float, paddle_y: float) -> void:
	var level_data = LevelManager.get_current_level_data()
	var rows = level_data.size()
	var columns = level_data[0].size()
	var total_unscaled_width = (columns * BRICK_SIZE.x) + ((columns - 1) * gap.x)
	var target_max_width = play_area.size.x * 0.95 
	var scale_factor = 1.0
	if total_unscaled_width > target_max_width:
		scale_factor = target_max_width / total_unscaled_width
	var scaled_brick_size = BRICK_SIZE * scale_factor
	var scaled_gap = gap * scale_factor
	var total_width = (columns * scaled_brick_size.x) + ((columns - 1) * scaled_gap.x)
	var start_x = play_area.position.x + (play_area.size.x - total_width) / 2.0
	var start_center_x = start_x + (scaled_brick_size.x / 2.0)
	var start_center_y = margin_top + (scaled_brick_size.y / 2.0)
	var actual_brick_count: int = 0
	for r in range(rows):
		for c in range(columns):
			var brick_type = level_data[r][c]
			if brick_type == 0:
				continue
			var brick = BrickScene.instantiate()
			var pos_x = start_center_x + c * (scaled_brick_size.x + scaled_gap.x)
			var pos_y = start_center_y + r * (scaled_brick_size.y + scaled_gap.y)
			brick.position = Vector2(pos_x, pos_y)
			brick.scale = Vector2(scale_factor, scale_factor) 
			add_child(brick)
			actual_brick_count += 1
	Events.level_ready.emit.call_deferred(actual_brick_count)
