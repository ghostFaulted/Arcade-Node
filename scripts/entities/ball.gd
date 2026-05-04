extends CharacterBody2D

@export var min_speed: float = 700.0
@export var max_speed: float = 1100.0
@export var speed_step: float = 7.5
@export var direction: Vector2 = Vector2.ZERO
const MAX_BOUNCE_ANGLE: float = PI / 3.0
var is_launched: bool = false
var attach_offset_y: float = 0.0
var attach_node: Node2D:
	set(value):
		attach_node = value
		if is_instance_valid(attach_node):
			var paddle_col = attach_node.get_node("CollisionShape2D")
			var paddle_thickness = paddle_col.shape.size.y 
			var ball_radius = $CollisionShape2D.shape.radius
			attach_offset_y = (paddle_thickness / 2.0) + ball_radius

var current_speed: float:
	set(value):
		current_speed = clampf(value, min_speed, max_speed)
		var ratio = (current_speed - min_speed) / (max_speed - min_speed)
		Events.speed_updated.emit(ratio)
		print("[DEBUG] Ball Speed: ", current_speed)

func _process(delta: float) -> void:
	if not is_launched and is_instance_valid(attach_node):
		var col_pos = attach_node.get_node("CollisionShape2D").global_position
		global_position = col_pos - Vector2(0, attach_offset_y)

func _physics_process(delta: float) -> void:
	if not is_launched:
		return  
	var movement = direction * current_speed * delta
	var has_damaged: bool = false
	for i in range(4):
		var collision = move_and_collide(movement)
		if not collision:
			break
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		if collider.is_in_group("paddle"):
			if normal.y < -0.5 and direction.y > 0:
				var offset = global_position.x - collider.global_position.x
				var normalized_offset = clampf(offset / collider.half_width, -1.0, 1.0)
				var bounce_angle = normalized_offset * MAX_BOUNCE_ANGLE
				direction = Vector2.UP.rotated(bounce_angle).normalized()
				current_speed += speed_step 
			else:
				direction = direction.bounce(normal).normalized()
				direction.y = -abs(direction.y) - 0.5
				direction = direction.normalized()
				global_position.y -= 3.0
		else:
			direction = direction.bounce(normal).normalized()
		if abs(direction.y) < 0.2:
			var dir_sign = sign(direction.y) if direction.y != 0 else 1.0
			direction.y = 0.2 * dir_sign
			direction = direction.normalized()
		if collider.has_method("take_damage"):
			if not has_damaged:
				collider.take_damage(1)
				has_damaged = true
				current_speed += speed_step
		elif not collider.is_in_group("paddle") and normal.y > 0.8:
			current_speed += (5.0 * speed_step)
		var remainder = collision.get_remainder()
		movement = direction * remainder.length()

func _ready() -> void:
	current_speed = min_speed
	Events.speed_updated.emit(0.0)
	direction = direction.normalized()
	Events.ball_launched.connect(_on_launch)
	
func _on_launch() -> void:
	if not is_launched:
		is_launched = true
		direction = Vector2.UP
		
func _draw() -> void:
	var radius = $CollisionShape2D.shape.radius
	draw_circle(Vector2.ZERO, radius, Color.YELLOW)
