extends Control

@onready var health_label = $HealthLabel
@onready var player = get_node("/root/TestLevel/Player")

func _ready():
	# Connect to player's signals
	player.player_died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	player.player_respawned.connect(_on_player_respawned)
	
	# Set initial health display
	update_health_display(player.current_health)
	
	# Ensure UI is visible
	show()

func _process(_delta):
	if not player.is_dead:
		update_health_display(player.current_health)

func update_health_display(health: float):
	var health_int = int(health)
	health_label.text = "Health: %d" % health_int
	
	# Update color based on health percentage
	var health_percent = health / player.max_health
	if health_percent > 0.6:
		health_label.modulate = Color(0, 1, 0)  # Green
	elif health_percent > 0.3:
		health_label.modulate = Color(1, 1, 0)  # Yellow
	else:
		health_label.modulate = Color(1, 0, 0)  # Red

func _on_health_changed(new_health: float):
	update_health_display(new_health)

func _on_player_died():
	# When player dies, ensure health shows 0 and set to red
	health_label.text = "Health: 0"
	health_label.modulate = Color(1, 0, 0)  # Red
	# Add a slight fade effect
	var tween = create_tween()
	tween.tween_property(health_label, "modulate:a", 0.5, 0.3)
	tween.tween_property(health_label, "modulate:a", 1.0, 0.3)

func _on_player_respawned():
	# Reset health display when player respawns
	update_health_display(player.current_health)
	# Ensure full opacity
	health_label.modulate.a = 1.0 
