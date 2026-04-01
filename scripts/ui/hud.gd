extends CanvasLayer

func _ready() -> void:
	Events.score_updated.connect(_on_score_updated)
	Events.lives_updated.connect(_on_lives_updated)

func _on_score_updated(new_score: int) -> void:
	$MarginContainer/HBoxContainer/ScoreLabel.text = "Score: " + str(new_score)
	
func _on_lives_updated(new_lives: int) -> void:
	$MarginContainer/HBoxContainer/LivesLabel.text = "Lives: " + str(new_lives)
