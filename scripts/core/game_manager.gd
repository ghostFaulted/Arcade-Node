extends Node

const BallScene = preload("res://scenes/entities/Ball.tscn")
var score: int = 0
var lives: int = 3
var bricks_remaining: int = 0

func _ready() -> void:
	Events.brick_destroyed.connect(_on_brick_destroyed)
	Events.ball_lost.connect(_on_ball_lost)
	Events.level_ready.connect(_on_level_ready)
	Events.score_updated.emit.call_deferred(0)
	Events.lives_updated.emit.call_deferred(3)
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	var paddle_y = screen_size.y * 0.65
	var slider_y = paddle_y + 50.0
	Events.layout_calculated.emit(screen_size, slider_y, paddle_y)
	spawn_ball()
	
func _on_brick_destroyed(points: int) -> void:
	score += points
	Events.score_updated.emit(score)
	bricks_remaining -= 1
	if bricks_remaining <= 0:
		Events.level_completed.emit()
		get_tree().paused = true
	
func _on_ball_lost() -> void:
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
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		Events.ball_launched.emit()
