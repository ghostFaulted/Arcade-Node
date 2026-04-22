extends CharacterBody2D

@export var speed: float = 800.0
@export var direction: Vector2 = Vector2.ZERO
const MAX_BOUNCE_ANGLE: float = PI / 3.0
var is_launched: bool = false
var attach_node: Node2D

# Physics of the Ball
func _physics_process(delta: float) -> void:
	if not is_launched:
		if is_instance_valid(attach_node):
			global_position = attach_node.global_position - Vector2(0, 30)
		return
	var movement = direction * speed * delta
	var has_damaged: bool = false
	for i in range(4):
		var collision = move_and_collide(movement)
		if not collision:
			break
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		if collider.has_method("take_damage"):
			if not has_damaged:
				collider.take_damage(1)
				has_damaged = true
		if collider.is_in_group("paddle") and normal.y < -0.5 and direction.y > 0:
			var offset = global_position.x - collider.global_position.x
			var normalized_offset = clampf(offset / collider.half_width, -1.0, 1.0)
			var bounce_angle = normalized_offset * MAX_BOUNCE_ANGLE
			direction = Vector2.UP.rotated(bounce_angle).normalized()
		else:
			direction = direction.bounce(collision.get_normal()).normalized()
		var remainder = collision.get_remainder()
		movement = direction * remainder.length()

func _ready() -> void:
	direction = direction.normalized()
	Events.ball_launched.connect(_on_launch)
	
func _on_launch() -> void:
	if not is_launched:
		is_launched = true
		direction = Vector2.UP
