extends CanvasLayer

@export var prompt_y_offset: float = 150.0
var is_game_over: bool = false
var is_waiting_for_launch: bool = false
var has_aimed: bool = false 
var hint_timer: Timer

func _ready() -> void:
	Events.score_updated.connect(_on_score_updated)
	Events.lives_updated.connect(_on_lives_updated)
	Events.game_over.connect(_on_game_over)
	Events.level_completed.connect(_on_level_completed)
	Events.layout_calculated.connect(_on_layout_calculated)
	Events.ball_spawned.connect(_on_ball_spawned)
	Events.ball_launched.connect(_on_ball_launched)
	Events.ball_caught.connect(_on_ball_spawned)
	Events.ball_aimed.connect(_on_ball_aimed)
	apply_safe_area()
	
	hint_timer = Timer.new()
	hint_timer.one_shot = true
	hint_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	add_child(hint_timer)

func _on_score_updated(new_score: int) -> void:
	$MarginContainer/HBoxContainer/ScoreLabel.text = "Score: " + str(new_score)
	
func _on_lives_updated(new_lives: int) -> void:
	$MarginContainer/HBoxContainer/LivesLabel.text = "Lives: " + str(new_lives)
	
func _on_game_over() -> void:
	$Overlay/CenterContainer/VBoxContainer/MessageLabel.text = "GAME OVER"
	$Overlay/CenterContainer/VBoxContainer/NextLevelButton.visible = false
	$Overlay/CenterContainer/VBoxContainer/RestartButton.visible = true
	$Overlay/CenterContainer/VBoxContainer/MenuButton.visible = true
	$Overlay.visible = true
	$CenterContainer.visible = false 
	is_game_over = true
	
func _on_level_completed() -> void:
	is_game_over = true
	$Overlay.visible = true
	$CenterContainer.visible = false 
	$Overlay/CenterContainer/VBoxContainer/RestartButton.visible = true
	$Overlay/CenterContainer/VBoxContainer/MenuButton.visible = true
	if LevelManager.has_next_level():
		$Overlay/CenterContainer/VBoxContainer/MessageLabel.text = "LEVEL COMPLETED!"
		$Overlay/CenterContainer/VBoxContainer/NextLevelButton.visible = true
	else:
		$Overlay/CenterContainer/VBoxContainer/MessageLabel.text = "GAME BEATEN!"
		$Overlay/CenterContainer/VBoxContainer/NextLevelButton.visible = false

func _on_restart_button_pressed() -> void:
	if not is_inside_tree(): return
	get_tree().paused = false
	is_game_over = false
	get_tree().reload_current_scene()

func _on_paddle_controller_value_changed(value: float) -> void:
	Events.paddle_slider_moved.emit(value)
	
	if is_waiting_for_launch and has_aimed:
		$CenterContainer/PromptLabel.modulate.a = 0.0
		hint_timer.start(4.0)
	
func _on_layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float) -> void:
	$CustomSlider.size.x = play_area.size.x
	$CustomSlider.position.x = play_area.position.x
	$CustomSlider.size.y = 150.0
	$CustomSlider.position.y = slider_y
	$CustomSlider.queue_redraw()
	var slot_y = slider_y - 70.0
	var center_x = play_area.position.x + (play_area.size.x / 2.0)
	var slot_width = 60.0
	var gap = 20.0
	$PaddleSlot.position = Vector2(center_x - slot_width - (gap / 2.0), slot_y)
	$BallSlot.position = Vector2(center_x + (gap / 2.0), slot_y)
	$CenterContainer.position.y = prompt_y_offset

func _on_pause_button_pressed() -> void:
	if not is_inside_tree() or is_game_over: return
	get_tree().paused = true
	$PauseOverlay.visible = true
	$MarginContainer/HBoxContainer/PauseButton.disabled = true
	$CenterContainer.visible = false 

func _on_resume_button_pressed() -> void:
	if not is_inside_tree(): return
	$PauseOverlay.visible = false
	$MarginContainer/HBoxContainer/PauseButton.disabled = false
	get_tree().paused = false
	$CenterContainer.visible = true

func _on_menu_button_pressed() -> void:
	if not is_inside_tree(): return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelection.tscn")
	
func apply_safe_area() -> void:
	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.screen_get_size()
	if window_size.y == 0: return
	var top_ratio = float(safe_area.position.y) / float(window_size.y)
	var viewport_height = get_viewport().get_visible_rect().size.y
	var safe_margin_top = top_ratio * viewport_height
	$MarginContainer.add_theme_constant_override("margin_top", 20 + safe_margin_top)

func _on_pause_restart_button_pressed() -> void:
	if not is_inside_tree(): return
	get_tree().paused = false
	is_game_over = false
	get_tree().reload_current_scene()
	
func _on_ball_spawned() -> void:
	if not is_inside_tree(): return
	is_waiting_for_launch = true
	has_aimed = false
	$CenterContainer/PromptLabel.visible = true
	
	$CenterContainer/PromptLabel.text = "Move slider to aim"
	$CenterContainer/PromptLabel.modulate.a = 0.0
	
	hint_timer.start(4.0)
	
func _on_ball_launched() -> void:
	if not is_inside_tree(): return
	is_waiting_for_launch = false
	$CenterContainer/PromptLabel.visible = false
	hint_timer.stop()

func _on_next_level_button_pressed() -> void:
	if not is_inside_tree(): return
	get_tree().paused = false
	is_game_over = false
	LevelManager.current_level_index += 1
	get_tree().reload_current_scene()
	
func _on_hint_timer_timeout() -> void:
	if is_waiting_for_launch and not is_game_over:
		$CenterContainer/PromptLabel.modulate.a = 1.0

func _on_ball_aimed() -> void:
	if not is_inside_tree() or not is_waiting_for_launch: return

	has_aimed = true
	
	$CenterContainer/PromptLabel.modulate.a = 0.0
	
	$CenterContainer/PromptLabel.text = "Tap here to launch"
	
	hint_timer.start(4.0)
