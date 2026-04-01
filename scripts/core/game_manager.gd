extends Node

const BallScene = preload("res://scenes/entities/Ball.tscn")
var score: int = 0
var lives: int = 3
@export var spawn_point: Marker2D
var bricks_remaining: int = 0


func _ready() -> void:
	Events.brick_destroyed.connect(_on_brick_destroyed)
	Events.ball_lost.connect(_on_ball_lost)
	Events.level_ready.connect(_on_level_ready)
	Events.score_updated.emit.call_deferred(0)
	Events.lives_updated.emit.call_deferred(3)
	#print("Game started. Lives: ", lives)
	spawn_ball()
	
func _on_brick_destroyed(points: int) -> void:
	score += points
	Events.score_updated.emit(score)
	#print("Score: ", score)
	bricks_remaining -= 1
	if bricks_remaining <= 0:
		print("Level completed!")
		get_tree().paused = true
	
func _on_ball_lost() -> void:
	lives -= 1
	Events.lives_updated.emit(lives)
	#print("Ball lost! Lives remaining: ", lives)
	if lives > 0:
		spawn_ball()
	else:
		print("GAME OVER")
		
func _on_level_ready(total: int) -> void:
	bricks_remaining = total
	print("Level loaded. Total bricks: ", bricks_remaining)
	
func spawn_ball() -> void:
	var ball = BallScene.instantiate()
	ball.direction = Vector2.ZERO
	ball.global_position = spawn_point.global_position
	get_parent().call_deferred("add_child", ball)
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(ball):
		ball.direction = Vector2.DOWN
