extends CharacterBody2D

@export var min_speed: float = 850.0
@export var max_speed: float = 1300.0
@export var speed_step: float = 10.0
@export var slow_speed: float = 550.0
@export var sway_speed: float = 0.75
@export var direction: Vector2 = Vector2.ZERO
const MAX_BOUNCE_ANGLE: float = PI / 3.0
const MAX_LAUNCH_ANGLE: float = deg_to_rad(60.0)

var is_launched: bool = false
var attach_offset_y: float = 0.0
var damage: int = 1
var visual_scale: float = 1.0
var is_slowed: bool = false 
var is_swaying: bool = true 
var sway_time: float = 0.0
var launch_direction: Vector2 = Vector2.UP
@onready var trajectory_line = $TrajectoryLine
var attach_offset_x: float = 0.0

var attach_node: Node2D:
	set(value):
		attach_node = value
		if is_instance_valid(attach_node):
			var paddle_col = attach_node.get_node("CollisionShape2D")
			var paddle_thickness = paddle_col.shape.radius * 2.0
			var ball_radius = $CollisionShape2D.shape.radius * visual_scale
			attach_offset_y = (paddle_thickness / 2.0) + ball_radius

var current_speed: float:
	set(value):
		if is_slowed and value > current_speed:
			return 
			
		current_speed = clampf(value, min_speed, max_speed)
		var ratio = (current_speed - min_speed) / (max_speed - min_speed)
		Events.speed_updated.emit(ratio)

func _ready() -> void:
	min_speed *= Events.vertical_speed_scale
	max_speed *= Events.vertical_speed_scale
	speed_step *= Events.vertical_speed_scale
	slow_speed *= Events.vertical_speed_scale
	
	var inherited_speed = min_speed
	var existing_balls = get_tree().get_nodes_in_group("ball")
	for b in existing_balls:
		if b != self and is_instance_valid(b) and not b.is_queued_for_deletion():
			inherited_speed = b.current_speed
			break
			
	current_speed = inherited_speed
	
	if existing_balls.size() <= 1:
		Events.speed_updated.emit((current_speed - min_speed) / (max_speed - min_speed))
		
	direction = direction.normalized()
	
	Events.ball_launched.connect(_on_launch)
	Events.ball_big_state_changed.connect(_on_ball_big_state_changed)
	Events.ball_slow_state_changed.connect(_on_ball_slow_state_changed)
	Events.paddle_exact_x_moved.connect(_on_exact_x_moved)
	
	for other_ball in get_tree().get_nodes_in_group("ball"):
		if other_ball != self:
			add_collision_exception_with(other_ball)
			other_ball.add_collision_exception_with(self)
			
	add_to_group("ball")
	
	is_swaying = true
	sway_time = 0.0
	
	if is_launched:
		trajectory_line.visible = false
	else:
		trajectory_line.visible = true
		
	if PowerUpManager.active_ball_powerup == "slow_ball":
		_on_ball_slow_state_changed(true)
	elif PowerUpManager.active_ball_powerup == "big_ball":
		_on_ball_big_state_changed(true)

func _process(delta: float) -> void:
	if not is_launched and is_instance_valid(attach_node):
		var col_pos = attach_node.get_node("CollisionShape2D").global_position
		global_position = col_pos + Vector2(attach_offset_x, -attach_offset_y)

func _physics_process(delta: float) -> void:
	if not is_launched:
		_update_trajectory()
		return  
	var movement = direction * current_speed * delta
	var damaged_objects: Array = []
	for i in range(4):
		var collision = move_and_collide(movement)
		if not collision:
			break
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		if collider.is_in_group("paddle"):
			if collider.get("is_magnet_active") == true and collider.get("attached_ball") == null:
				attach_offset_x = global_position.x - collider.global_position.x
				var ball_rad = $CollisionShape2D.shape.radius * visual_scale
				attach_offset_x = clampf(attach_offset_x, -collider.half_width + ball_rad, collider.half_width - ball_rad)
				is_launched = false
				attach_node = collider
				collider.attached_ball = self
				trajectory_line.visible = true
				
				is_swaying = true
				sway_time = 0.0
				
				Events.ball_caught.emit()
				continue
			if normal.y < -0.2 and direction.y > 0:
				var offset = global_position.x - collider.global_position.x
				var normalized_offset = clampf(offset / collider.half_width, -1.0, 1.0)
				var bounce_angle = normalized_offset * MAX_BOUNCE_ANGLE
				direction = Vector2.UP.rotated(bounce_angle).normalized()
				_increase_global_speed(speed_step)
			else:
				var paddle_shape = collider.get_node("CollisionShape2D").shape
				var paddle_top_y = collider.global_position.y - paddle_shape.radius
				var ball_radius = $CollisionShape2D.shape.radius * visual_scale
				global_position.y = paddle_top_y - ball_radius - 1.0
				var offset_dir = sign(global_position.x - collider.global_position.x)
				if offset_dir == 0: offset_dir = 1.0
				direction = Vector2(offset_dir * 0.5, -1.0).normalized() 
		else:
			direction = direction.bounce(normal).normalized()
		if abs(direction.y) < 0.2:
			var dir_sign = sign(direction.y) if direction.y != 0 else 1.0
			direction.y = 0.2 * dir_sign
			direction = direction.normalized()
		if collider.has_method("take_damage"):
			if not collider in damaged_objects:
				collider.take_damage(damage)
				damaged_objects.append(collider)
				_increase_global_speed(speed_step)
		elif not collider.is_in_group("paddle") and normal.y > 0.8:
			_increase_global_speed(5.0 * speed_step)
		var remainder = collision.get_remainder()
		movement = direction * remainder.length()

