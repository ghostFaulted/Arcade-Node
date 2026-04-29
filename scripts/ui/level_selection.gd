extends Control

func start_level(index: int) -> void:
	LevelManager.current_level_index = index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
func _on_btn_level_1_pressed() -> void:
	start_level(0)
	
func _on_btn_level_2_pressed() -> void:
	start_level(1)
	
func _on_btn_level_3_pressed() -> void:
	start_level(2)

func _ready() -> void:
	apply_safe_area()
	
func apply_safe_area() -> void:
	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.screen_get_size()
	if window_size.y == 0: return
	var top_ratio = float(safe_area.position.y) / float(window_size.y)
	var viewport_height = get_viewport().get_visible_rect().size.y
	var safe_margin_top = top_ratio * viewport_height
	$MarginContainer.add_theme_constant_override("margin_top", safe_margin_top + 20)
	
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
