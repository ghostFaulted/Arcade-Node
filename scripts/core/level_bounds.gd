extends Node2D

var current_play_area: Rect2
var is_shield_active: bool = false
var current_paddle_y: float = 0.0

func _ready() -> void:
	Events.layout_calculated.connect(_on_layout_calculated)
	Events.shield_state_changed.connect(_on_shield_state_changed)
	
	$Killzone.body_entered.connect(_on_killzone_body_entered)
	$Killzone.area_entered.connect(_on_killzone_area_entered)
	
	$Killzone.monitoring = true
	$Killzone.monitorable = false
	$Killzone.collision_layer = 1
	$Killzone.collision_mask = 1
	
	var col_shape = $Killzone/BottomZone
	if col_shape == null:
		print("[CRITICAL ERROR] Killzone has NO BottomZone node!")
	elif col_shape.shape == null:
		print("[CRITICAL ERROR] Killzone BottomZone has NO SHAPE assigned!")
	else:
		col_shape.disabled = false

func _on_layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float) -> void:
	current_play_area = play_area
	var thickness = 100.0
	
	$Walls/TopWall.shape.size = Vector2(play_area.size.x + thickness * 2.0, thickness)
	$Walls/TopWall.global_position = Vector2(play_area.position.x + play_area.size.x / 2.0, play_area.position.y - (thickness / 2.0))
	
	$Walls/LeftWall.shape.size = Vector2(thickness, play_area.size.y * 2.0)
	$Walls/LeftWall.global_position = Vector2(play_area.position.x - thickness / 2.0, play_area.position.y + play_area.size.y / 2.0)
	
	$Walls/RightWall.shape.size = Vector2(thickness, play_area.size.y * 2.0)
	$Walls/RightWall.global_position = Vector2(play_area.position.x + play_area.size.x + thickness / 2.0, play_area.position.y + play_area.size.y / 2.0)
	
	$Killzone/BottomZone.shape.size = Vector2(play_area.size.x + thickness * 2.0, thickness)
	$Killzone/BottomZone.position = Vector2.ZERO 
	
	var screen_height = get_viewport_rect().size.y
	$Killzone.global_position = Vector2(play_area.position.x + play_area.size.x / 2.0, screen_height + 150.0)
	
	current_paddle_y = paddle_y
	$ShieldWall/Shape.shape.size = Vector2(play_area.size.x, 20.0)
	$ShieldWall/Shape.global_position = Vector2(play_area.position.x + play_area.size.x / 2.0, paddle_y + 30.0)
	
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
	var bottom_left = Vector2(current_play_area.position.x, current_play_area.end.y)
	var bottom_right = Vector2(current_play_area.end.x, current_play_area.end.y)
	draw_line(bottom_left, top_left, line_color, line_thickness)
	draw_line(top_left, top_right, line_color, line_thickness)
	draw_line(top_right, bottom_right, line_color, line_thickness)
	if is_shield_active:
		var shield_y = current_paddle_y + 30.0
		var s_left = Vector2(current_play_area.position.x, shield_y)
		var s_right = Vector2(current_play_area.end.x, shield_y)
		draw_line(s_left, s_right, Color.CYAN, 6.0)

func _on_killzone_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		body.queue_free()
		Events.ball_lost.emit()
		
func _on_killzone_area_entered(area: Area2D) -> void:
	if area.is_in_group("powerups"):
		print("[DEBUG] Power-up fell into abyss and was destroyed: ", area.type)
		Events.powerup_freed.emit() 
		area.queue_free()
		
func _on_shield_state_changed(active: bool) -> void:
	is_shield_active = active
	$ShieldWall/Shape.set_deferred("disabled", not active)
	queue_redraw()
