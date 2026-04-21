extends CanvasLayer

var is_game_over: bool = false

func _ready() -> void:
	Events.score_updated.connect(_on_score_updated)
	Events.lives_updated.connect(_on_lives_updated)
	Events.game_over.connect(_on_game_over)
	Events.level_completed.connect(_on_level_completed)
	Events.layout_calculated.connect(_on_layout_calculated)
	apply_safe_area()

func _on_score_updated(new_score: int) -> void:
	$MarginContainer/HBoxContainer/ScoreLabel.text = "Score: " + str(new_score)
	
func _on_lives_updated(new_lives: int) -> void:
	$MarginContainer/HBoxContainer/LivesLabel.text = "Lives: " + str(new_lives)
	
func _on_game_over() -> void:
	$Overlay/CenterContainer/VBoxContainer/MessageLabel.text = "GAME OVER"
	$Overlay.visible = true
	is_game_over = true
	
func _on_level_completed() -> void:
	$Overlay/CenterContainer/VBoxContainer/MessageLabel.text = "YOU WIN!"
	$Overlay.visible = true
	is_game_over = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	is_game_over = false
	get_tree().reload_current_scene()

func _on_paddle_controller_value_changed(value: float) -> void:
	Events.paddle_slider_moved.emit(value)
	
func _on_layout_calculated(screen_size: Vector2, slider_y: float, paddle_y: float) -> void:
	$CustomSlider.size.x = screen_size.x
	$CustomSlider.size.y = 120.0
	$CustomSlider.position.y = slider_y
	$CustomSlider.queue_redraw()

func _on_pause_button_pressed() -> void:
	if is_game_over: return
	get_tree().paused = true
	$PauseOverlay.visible = true
	$MarginContainer/HBoxContainer/PauseButton.disabled = true

func _on_resume_button_pressed() -> void:
	$PauseOverlay.visible = false
	$MarginContainer/HBoxContainer/PauseButton.disabled = false
	get_tree().paused = false

func _on_menu_button_pressed() -> void:
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
	get_tree().paused = false
	is_game_over = false
	get_tree().reload_current_scene()
