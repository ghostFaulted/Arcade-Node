extends Node

const BallScene = preload("res://scenes/entities/Ball.tscn")
var score: int = 0
var lives: int = 3
@export var spawn_point: Marker2D

func _ready() -> void:
	Events.brick_destroyed.connect(_on_brick_destroyed)
	Events.ball_lost.connect(_on_ball_lost)
	print("Game started. Lives: ", lives)
	spawn_ball()
	
func _on_brick_destroyed(points: int) -> void:
	score += points
	print("Score: ", score)
	
func _on_ball_lost() -> void:
	lives -= 1
	print("Ball lost! Lives remaining: ", lives)
	if lives > 0:
		spawn_ball()
	else:
		print("GAME OVER")
		
func spawn_ball() -> void:
	var ball = BallScene.instantiate()
	ball.direction = Vector2.ZERO
	ball.global_position = spawn_point.global_position
	get_parent().call_deferred("add_child", ball)
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(ball):
		ball.direction = Vector2.DOWN
