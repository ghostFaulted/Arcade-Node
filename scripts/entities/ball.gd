extends CharacterBody2D

@export var min_speed: float = 850.0
@export var max_speed: float = 1300.0
@export var speed_step: float = 10.0
@export var slow_speed: float = 550.0
@export var sway_speed: float = 0.30 
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

var is_ghost_active: bool = false
var ghost_landing_pos: Vector2 = Vector2.INF
var ghost_path: PackedVector2Array = PackedVector2Array()
var _needs_ghost_update: bool = true
var ghost_marker: Node2D 
var _prev_dir_y: float = 0.0

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
	_prev_dir_y = direction.y
	
	ghost_marker = Node2D.new()
	ghost_marker.top_level = true 
	add_child(ghost_marker)
	ghost_marker.draw.connect(_on_ghost_marker_draw)
	
	Events.ball_launched.connect(_on_launch)
	Events.ball_big_state_changed.connect(_on_ball_big_state_changed)
	Events.ball_slow_state_changed.connect(_on_ball_slow_state_changed)
	Events.ball_ghost_state_changed.connect(_on_ball_ghost_state_changed)
	Events.paddle_exact_x_moved.connect(_on_exact_x_moved)
	Events.level_cleared_start_anim.connect(queue_free)
	
	Events.brick_destroyed.connect(func(_p): _needs_ghost_update = true)
	
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
	elif PowerUpManager.active_ball_powerup == "ghost_ball":
		_on_ball_ghost_state_changed(true)

func _process(delta: float) -> void:
	if not is_launched and is_instance_valid(attach_node):
		var col_pos = attach_node.get_node("CollisionShape2D").global_position
		global_position = col_pos + Vector2(attach_offset_x, -attach_offset_y)
		
	if is_ghost_active and ghost_landing_pos != Vector2.INF:
		ghost_marker.queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_launched:
		_update_trajectory()
		return  
		
	var movement = direction * current_speed * delta
	var damaged_objects: Array = []
	var trajectory_changed = false
	
	for i in range(4):
		var collision = move_and_collide(movement)
		if not collision:
			break
			
		trajectory_changed = true
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
				_needs_ghost_update = true
				Events.ball_caught.emit()
				continue
				
			if normal.y < -0.2 and direction.y > 0:
				_increase_global_speed(speed_step)
			else:
				var paddle_shape = collider.get_node("CollisionShape2D").shape
				var paddle_top_y = collider.global_position.y - paddle_shape.radius
				var ball_radius = $CollisionShape2D.shape.radius * visual_scale
				global_position.y = paddle_top_y - ball_radius - 1.0
				
			var offset = global_position.x - collider.global_position.x
			var normalized_offset = clampf(offset / collider.half_width, -1.0, 1.0)
			var bounce_angle = normalized_offset * MAX_BOUNCE_ANGLE
			direction = Vector2.UP.rotated(bounce_angle).normalized() 
		else:
			if collider.is_in_group("brick"):
				if abs(abs(normal.x) - abs(normal.y)) < 0.2:
					var screen_center_x = get_viewport_rect().size.x / 2.0
					var to_center = sign(screen_center_x - global_position.x)
					if to_center == 0: to_center = 1.0
					var bend_angle = deg_to_rad(2.5)
					normal = normal.rotated(-to_center * sign(normal.y) * bend_angle).normalized()
					
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

	var is_below_paddle = false
	var paddle = get_tree().get_first_node_in_group("paddle")
	if is_instance_valid(paddle):
		var paddle_shape = paddle.get_node("CollisionShape2D").shape
		var ball_radius = $CollisionShape2D.shape.radius * visual_scale
		var target_y = paddle.global_position.y - paddle_shape.radius - ball_radius
		if global_position.y > target_y:
			is_below_paddle = true

	var dir_y_changed_to_down = (direction.y > 0 and _prev_dir_y <= 0)
	_prev_dir_y = direction.y

	if is_below_paddle or direction.y <= 0:
		if ghost_landing_pos != Vector2.INF:
			ghost_landing_pos = Vector2.INF
			ghost_path.clear()
			ghost_marker.queue_redraw()
	elif trajectory_changed or _needs_ghost_update or dir_y_changed_to_down:
		if is_ghost_active and is_launched:
			ghost_landing_pos = _get_predicted_landing_point()
		else:
			ghost_landing_pos = Vector2.INF
			ghost_path.clear()
			
		if ghost_landing_pos != Vector2.INF:
			ghost_marker.global_position = ghost_landing_pos
			ghost_marker.queue_redraw()
		else:
			ghost_marker.queue_redraw()
			
		_needs_ghost_update = false

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

func _sweep_cast(space_state: PhysicsDirectSpaceState2D, start: Vector2, dir: Vector2, radius: float, exclude: Array) -> Dictionary:
	var max_distance = 2000.0
	var perp = Vector2(-dir.y, dir.x) * (radius - 0.5)
	var q_center = PhysicsRayQueryParameters2D.create(start, start + dir * max_distance)
	var q_left = PhysicsRayQueryParameters2D.create(start + perp, start + perp + dir * max_distance)
	var q_right = PhysicsRayQueryParameters2D.create(start - perp, start - perp + dir * max_distance)
	
	for q in [q_center, q_left, q_right]:
		q.exclude = exclude
		q.collide_with_areas = false
		
	var r_center = space_state.intersect_ray(q_center)
	var r_left = space_state.intersect_ray(q_left)
	var r_right = space_state.intersect_ray(q_right)
	
	var d_center = r_center.position.distance_to(start) if r_center else INF
	var d_left = r_left.position.distance_to(start + perp) if r_left else INF
	var d_right = r_right.position.distance_to(start - perp) if r_right else INF
	
	var min_dist = minf(d_center, minf(d_left, d_right))
	if min_dist == INF: return {}
		
	var result_dict = {}
	result_dict["distance"] = min_dist
	result_dict["position"] = start + dir * min_dist 
	
	var winner = {}
	if min_dist == d_center:
		winner = r_center
	elif min_dist == d_left:
		winner = r_left
	else:
		winner = r_right
		
	result_dict["normal"] = winner.normal
	result_dict["collider"] = winner.collider
	result_dict["rid"] = winner.rid
		
	return result_dict

