extends Node2D

@export var base_spawn_interval: float = 5.0  # Base time between spawns
@export var min_spawn_interval: float = 2.0  # Minimum spawn interval at max difficulty
@export var max_enemies_base: int = 3  # Base maximum number of enemies
@export var max_enemies_increment: float = 0.5  # How many enemies to add per 1000 score
@export var spawn_margin: float = 50.0  # Margin from viewport edges for spawning
@export var difficulty_scale_score: float = 1000.0  # Score at which difficulty increases

var enemy_scene = preload("res://Mob/enemy.tscn")
var current_enemies: int = 0
var spawn_timer: float = 0.0
var current_score: float = 0.0
var current_spawn_interval: float
var current_max_enemies: int

func _ready():
	# Start with base difficulty
	current_spawn_interval = base_spawn_interval
	current_max_enemies = max_enemies_base
	# Start with a random initial spawn time
	spawn_timer = randf_range(0, base_spawn_interval)

func _process(delta):
	spawn_timer += delta
	
	if spawn_timer >= current_spawn_interval and current_enemies < current_max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func update_difficulty(score: float):
	current_score = score
	
	# Calculate new spawn interval based on score
	var difficulty_factor = score / difficulty_scale_score
	current_spawn_interval = max(min_spawn_interval, base_spawn_interval - difficulty_factor)
	
	# Calculate new max enemies based on score
	var additional_enemies = floor(score / difficulty_scale_score * max_enemies_increment)
	current_max_enemies = max_enemies_base + int(additional_enemies)

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	
	# Get viewport and camera information
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	var viewport_size = viewport.get_visible_rect().size
	
	# Calculate spawn position relative to camera
	var camera_pos = camera.global_position
	
	# Calculate spawn area bounds with better margins
	var spawn_left = camera_pos.x - viewport_size.x/2 + spawn_margin
	var spawn_right = camera_pos.x + viewport_size.x/2 - spawn_margin
	var spawn_top = camera_pos.y - viewport_size.y/2  # Spawn in upper half of screen
	var spawn_bottom = camera_pos.y - viewport_size.y/4  # Spawn in upper quarter of screen
	
	# Randomly choose spawn side (left, right, or top) with weighted probabilities
	var spawn_side = randi() % 100
	var spawn_pos = Vector2.ZERO
	
	if spawn_side < 40:  # 40% chance for left side
		spawn_pos = Vector2(
			spawn_left,
			randf_range(spawn_top, spawn_bottom)
		)
	elif spawn_side < 80:  # 40% chance for right side
		spawn_pos = Vector2(
			spawn_right,
			randf_range(spawn_top, spawn_bottom)
		)
	else:  # 20% chance for top
		spawn_pos = Vector2(
			randf_range(spawn_left, spawn_right),
			spawn_top
		)
	
	enemy.position = spawn_pos
	
	# Scale enemy stats based on score with smoother progression
	var difficulty_multiplier = 1.0 + (current_score / difficulty_scale_score * 0.15)  # 15% stronger per difficulty level
	enemy.health *= difficulty_multiplier
	enemy.damage *= difficulty_multiplier
	enemy.move_speed *= (1.0 + (current_score / difficulty_scale_score * 0.08))  # 8% faster per difficulty level
	
	current_enemies += 1
	
	# Connect to enemy's death signal
	enemy.enemy_died.connect(_on_enemy_destroyed)

func _on_enemy_destroyed():
	current_enemies -= 1 