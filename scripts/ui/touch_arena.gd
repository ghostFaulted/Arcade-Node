extends Control
signal paddle_moved(normalized_x: float)

func  _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var norm_x = event.position.x / size.x
		norm_x = clampf(norm_x, 0.0, 1.0)
		paddle_moved.emit(norm_x)
