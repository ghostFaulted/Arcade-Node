extends Node

var vertical_speed_scale: float = 1.0

signal brick_destroyed(points: int)
signal bonus_points_gained(points: int)
signal ball_lost
signal level_ready(total_bricks: int)
signal score_updated(new_score: int)
signal lives_updated(new_lives: int)
signal game_over
signal level_completed
signal level_cleared_start_anim
signal layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float)
signal paddle_exact_x_moved(target_x: float)
signal ball_launched
signal ball_spawned
signal speed_updated(normalized_ratio: float)
signal request_powerup_drop(spawn_position: Vector2)
signal powerup_freed
signal powerup_collected(type: String)
signal life_gained
signal paddle_size_changed(new_width: float)
signal ball_big_state_changed(is_active: bool)
signal ball_slow_state_changed(active: bool)
signal shield_state_changed(is_active: bool)
signal paddle_laser_state_changed(is_active: bool)
signal paddle_magnet_state_changed(is_active: bool)
signal ball_caught
signal multiball_activated
signal ball_aimed
signal door_opened
signal level_skip_entered
signal ball_ghost_state_changed(is_active: bool)
