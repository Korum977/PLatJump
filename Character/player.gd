extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -500.0  # Increased jump force
@export var max_fall_speed : float = 400.0  # Reduced max fall speed for better control
@export var max_health : float = 100.0  # Maximum health value
@export var invincibility_duration : float = 1.0  # Duration of invincibility after taking damage

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.5  # More floaty feel
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var score : float = 0
var max_height : float = 0
var can_jump : bool = true
var last_platform_collision : Node2D = null
var is_dead : bool = false  # Track if player is dead
var current_health : float  # Current health value
var is_invincible : bool = false  # Track invincibility state
var invincibility_timer : float = 0.0  # Timer for invincibility duration

# Add a constant for the death Y-coordinate threshold
const DEATH_Y_THRESHOLD = 400.0

# Add signals for better state management
signal health_changed(new_health: float)
signal player_died
signal player_respawned

func _ready():
	current_health = max_health
	emit_signal("health_changed", current_health)

func _process(delta):
	# Handle quitting the game
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	# Update invincibility timer
	if is_invincible:
		invincibility_timer += delta
		if invincibility_timer >= invincibility_duration:
			is_invincible = false
			invincibility_timer = 0.0
			animated_sprite.modulate.a = 1.0  # Restore full opacity

func _physics_process(delta):
	if is_dead:
		# Disable all movement and input when dead
		velocity = Vector2.ZERO
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)  # Cap fall speed
		was_in_air = true
	else:
		was_in_air = false
		can_jump = true

	# Handle Jump
	if Input.is_action_just_pressed("jump") and can_jump:
		jump()
		can_jump = false

	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_vector("left", "right", "up", "down")
	
	if direction.x != 0 && animated_sprite.animation != "jump_end":
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 0.1)  # Smoother horizontal movement

	# Screen wrap (Doodle Jump style)
	var viewport_size = get_viewport_rect().size
	if position.x < 0:
		position.x = viewport_size.x
	elif position.x > viewport_size.x:
		position.x = 0

	# Update score based on maximum height reached
	var current_height = -position.y  # Convert position to height (higher y is negative in Godot)
	if current_height > max_height:
		max_height = current_height
		score = max_height  # Score is based on maximum height reached

	# Check if the player has fallen below the death threshold
	if position.y > DEATH_Y_THRESHOLD and not is_dead:
		die()
		return

	# Handle platform collisions
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.has_method("handle_collision"):
			# Store the last platform we collided with
			last_platform_collision = collider
			# Handle platform collision
			var bounce_velocity = collider.handle_collision(self, collision.get_normal())
			if bounce_velocity != 0:
				velocity.y = bounce_velocity
				can_jump = true
				# Play jump animation when bouncing
				if bounce_velocity < 0:
					animated_sprite.play("jump_start")
					animation_locked = true
	
	# Handle one-way platform pass-through
	if Input.is_action_pressed("down") and is_on_floor():
		# Temporarily disable one-way collision to drop through platforms
		set_collision_mask_value(2, false)
		await get_tree().create_timer(0.2).timeout
		set_collision_mask_value(2, true)
	
	move_and_slide()
	update_animation()
	update_facing_direction()

func update_animation():
	if not animation_locked:
		if is_dead:
			animated_sprite.play("dead")
		elif not is_on_floor():
			if velocity.y < 0:
				animated_sprite.play("jump_start")
			else:
				animated_sprite.play("jump_loop")
		else:
			if direction.x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")

func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
		
func jump():
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animation_locked = true

func die():
	if is_dead:
		return
		
	is_dead = true
	animated_sprite.play("dead")
	# Stop all movement
	velocity = Vector2.ZERO
	# Disable collision with enemies and platforms
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)
	
	# Add a slight delay before showing game over to allow death animation to play
	await get_tree().create_timer(0.5).timeout
	emit_signal("player_died")

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == "jump_start":
		animated_sprite.play("jump_loop")
		animation_locked = false
	elif animated_sprite.animation == "jump_end":
		animation_locked = false
		
func take_damage(amount: float):
	if is_dead or is_invincible:
		return
		
	current_health -= amount
	emit_signal("health_changed", current_health)
	
	if current_health <= 0:
		current_health = 0
		die()
	else:
		# Activate invincibility frames with visual feedback
		is_invincible = true
		invincibility_timer = 0.0
		animated_sprite.modulate.a = 0.5  # Visual feedback for invincibility
		
		# Flash effect when taking damage
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(animated_sprite, "modulate:a", 0.5, 0.1)
		tween.set_loops(2)

		
