extends Control

@onready var game_over_label = $SafeArea/CenterContainer/VBoxContainer/GameOverLabel
@onready var restart_button = $SafeArea/CenterContainer/VBoxContainer/RestartButton
@onready var background = $ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	# Start hidden
	hide()
	modulate.a = 0  # Start fully transparent
	background.color.a = 0  # Start with transparent background
	
	# Set up input handling
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	restart_button.mouse_entered.connect(_on_RestartButton_mouse_entered)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Only handle clicks if they're not on the button
			var local_click = event.position
			var button_rect = restart_button.get_global_rect()
			if not button_rect.has_point(get_global_mouse_position()):
				_on_RestartButton_pressed()

# Show the game over HUD with a fade effect
func show_game_over():
	# Pause the game
	get_tree().paused = true
	
	# Reset button state
	restart_button.disabled = false
	restart_button.grab_focus()
	
	# Show the HUD
	show()
	
	# Create a fade-in effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(background, "color:a", 0.7, 0.5)

# Restart the game when the button is pressed
func _on_RestartButton_pressed():
	if restart_button.disabled:
		return
		
	# Prevent double-clicking
	restart_button.disabled = true
	
	# Create a fade-out effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(background, "color:a", 0.0, 0.3)
	
	# Wait for fade out before restarting
	await tween.finished
	
	# Unpause and reload
	get_tree().paused = false
	get_tree().reload_current_scene()
	hide()

func _on_RestartButton_mouse_entered():
	if not restart_button.disabled:
		restart_button.grab_focus() 
