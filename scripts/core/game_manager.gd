extends Node

const BallScene = preload("res://scenes/entities/Ball.tscn")
var score: int = 0
var lives: int = 3
var bricks_remaining: int = 0
const MAX_LIVES: int = 99

func _ready() -> void:
	Events.brick_destroyed.connect(_on_brick_destroyed)
	Events.bonus_points_gained.connect(_on_bonus_points_gained)
	Events.ball_lost.connect(_on_ball_lost)
	Events.level_ready.connect(_on_level_ready)
	Events.score_updated.emit.call_deferred(0)
	Events.lives_updated.emit.call_deferred(3)
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	var current_aspect = screen_size.y / screen_size.x
	var base_aspect = 20.0 / 9.0
	Events.vertical_speed_scale = current_aspect / base_aspect
	var safe_area = DisplayServer.get_display_safe_area()
	var top_ratio = float(safe_area.position.y) / float(DisplayServer.screen_get_size().y) if DisplayServer.screen_get_size().y > 0 else 0.0
	var safe_margin_top = top_ratio * screen_size.y
	var top_ui_height = safe_margin_top + 60.0
	var slider_y = screen_size.y * 0.70
	var paddle_y = slider_y - 120.0 
	var side_margin = 10.0 
	var play_x = side_margin
	var play_width = screen_size.x - (side_margin * 2.0)
	var play_y = top_ui_height + 30.0
	var play_height = (screen_size.y - play_y) + 200.0 
	var play_area = Rect2(play_x, play_y, play_width, play_height)
	Events.layout_calculated.emit(play_area, slider_y, paddle_y)
	Events.life_gained.connect(_on_life_gained)
	Events.multiball_activated.connect(_on_multiball_activated)
	spawn_ball()
	
func _on_brick_destroyed(points: int) -> void:
	if not is_inside_tree(): return
	score += points
	Events.score_updated.emit(score)
	bricks_remaining -= 1
	if bricks_remaining == 0:
		Events.level_completed.emit()
		get_tree().paused = true

func _on_bonus_points_gained(points: int) -> void:
	if not is_inside_tree(): return
	score += points
	Events.score_updated.emit(score)
	
func _on_ball_lost() -> void:
	if not is_inside_tree(): return
	var active_balls = 0
	for b in get_tree().get_nodes_in_group("ball"):
		if not b.is_queued_for_deletion():
			active_balls += 1
			
	if active_balls == 0:
		lives -= 1
		Events.lives_updated.emit(lives)
		if lives > 0:
			spawn_ball()
		else:
			Events.game_over.emit()
			get_tree().paused = true
		
func _on_level_ready(total: int) -> void:
	bricks_remaining = total
	
func spawn_ball() -> void:
	var ball = BallScene.instantiate()
	ball.direction = Vector2.ZERO
	var paddle = get_tree().get_first_node_in_group("paddle")
	ball.attach_node = paddle
	get_parent().call_deferred("add_child", ball)
	Events.ball_spawned.emit.call_deferred()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		Events.ball_launched.emit()
		
func _on_life_gained() -> void:
	if lives < MAX_LIVES:
		lives += 1
		Events.lives_updated.emit(lives)
	else:
		_on_bonus_points_gained(500)

func _on_multiball_activated() -> void:
	if not is_inside_tree(): return
	var paddle = get_tree().get_first_node_in_group("paddle")
	if not is_instance_valid(paddle): return
	var directions = [Vector2(-1, -1).normalized(), Vector2(1, -1).normalized()]
	for dir in directions:
		var ball = BallScene.instantiate()
		ball.global_position = paddle.global_position - Vector2(0, 40)
		ball.direction = dir
		ball.is_launched = true
		get_parent().call_deferred("add_child", ball)