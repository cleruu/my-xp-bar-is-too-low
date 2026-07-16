extends Area2D

@export var moveSpeed: float = 120.0
@export var hit_sound: AudioStream = null

var player: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collisionShape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Set up collision - ONLY detect player, ignore obstacles
	collision_layer = 0
	collision_mask = 1  # Only detect player (layer 1)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# SET HITBOX SAME AS PLAYER STAND SIZE (192x264)
	if collisionShape and collisionShape.shape is RectangleShape2D:
		collisionShape.shape.size = Vector2(192, 264)
		collisionShape.position = Vector2(0, -132)
	
	# Hide ColorRect if it exists
	if has_node("ColorRect"):
		$ColorRect.visible = false
	
	# Position at left edge (fixed position)
	position = Vector2(0, 580)
	
	# PLAY RUNNING ANIMATION CONTINUOUSLY
	if animated_sprite:
		animated_sprite.play("run")
		animated_sprite.flip_h = false  # Facing right
		animated_sprite.position = Vector2(0, -132)  # Match collision shape

func _process(delta: float):
	# Enemy stays at fixed position - NO CHASING
	position = Vector2(0, 580)
	
	# Keep animation running
	if animated_sprite and not animated_sprite.is_playing():
		animated_sprite.play("run")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var controller = get_tree().current_scene
		
		# Play hit sound through controller (persists through scene change)
		if controller and controller.has_method("play_sound") and hit_sound:
			var pitch = randf_range(0.9, 1.1)
			controller.play_sound(hit_sound, 0, pitch)
			print("🔊 Enemy caught player! Sound playing!")
		
		# INSTANT GAME OVER (sound continues playing)
		if controller and controller.has_method("_on_game_over"):
			# Add small delay so sound plays before scene changes
			await get_tree().create_timer(0.3).timeout
			controller._on_game_over()
		else:
			await get_tree().create_timer(0.3).timeout
			get_tree().change_scene_to_file("res://Scenes/LevelTwo/gameOver.tscn")
