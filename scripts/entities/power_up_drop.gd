extends Area2D

@export var fall_speed: float = 300.0
var type: String = "none"

func _ready() -> void:
	fall_speed *= Events.vertical_speed_scale
	add_to_group("powerups")
	monitorable = true
	monitoring = true 
	collision_layer = 1 
	collision_mask = 1  
	body_entered.connect(_on_body_entered)
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape != null and col_shape.shape != null:
		col_shape.disabled = false

func _process(delta: float) -> void:
	global_position.y += fall_speed * delta
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("paddle"):
		Events.powerup_collected.emit(type)
		queue_free()
