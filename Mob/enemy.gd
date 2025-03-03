extends Area2D

@export var move_speed: float = 100.0
@export var patrol_range: float = 200.0
@export var attack_range: float = 100.0
@export var damage: float = 10.0
@export var health: float = 50.0
@export var chase_speed_multiplier: float = 1.5
@export var attack_cooldown: float = 1.0

var start_position: Vector2
var target_position: Vector2
var current_state: String = "patrol"
var player: Node2D = null
var attack_timer: float = 0.0
var can_attack: bool = true

signal enemy_died

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	start_position = position
	target_position = start_position + Vector2(patrol_range, 0)
	animated_sprite.play("fly")

func _physics_process(delta):
	match current_state:
		"patrol":
			patrol_behavior(delta)
		"chase":
			chase_behavior(delta)
		"attack":
			attack_behavior(delta)
	
	# Update attack cooldown
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0

func patrol_behavior(delta):
	# Move towards target position
	var direction = (target_position - position).normalized()
	position += direction * move_speed * delta
	
	# Update sprite direction
	animated_sprite.flip_h = direction.x < 0
	
	# Check if reached target position
	if position.distance_to(target_position) < 5:
		# Switch target position
		if target_position == start_position + Vector2(patrol_range, 0):
			target_position = start_position - Vector2(patrol_range, 0)
		else:
			target_position = start_position + Vector2(patrol_range, 0)
	
	# Check for player in range
	if player and position.distance_to(player.position) < attack_range:
		current_state = "chase"

func chase_behavior(delta):
	if not player:
		current_state = "patrol"
		return
		
	var direction = (player.position - position).normalized()
	position += direction * move_speed * chase_speed_multiplier * delta
	
	# Update sprite direction
	animated_sprite.flip_h = direction.x < 0
	
	# Check if in attack range
	if position.distance_to(player.position) < attack_range and can_attack:
		current_state = "attack"
		animated_sprite.play("attack")
	
	# Check if player is too far
	if position.distance_to(player.position) > attack_range * 2:
		current_state = "patrol"
		animated_sprite.play("fly")

func attack_behavior(delta):
	if not player:
		current_state = "patrol"
		return
		
	# Stay in place while attacking
	if animated_sprite.animation == "attack" and animated_sprite.frame == 2:
		# Deal damage at the middle of the attack animation
		if player.has_method("take_damage") and can_attack:
			player.take_damage(damage)
			can_attack = false
	
	# Return to chase state after attack animation
	if animated_sprite.animation == "attack" and animated_sprite.frame == animated_sprite.sprite_frames.get_frame_count("attack") - 1:
		current_state = "chase"
		animated_sprite.play("fly")

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null
		current_state = "patrol"

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage") and can_attack:
		body.take_damage(damage)
		can_attack = false

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		die()
	else:
		animated_sprite.play("hit")
		await animated_sprite.animation_finished
		animated_sprite.play("fly")

func die():
	if animated_sprite.sprite_frames.has_animation("hit"):
		animated_sprite.play("hit")
		await animated_sprite.animation_finished
	emit_signal("enemy_died")
	queue_free() 
