extends Control

@export_enum("Paddle", "Ball") var slot_type: String = "Paddle"

@export var ring_color: Color = Color.GREEN
@export var bg_color: Color = Color(0.1, 0.1, 0.2, 0.8)
@export var line_thickness: float = 6.0

var current_ratio: float = 0.0
var active_powerup: String = ""

func _process(delta: float) -> void:
	var manager = PowerUpManager
	var new_ratio = 0.0
	var new_powerup = ""
	if slot_type == "Paddle":
		new_powerup = manager.active_paddle_powerup
		if not manager.paddle_timer.is_stopped():
			new_ratio = manager.paddle_timer.time_left / manager.current_paddle_duration
	else:
		new_powerup = manager.active_ball_powerup
		if not manager.ball_timer.is_stopped():
			new_ratio = manager.ball_timer.time_left / manager.current_ball_duration
	if new_ratio != current_ratio or new_powerup != active_powerup:
		current_ratio = new_ratio
		active_powerup = new_powerup
		_update_visuals()
		
func _update_visuals() -> void:
	visible = true
	if active_powerup == "":
		$LetterLabel.text = ""
	else:
		$LetterLabel.text = active_powerup.left(1).to_upper()
	queue_redraw()

func _draw() -> void:
	var center = size / 2.0
	var radius = (size.x / 2.0) - (line_thickness / 2.0)
	draw_circle(center, radius, bg_color)
	if current_ratio > 0.0 and active_powerup != "":
		var start_angle = -PI/2.0 + (TAU * (1.0 - current_ratio))
		var end_angle = -PI/2.0 + TAU 
		draw_arc(center, radius, start_angle, end_angle, 64, ring_color, line_thickness, true)