func _get_predicted_landing_point() -> Vector2:
	ghost_path.clear()
	if direction.length_squared() == 0: return Vector2.INF
	var paddle = get_tree().get_first_node_in_group("paddle")
	if not is_instance_valid(paddle): return Vector2.INF
	
	var space_state = get_world_2d().direct_space_state
	var exclude = [self.get_rid(), paddle.get_rid()]
	var paddle_shape = paddle.get_node("CollisionShape2D").shape
	var ball_radius = $CollisionShape2D.shape.radius * visual_scale
	var target_y = paddle.global_position.y - paddle_shape.radius - ball_radius
	
	var current_pos = global_position
	var current_dir = direction
	var max_bounces = 20
	
	ghost_path.append(current_pos)
	
	for i in range(max_bounces):
		var dist_to_paddle = INF
		if current_dir.y > 0:
			var t = (target_y - current_pos.y) / current_dir.y
			if t >= 0:
				dist_to_paddle = t
				
		var hit = _sweep_cast(space_state, current_pos, current_dir, ball_radius, exclude)
		
		if hit:
			var hit_dist = current_pos.distance_to(hit.position)
			
			if dist_to_paddle != INF and dist_to_paddle < hit_dist:
				var final_pos = current_pos + current_dir * dist_to_paddle
				ghost_path.append(final_pos)
				return final_pos
				
			if hit.has("collider") and is_instance_valid(hit.collider) and hit.collider.is_in_group("brick") and hit.collider.get("is_dying") == true:
				exclude.append(hit.rid)
				continue
				
			ghost_path.append(hit.position)
			current_pos = hit.position + hit.normal * 1.5
			current_dir = current_dir.bounce(hit.normal).normalized()
			
			if abs(current_dir.y) < 0.2:
				var dir_sign = sign(current_dir.y) if current_dir.y != 0 else 1.0
				current_dir.y = 0.2 * dir_sign
				current_dir = current_dir.normalized()
		else:
			if dist_to_paddle != INF:
				var final_pos = current_pos + current_dir * dist_to_paddle
				ghost_path.append(final_pos)
				return final_pos
			break
			
	return Vector2.INF

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
	var exclude = [self.get_rid(), attach_node.get_rid()]
	var radius = $CollisionShape2D.shape.radius * visual_scale
	
	var hit1 = _sweep_cast(space_state, global_position, launch_direction, radius, exclude)
	if hit1:
		var hit_pos1_local = hit1.position - global_position
		trajectory_line.add_point(hit_pos1_local)
		var normal1 = hit1.normal
		var bounce_dir = launch_direction.bounce(normal1).normalized()
		var ray2_start = hit1.position + normal1 * 1.5 
		var hit2 = _sweep_cast(space_state, ray2_start, bounce_dir, radius, exclude)
		var ray2_end_global: Vector2
		if hit2: 
			ray2_end_global = hit2.position
		else: 
			ray2_end_global = ray2_start + bounce_dir * 2000.0
			
		var floor_y = global_position.y
		if ray2_end_global.y > floor_y and bounce_dir.y > 0:
			var t = (floor_y - ray2_start.y) / bounce_dir.y
			ray2_end_global = ray2_start + bounce_dir * t
				
		var hit_pos2_local = ray2_end_global - global_position
		trajectory_line.add_point(hit_pos2_local)
	else:
		trajectory_line.add_point(launch_direction * 2000.0)

func _on_launch() -> void:
	if not is_launched:
		is_launched = true
		direction = launch_direction
		trajectory_line.visible = false
		_needs_ghost_update = true
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
	
func _on_ghost_marker_draw() -> void:
	if not is_ghost_active or ghost_landing_pos == Vector2.INF:
		return
		
	var radius = $CollisionShape2D.shape.radius * visual_scale
	var ghost_color = Color(1.0, 1.0, 1.0, 0.4)
	var line_color = Color(1.0, 1.0, 1.0, 0.15)
	
	if ghost_path.size() >= 2:
		var local_points = PackedVector2Array()
		local_points.append(ghost_marker.to_local(global_position))
		
		for i in range(1, ghost_path.size()):
			local_points.append(ghost_marker.to_local(ghost_path[i]))
			
		ghost_marker.draw_polyline(local_points, line_color, 2.0, true)
	
	ghost_marker.draw_circle(Vector2.ZERO, radius, ghost_color)
	
func _on_ball_big_state_changed(active: bool) -> void:
	if active:
		damage = 2
		visual_scale = 1.5
	else:
		damage = 1
		visual_scale = 1.0
	$CollisionShape2D.scale = Vector2(visual_scale, visual_scale)
	_needs_ghost_update = true
	queue_redraw()

func _on_ball_slow_state_changed(active: bool) -> void:
	is_slowed = active
	if is_slowed:
		current_speed = slow_speed
	else:
		current_speed = min_speed
	_needs_ghost_update = true

func _on_ball_ghost_state_changed(active: bool) -> void:
	is_ghost_active = active
	_needs_ghost_update = true
	if not active:
		ghost_landing_pos = Vector2.INF
		ghost_path.clear()
	queue_redraw()
	ghost_marker.queue_redraw()
