extends ParallaxBackground

@onready var camera = get_viewport().get_camera_2d()
var last_camera_pos : Vector2

func _ready():
	if camera:
		last_camera_pos = camera.global_position

func _process(_delta):
	if camera:
		# Calculate camera movement
		var camera_movement = camera.global_position - last_camera_pos
		# Scroll the background based on camera movement
		scroll_offset += camera_movement
		last_camera_pos = camera.global_position 
