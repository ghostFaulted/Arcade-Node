extends Node2D

var paddle_width: float = 0.0
@export var gap: float = 3.0
@export var height: float = 8.0
@export var y_offset: float = 14.0
var current_ratio: float = 0.0
var is_slowed: bool = false

const COLORS = [
	Color.GREEN_YELLOW,
	Color.YELLOW,
	Color.ORANGE,
	Color.RED
]

const EMPTY_COLOR = Color(0.2, 0.2, 0.2, 0.8)

func _ready() -> void:
	paddle_width = get_parent().get_node("CollisionShape2D").shape.height
	Events.speed_updated.connect(_on_speed_updated)
	Events.paddle_size_changed.connect(_on_paddle_size_changed)
	Events.ball_slow_state_changed.connect(_on_ball_slow_state_changed)
	
func _on_speed_updated(ratio: float) -> void:
	current_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()
	
func _draw() -> void:
	var segments = 4
	var segment_width = (paddle_width - ((segments - 1) * gap)) / segments
	var start_x = -(paddle_width / 2.0)
	
	for i in range(segments):
		var pos_x = start_x + (i * (segment_width + gap))
		var base_rect = Rect2(pos_x, y_offset, segment_width, height)
		
		draw_rect(base_rect, EMPTY_COLOR)
		
		if is_slowed:
			draw_rect(base_rect, Color.GREEN)
		else:
			var segment_start = float(i) * 0.25
			var local_ratio = (current_ratio - segment_start) * 4.0
			var fill_percent = clampf(local_ratio, 0.0, 1.0)
			
			if fill_percent > 0.0:
				var fill_width = segment_width * fill_percent
				var filled_rect = Rect2(pos_x, y_offset, fill_width, height)
				draw_rect(filled_rect, COLORS[i])
				
func _on_paddle_size_changed(new_width: float) -> void:
	paddle_width = new_width
	queue_redraw()
	
func _on_ball_slow_state_changed(active: bool) -> void:
	is_slowed = active
	queue_redraw()