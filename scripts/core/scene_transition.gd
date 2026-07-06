extends CanvasLayer

var color_rect: ColorRect

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func change_scene(path: String) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.3)
	await tween.finished
	
	get_tree().change_scene_to_file(path)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "color:a", 0.0, 0.3)
	await tween_out.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func reload_scene() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.3)
	await tween.finished
	
	get_tree().reload_current_scene()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "color:a", 0.0, 0.3)
	await tween_out.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
