extends AnimatableBody2D

var screen_width: float = 0.0
var half_width: float = 0.0
var min_x: float = 0.0
var max_x: float = 0.0
var target_x: float = 0.0
var target_y: float = 0.0
var current_play_area: Rect2
const LaserScene = preload("res://scenes/entities/LaserBeam.tscn")
var base_color: Color = Color.DEEP_PINK
var is_magnet_active: bool = false
var attached_ball: Node2D = null

func _ready() -> void:
	add_to_group("paddle")
	Events.paddle_exact_x_moved.connect(_on_exact_x_moved)
	Events.layout_calculated.connect(_on_layout_calculated)
	Events.paddle_size_changed.connect(_on_paddle_size_changed)
	Events.paddle_laser_state_changed.connect(_on_paddle_laser_state_changed)
	$LaserTimer.timeout.connect(_on_laser_timer_timeout)
	Events.paddle_magnet_state_changed.connect(_on_paddle_magnet_state_changed)

func _on_layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float) -> void:
	current_play_area = play_area
	screen_width = play_area.size.x
	half_width = $CollisionShape2D.shape.height / 2.0
	min_x = play_area.position.x + half_width
	max_x = play_area.position.x + play_area.size.x - half_width
	target_x = play_area.position.x + play_area.size.x / 2.0
	target_y = paddle_y

func _on_exact_x_moved(new_x: float) -> void:
	target_x = clampf(new_x, min_x, max_x)

func _process(delta: float) -> void:
	if screen_width > 0:
		global_position = Vector2(target_x, target_y)
		
func _on_paddle_size_changed(new_width: float) -> void:
	$CollisionShape2D.shape.height = new_width
	$Panel.size.x = new_width
	$Panel.position.x = -(new_width / 2.0)
	half_width = new_width / 2.0
	min_x = current_play_area.position.x + half_width
	max_x = current_play_area.position.x + current_play_area.size.x - half_width
	queue_redraw()
	
func _on_paddle_laser_state_changed(active: bool) -> void:
	var style = $Panel.get_theme_stylebox("panel").duplicate()
	if active:
		style.bg_color = Color.YELLOW
		$LaserTimer.start()
	else:
		style.bg_color = base_color
		$LaserTimer.stop()
	$Panel.add_theme_stylebox_override("panel", style)
	
func _on_laser_timer_timeout() -> void:
	var l1 = LaserScene.instantiate()
	l1.global_position = global_position + Vector2(-half_width + 20.0, -40.0) 
	get_parent().add_child(l1)
	var l2 = LaserScene.instantiate()
	l2.global_position = global_position + Vector2(half_width - 20.0, -40.0)
	get_parent().add_child(l2)
	
func _on_paddle_magnet_state_changed(active: bool) -> void:
	is_magnet_active = active
	var style = $Panel.get_theme_stylebox("panel").duplicate()
	if active:
		style.bg_color = Color.PURPLE
	else:
		style.bg_color = Color.DEEP_PINK
		if is_instance_valid(attached_ball):
			Events.ball_launched.emit() 
	$Panel.add_theme_stylebox_override("panel", style)
	
