extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
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
