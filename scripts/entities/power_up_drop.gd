extends Area2D

@export var fall_speed: float = 300.0
var type: String = "none"

func _ready() -> void:
	add_to_group("powerups")
	
	monitorable = true
	monitoring = false 
	collision_layer = 1 
	collision_mask = 1  
	
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape == null:
		print("[CRITICAL ERROR] PowerUpDrop has NO CollisionShape2D node as a child!")
	elif col_shape.shape == null:
		print("[CRITICAL ERROR] PowerUpDrop CollisionShape2D has NO SHAPE assigned in Inspector (it is empty)!")
	else:
		col_shape.disabled = false

func _process(delta: float) -> void:
	global_position.y += fall_speed * delta
