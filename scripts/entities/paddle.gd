extends AnimatableBody2D

var screen_width: float = 0.0
var half_width: float = 0.0
var min_x: float = 0.0
var max_x: float = 0.0
var target_x: float = 0.0
var target_y: float = 0.0

func _ready() -> void:
	add_to_group("paddle")
	Events.paddle_exact_x_moved.connect(_on_exact_x_moved)
	Events.layout_calculated.connect(_on_layout_calculated)

func _on_layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float) -> void:
	screen_width = play_area.size.x
	half_width = $CollisionShape2D.shape.size.x / 2.0
	min_x = play_area.position.x + half_width
	max_x = play_area.position.x + play_area.size.x - half_width
	target_x = play_area.position.x + play_area.size.x / 2.0
	target_y = paddle_y

func _on_exact_x_moved(new_x: float) -> void:
	target_x = clampf(new_x, min_x, max_x)

func _process(delta: float) -> void:
	if screen_width > 0:
		global_position = Vector2(target_x, target_y)