func _increase_global_speed(amount: float) -> void:
	if is_slowed: return
	
	var balls = get_tree().get_nodes_in_group("ball")
	var valid_balls = 0
	
	for b in balls:
		if not b.is_queued_for_deletion():
			valid_balls += 1
			
	if valid_balls == 0: valid_balls = 1
	
	var actual_step = amount / float(valid_balls)
	var new_speed = clampf(current_speed + actual_step, min_speed, max_speed)
	
	for b in balls:
		if not b.is_queued_for_deletion():
			if b.current_speed != new_speed:
				b.current_speed = new_speed

func _update_trajectory() -> void:
	if not is_instance_valid(attach_node): return 
	
	if is_swaying:
		sway_time += get_process_delta_time()
		var angle = sin(sway_time * sway_speed) * MAX_LAUNCH_ANGLE
		launch_direction = Vector2.UP.rotated(angle).normalized()
	else:
		var p_min = attach_node.min_x
		var p_max = attach_node.max_x
		var center_x = (p_max + p_min) / 2.0
		var half_range = (p_max - p_min) / 2.0
		var offset = global_position.x - center_x
		var normalized_pos = clampf(offset / half_range, -1.0, 1.0) 
		var angle = -normalized_pos * MAX_LAUNCH_ANGLE
		launch_direction = Vector2.UP.rotated(angle).normalized()
		
	trajectory_line.clear_points()
	trajectory_line.add_point(Vector2.ZERO) 
	var space_state = get_world_2d().direct_space_state
	var current_global_pos = global_position
	var current_dir = launch_direction
	var max_distance = 2000.0
	var query1 = PhysicsRayQueryParameters2D.create(current_global_pos, current_global_pos + current_dir * max_distance)
	query1.exclude = [self.get_rid(), attach_node.get_rid()] 
	query1.collide_with_areas = false 
	var result1 = space_state.intersect_ray(query1)
	if result1:
		var hit_pos1_local = result1.position - global_position
		trajectory_line.add_point(hit_pos1_local)
		var normal1 = result1.normal
		var bounce_dir = current_dir.bounce(normal1)
		var ray2_start = result1.position + normal1 * 2.0 
		var query2 = PhysicsRayQueryParameters2D.create(ray2_start, ray2_start + bounce_dir * max_distance)
		query2.exclude = [self.get_rid(), attach_node.get_rid()]
		query2.collide_with_areas = false
		var result2 = space_state.intersect_ray(query2)
		var ray2_end_global: Vector2
		if result2:
			ray2_end_global = result2.position
		else:
			ray2_end_global = ray2_start + bounce_dir * max_distance
		var floor_y = global_position.y
		if ray2_end_global.y > floor_y:
			if bounce_dir.y > 0:
				var t = (floor_y - ray2_start.y) / bounce_dir.y
				ray2_end_global = ray2_start + bounce_dir * t
		var hit_pos2_local = ray2_end_global - global_position
		trajectory_line.add_point(hit_pos2_local)
	else:
		trajectory_line.add_point(current_dir * max_distance)

func _on_launch() -> void:
	if not is_launched:
		is_launched = true
		direction = launch_direction
		trajectory_line.visible = false
		if is_instance_valid(attach_node) and attach_node.is_in_group("paddle"):
			if attach_node.get("attached_ball") == self:
				attach_node.attached_ball = null

func _on_exact_x_moved(new_x: float) -> void:
	if is_swaying:
		is_swaying = false
		Events.ball_aimed.emit()
		
func _draw() -> void:
	var radius = $CollisionShape2D.shape.radius * visual_scale
	draw_circle(Vector2.ZERO, radius, Color.YELLOW)
	
func _on_ball_big_state_changed(active: bool) -> void:
	if active:
		damage = 2
		visual_scale = 1.5
	else:
		damage = 1
		visual_scale = 1.0
	$CollisionShape2D.scale = Vector2(visual_scale, visual_scale)
	queue_redraw()

func _on_ball_slow_state_changed(active: bool) -> void:
	is_slowed = active
	if is_slowed:
		current_speed = slow_speed
	else:
		current_speed = min_speed
