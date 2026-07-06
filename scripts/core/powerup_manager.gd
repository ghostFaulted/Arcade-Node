extends Node

const PowerUpScene = preload("res://scenes/entities/PowerUpDrop.tscn")

var base_chance: float = 0.03
var current_chance: float = 0.03
var chance_step: float = 0.03
var max_on_screen: int = 3

var powerup_pool = {
	"slow_ball": 30,
	"big_ball": 30,
	"multiball": 30,
	"wide_paddle": 30,
	"shield": 30,
	"laser": 30,
	"extra_life": 5,
	"magnet": 30
}

var active_paddle_powerup: String = ""
var active_ball_powerup: String = ""
var paddle_timer: Timer
var ball_timer: Timer
var current_paddle_duration: float = 10.0
var current_ball_duration: float = 10.0
var group_paddle = ["wide_paddle", "shield", "laser", "magnet"]
var group_ball = ["slow_ball", "big_ball"]
var group_instant = ["multiball", "extra_life"]
var is_level_active: bool = false

func _ready() -> void:
	Events.request_powerup_drop.connect(_on_request_drop)
	Events.powerup_collected.connect(_on_powerup_collected)
	Events.ball_spawned.connect(reset_all_powerups)
	Events.level_ready.connect(_on_level_ready)
	Events.level_cleared_start_anim.connect(_on_level_ended)
	Events.game_over.connect(_on_level_ended)
	
	paddle_timer = Timer.new()
	paddle_timer.one_shot = true
	paddle_timer.timeout.connect(_on_paddle_timer_timeout)
	add_child(paddle_timer)
	
	ball_timer = Timer.new()
	ball_timer.one_shot = true
	ball_timer.timeout.connect(_on_ball_timer_timeout)
	add_child(ball_timer)

func _on_request_drop(spawn_pos: Vector2) -> void:
	if not is_level_active:
		return
	var current_powerups = get_tree().get_nodes_in_group("powerups").size()
	if current_powerups >= max_on_screen:
		return
	var roll = randf()
	if roll <= current_chance:
		current_chance = base_chance 
		_spawn_powerup(spawn_pos)
	else:
		var active_count: int = 0
		if active_paddle_powerup != "": active_count += 1
		if active_ball_powerup != "": active_count += 1
		var dynamic_step = chance_step
		if active_count == 1:
			dynamic_step = chance_step / 2.0
		elif active_count == 2:
			dynamic_step = chance_step / 4.0
			
		var active_balls = 0
		for b in get_tree().get_nodes_in_group("ball"):
			if not b.is_queued_for_deletion():
				active_balls += 1
				
		if active_balls > 1:
			dynamic_step = dynamic_step / float(active_balls)
			
		current_chance += dynamic_step

func _spawn_powerup(pos: Vector2) -> void:
	var chosen_type = _get_weighted_random()
	var drop = PowerUpScene.instantiate()
	drop.type = chosen_type
	drop.global_position = pos
	if chosen_type == "slow_ball": drop.modulate = Color.BLUE
	elif chosen_type == "multiball": drop.modulate = Color.WHITE
	elif chosen_type == "wide_paddle": drop.modulate = Color.GREEN
	elif chosen_type == "extra_life": drop.modulate = Color.RED
	elif chosen_type == "big_ball": drop.modulate = Color.ORANGE
	elif chosen_type == "shield": drop.modulate = Color.CYAN
	elif chosen_type == "laser": drop.modulate = Color.YELLOW
	elif chosen_type == "magnet": drop.modulate = Color.PURPLE
	get_tree().current_scene.call_deferred("add_child", drop)

func _get_weighted_random() -> String:
	var total_weight = 0
	for key in powerup_pool:
		total_weight += powerup_pool[key]
	var random_val = randi() % total_weight
	var current_weight = 0
	for key in powerup_pool:
		current_weight += powerup_pool[key]
		if random_val < current_weight:
			return key
	return powerup_pool.keys()[0]

func _on_powerup_collected(type: String) -> void:
	if type in group_instant:
		_apply_instant_powerup(type)
	elif type in group_paddle:
		_apply_paddle_powerup(type)
	elif type in group_ball:
		_apply_ball_powerup(type)

func _apply_instant_powerup(type: String) -> void:
	if type == "extra_life":
		Events.life_gained.emit()
	elif type == "multiball":
		Events.multiball_activated.emit()

func _apply_paddle_powerup(type: String) -> void:
	if active_paddle_powerup != "" and active_paddle_powerup != type:
		_remove_paddle_powerup(active_paddle_powerup)
	active_paddle_powerup = type
	current_paddle_duration = _get_powerup_duration(type)
	paddle_timer.start(current_paddle_duration)
	if type == "wide_paddle":
		Events.paddle_size_changed.emit(170)
	elif type == "shield":
		Events.shield_state_changed.emit(true)
	elif type == "laser":
		Events.paddle_laser_state_changed.emit(true)
	elif type == "magnet":
		Events.paddle_magnet_state_changed.emit(true)

func _apply_ball_powerup(type: String) -> void:
	if active_ball_powerup != "" and active_ball_powerup != type:
		_remove_ball_powerup(active_ball_powerup)
	active_ball_powerup = type
	current_ball_duration = _get_powerup_duration(type)
	ball_timer.start(current_ball_duration)
	if type == "slow_ball":
		Events.ball_slow_state_changed.emit(true)
	elif type == "big_ball":
		Events.ball_big_state_changed.emit(true)

func _on_paddle_timer_timeout() -> void:
	_remove_paddle_powerup(active_paddle_powerup)
	active_paddle_powerup = ""

func _on_ball_timer_timeout() -> void:
	_remove_ball_powerup(active_ball_powerup)
	active_ball_powerup = ""

func _remove_paddle_powerup(type: String) -> void:
	if type == "wide_paddle":
		Events.paddle_size_changed.emit(130.0)
	elif type == "shield":
		Events.shield_state_changed.emit(false)
	elif type == "laser":
		Events.paddle_laser_state_changed.emit(false)
	elif type == "magnet":
		Events.paddle_magnet_state_changed.emit(false)

func _remove_ball_powerup(type: String) -> void:
	if type == "slow_ball":
		Events.ball_slow_state_changed.emit(false)
	elif type == "big_ball":
		Events.ball_big_state_changed.emit(false)

func reset_all_powerups() -> void:
	if active_paddle_powerup != "":
		_remove_paddle_powerup(active_paddle_powerup)
		active_paddle_powerup = ""
		paddle_timer.stop()
		
	if active_ball_powerup != "":
		_remove_ball_powerup(active_ball_powerup)
		active_ball_powerup = ""
		ball_timer.stop()
		
	for drop in get_tree().get_nodes_in_group("powerups"):
		drop.queue_free()
	
func _get_powerup_duration(type: String) -> float:
	if type == "big_ball": return 15.0
	return 10.0
	
func _on_level_ready(total_bricks: int) -> void:
	is_level_active = true
	
func _on_level_ended() -> void:
	is_level_active = false
	reset_all_powerups()
