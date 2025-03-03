extends Control

signal score_changed(new_score: float)

@onready var score_label = $ScoreLabel
@onready var player = get_node("/root/TestLevel/Player")
@onready var enemy_spawner = get_node("/root/TestLevel/EnemySpawner")

var last_score: float = 0

func _ready():
	# Connect score changed signal to enemy spawner
	if enemy_spawner:
		score_changed.connect(enemy_spawner.update_difficulty)

func _process(_delta):
	if not player:
		return
		
	# Update score display
	var current_score = player.score
	if current_score != last_score:
		score_label.text = "Score: %d" % int(current_score)
		emit_signal("score_changed", current_score)
		last_score = current_score 
