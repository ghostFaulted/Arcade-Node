extends Node

signal brick_destroyed(points: int)
signal ball_lost
signal level_ready(total_bricks: int)
signal score_updated(new_score: int)
signal lives_updated(new_lives: int)
signal game_over
signal level_completed
signal layout_calculated(play_area: Rect2, slider_y: float, paddle_y: float)
signal paddle_exact_x_moved(target_x: float)
signal ball_launched
signal ball_spawned
signal speed_updated(normalized_ratio: float)
