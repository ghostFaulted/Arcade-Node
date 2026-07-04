extends Control

@onready var grid = $MarginContainer/CenterContainer/VBoxContainer/ScrollContainer/GridContainer

func _ready() -> void:
	apply_safe_area()
	
	for child in grid.get_children():
		child.queue_free()
		
	var total_levels = LevelManager.levels.size()
	for i in range(total_levels):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 130)
		btn.add_theme_font_size_override("font_size", 56)
		btn.text = str(i + 1)
		
		if i <= LevelManager.max_unlocked_level or LevelManager.GOD_MODE:
			btn.pressed.connect(func(): start_level(i))
		else:
			btn.modulate = Color(0.4, 0.4, 0.4, 0.8)
			btn.pressed.connect(func(): show_locked_message(i))
			
		grid.add_child(btn)

func start_level(index: int) -> void:
	LevelManager.current_level_index = index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
func show_locked_message(target_index: int) -> void:
	$LockedPopup/CenterContainer/VBoxContainer/MessageLabel.text = "You need to complete\nLevel " + str(target_index) + " first!"
	$LockedPopup.visible = true

func _on_popup_ok_pressed() -> void:
	$LockedPopup.visible = false
	
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