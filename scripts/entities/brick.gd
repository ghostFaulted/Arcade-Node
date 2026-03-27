extends StaticBody2D
@export var max_hp: int = 1
var current_hp: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_hp = max_hp
	
func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		Events.brick_destroyed.emit(10)
		queue_free()
