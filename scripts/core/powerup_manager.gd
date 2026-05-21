extends Node

const PowerUpScene = preload("res://scenes/entities/PowerUpDrop.tscn")

@export var base_chance: float = 0.04   
@export var chance_step: float = 0.04   
@export var max_on_screen: int = 3

var current_chance: float = 0.04
var active_powerups_count: int = 0

@export var powerup_pool: Dictionary = {
	"slow_ball": 30,
	"wide_paddle": 20,
	"multiball": 10,
	"extra_life": 5
}

func _ready() -> void:
	Events.request_powerup_drop.connect(_on_request_drop)
	Events.powerup_freed.connect(_on_powerup_freed)
	Events.level_ready.connect(_on_level_ready)

func _on_request_drop(spawn_pos: Vector2) -> void:
	if active_powerups_count >= max_on_screen:
		print("[DEBUG] Power-up spawn frozen. Max on screen reached. Current chance: ", current_chance * 100.0, "%")
		return
	var roll = randf()
	print("[DEBUG] Roll: ", snapped(roll * 100.0, 0.1), "% | Chance to drop: ", current_chance * 100.0, "%")
	if roll <= current_chance:
		current_chance = base_chance 
		print("[DEBUG] SUCCESS! Power-up dropped. Chance reset to: ", current_chance * 100.0, "%")
		_spawn_powerup(spawn_pos)
	else:
		current_chance += chance_step
		print("[DEBUG] FAILURE. Chance increased to: ", current_chance * 100.0, "%")

func _spawn_powerup(pos: Vector2) -> void:
	var chosen_type = _get_weighted_random()
	var drop = PowerUpScene.instantiate()
	drop.type = chosen_type
	drop.global_position = pos
	if chosen_type == "slow_ball": 
		drop.modulate = Color.BLUE
	elif chosen_type == "wide_paddle": 
		drop.modulate = Color.GREEN
	elif chosen_type == "multiball": 
		drop.modulate = Color.WHITE
	elif chosen_type == "extra_life": 
		drop.modulate = Color.RED
	get_tree().current_scene.call_deferred("add_child", drop)
	active_powerups_count += 1

func _get_weighted_random() -> String:
	var total_weight = 0
	for key in powerup_pool:
		total_weight += powerup_pool[key]
	if total_weight <= 0:
		return "slow_ball"
	var random_val = randi() % total_weight
	var current_weight = 0
	for key in powerup_pool:
		current_weight += powerup_pool[key]
		if random_val < current_weight:
			return key
	return powerup_pool.keys()[0]
	
func _on_powerup_freed() -> void:
	active_powerups_count = max(0, active_powerups_count - 1) 
	print("[DEBUG] Power-up freed. Active remaining: ", active_powerups_count)
	
func _on_level_ready(total_bricks: int) -> void:
	active_powerups_count = 0
	current_chance = base_chance
	print("[DEBUG] PowerUpManager RESET. Active: ", active_powerups_count, " | Chance: ", current_chance * 100.0, "%")
