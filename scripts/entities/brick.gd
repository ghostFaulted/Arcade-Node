extends StaticBody2D

var type: int = 1
var current_hp: int = 1
var is_unbreakable: bool = false

const COLOR_3HP = Color.RED
const COLOR_2HP = Color.ORANGE
const COLOR_1HP = Color.GREEN
const COLOR_UNBREAKABLE = Color(0.3, 0.3, 0.3, 1.0)

func _ready() -> void:
	if type == 9:
		is_unbreakable = true
		current_hp = 999
	else:
		is_unbreakable = false
		current_hp = type
		
	_update_color()
	
func take_damage(amount: int) -> void:
	if is_unbreakable:
		return
		
	current_hp -= amount
	
	if current_hp <= 0:
		Events.brick_destroyed.emit(10)
		Events.request_powerup_drop.emit(global_position)
		queue_free()
	else:
		_update_color()

func _update_color() -> void:
	if is_unbreakable:
		$ColorRect.color = COLOR_UNBREAKABLE
	elif current_hp >= 3:
		$ColorRect.color = COLOR_3HP
	elif current_hp == 2:
		$ColorRect.color = COLOR_2HP
	else:
		$ColorRect.color = COLOR_1HP
