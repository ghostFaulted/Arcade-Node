extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var thickness = 100.0
	
	#TopWall
	$Walls/TopWall.shape.size = Vector2(screen_size.x + thickness * 2.0, thickness)
	$Walls/TopWall.position = Vector2(screen_size.x / 2.0, -thickness / 2.0)
	#LeftWall
	$Walls/LeftWall.shape.size = Vector2(thickness, screen_size.y)
	$Walls/LeftWall.position = Vector2(-thickness / 2.0, screen_size.y / 2.0)
	#RightWall
	$Walls/RightWall.shape.size = Vector2(thickness, screen_size.y)
	$Walls/RightWall.position = Vector2(screen_size.x + thickness / 2.0, screen_size.y / 2.0)
	#BottomZone 
	$Killzone/BottomZone.shape.size = Vector2(screen_size.x, thickness)
	$Killzone/BottomZone.position = Vector2(screen_size.x / 2.0, screen_size.y + thickness / 2.0)


func _on_killzone_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		body.queue_free()
		Events.ball_lost.emit()
