extends StaticBody2D
@export var max_hp: int = 1
var current_hp: int

func _ready() -> void:
	current_hp = max_hp
	
func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		Events.brick_destroyed.emit(10)
		Events.request_powerup_drop.emit(global_position)
		queue_free()
