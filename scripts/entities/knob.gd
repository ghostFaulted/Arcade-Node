extends Control

@export var knob_color: Color = Color.RED
@export var knob_radius: float = 60.0
@export var is_hollow: bool = false
@export var line_thickness: float = 4.0

func _draw() -> void:
	var center = Vector2(size.x / 2.0, size.y / 2.0)
	if is_hollow:
		draw_arc(center, knob_radius, 0.0, TAU, 64, knob_color, line_thickness, true)
	else:
		draw_circle(center, knob_radius, knob_color)
