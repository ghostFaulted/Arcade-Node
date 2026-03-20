extends AnimatableBody2D
var screen_width: float
var half_width: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_width = get_viewport_rect().size.x
	half_width = $CollisionShape2D.shape.size.x / 2.0
	
func set_normalized_position(norm_x: float) -> void:
	var target_x = norm_x * screen_width
	var clamped_x = clampf(target_x, half_width, screen_width - half_width)
	global_position.x = clamped_x
