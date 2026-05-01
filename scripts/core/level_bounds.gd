extends Node2D

var current_play_area: Rect2

func _ready() -> void:
	Events.layout_calculated.connect(_on_layout_calculated)
	
func _on_layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float) -> void:
	current_play_area = play_area
	var thickness = 100.0
	#TopWall
	$Walls/TopWall.shape.size = Vector2(play_area.size.x + thickness * 2.0, thickness)
	$Walls/TopWall.global_position = Vector2(play_area.position.x + play_area.size.x / 2.0, play_area.position.y - (thickness / 2.0))
	#LeftWall
	$Walls/LeftWall.shape.size = Vector2(thickness, play_area.size.y * 2.0)
	$Walls/LeftWall.global_position = Vector2(play_area.position.x - thickness / 2.0, play_area.position.y + play_area.size.y / 2.0)
	#RightWall
	$Walls/RightWall.shape.size = Vector2(thickness, play_area.size.y * 2.0)
	$Walls/RightWall.global_position = Vector2(play_area.position.x + play_area.size.x + thickness / 2.0, play_area.position.y + play_area.size.y / 2.0)
	#BottomZone 
	$Killzone/BottomZone.shape.size = Vector2(play_area.size.x + thickness * 2.0, thickness)
	$Killzone/BottomZone.global_position = Vector2(play_area.position.x + play_area.size.x / 2.0, play_area.position.y + play_area.size.y + 100.0)
	queue_redraw()
	
func _draw() -> void:
	if current_play_area.size == Vector2.ZERO:
		return
	var bg_color = Color(0.05, 0.05, 0.08)
	draw_rect(current_play_area, bg_color)
	var line_color = Color(0.2, 0.8, 1.0)
	var line_thickness = 4.0
	var top_left = current_play_area.position
	var top_right = Vector2(current_play_area.end.x, current_play_area.position.y)
	var bottom_left = Vector2(current_play_area.position.x, current_play_area.size.y + 200)
	var bottom_right = Vector2(current_play_area.end.x, current_play_area.size.y + 200)
	draw_line(bottom_left, top_left, line_color, line_thickness)
	draw_line(top_left, top_right, line_color, line_thickness)
	draw_line(top_right, bottom_right, line_color, line_thickness)

func _on_killzone_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		body.queue_free()
		Events.ball_lost.emit()
