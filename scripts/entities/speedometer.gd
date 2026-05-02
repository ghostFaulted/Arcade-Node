extends Node2D

var paddle_width: float = 0.0
@export var gap: float = 3.0
@export var height: float = 8.0
@export var y_offset: float = 14.0
var current_ratio: float = 0.0

const COLORS =[
	Color.GREEN,
	Color.GREEN_YELLOW,
	Color.YELLOW,
	Color.ORANGE,
	Color.RED
]

const EMPTY_COLOR = Color(0.2, 0.2, 0.2, 0.8)

func _ready() -> void:
	paddle_width = get_parent().get_node("CollisionShape2D").shape.size.x
	Events.speed_updated.connect(_on_speed_updated)
	
func _on_speed_updated(ratio: float) -> void:
	current_ratio = ratio
	queue_redraw()
	
func _draw() -> void:
	var segments = 5
	var segment_width = (paddle_width - ((segments - 1) * gap)) / segments
	var start_x = -(paddle_width / 2.0)
	for i in range(segments):
		var pos_x = start_x + (i * (segment_width + gap))
		var rect = Rect2(pos_x, y_offset, segment_width, height)
		var threshold = i * 0.25
		if current_ratio >= threshold:
			draw_rect(rect, COLORS[i])
		else:
			draw_rect(rect, EMPTY_COLOR)
