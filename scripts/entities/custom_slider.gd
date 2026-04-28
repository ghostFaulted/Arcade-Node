extends Control

@export var paddle_half_width: float = 60.0
@export var track_color: Color = Color.WHITE
@export var track_thickness: float = 4.0
@export var track_radius: float = 50.0
@onready var knob = $Knob

func _ready() -> void:
	await get_tree().process_frame
	var center_y = (size.y - knob.size.y) / 2.0
	knob.position.y = center_y
	var center_x = size.x / 2.0
	var margin = track_radius + (track_thickness / 2.0)
	var target_x = clampf(center_x, margin, size.x - margin)
	knob.position.x = target_x - (knob.size.x / 2.0)
	Events.paddle_exact_x_moved.emit(global_position.x + target_x)

func _gui_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	var is_valid_touch = (event is InputEventScreenTouch and event.is_pressed()) or event is InputEventScreenDrag
	var is_valid_mouse = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))	
	if is_valid_touch or is_valid_mouse:
		var touch_x = event.position.x
		var margin = track_radius + (track_thickness / 2.0)
		var target_x = clampf(touch_x, margin, size.x - margin)
		knob.position.x = target_x - (knob.size.x / 2.0)
		Events.paddle_exact_x_moved.emit(global_position.x + target_x)
		
func _draw() -> void:
	var center_y = size.y / 2.0
	var offset = track_thickness / 2.0
	var left_center = Vector2(track_radius + offset, center_y)
	var right_center = Vector2(size.x - track_radius - offset, center_y)
	draw_arc(left_center, track_radius, PI/2.0, 3.0*PI/2.0, 32, track_color, track_thickness, true)
	draw_arc(right_center, track_radius, -PI/2.0, PI/2.0, 32, track_color, track_thickness, true)
	var top_left = left_center + Vector2(0, -track_radius)
	var top_right = right_center + Vector2(0, -track_radius)
	var bottom_left = left_center + Vector2(0, track_radius)
	var bottom_right = right_center + Vector2(0, track_radius)
	draw_line(top_left, top_right, track_color, track_thickness, true)
	draw_line(bottom_left, bottom_right, track_color, track_thickness, true)
