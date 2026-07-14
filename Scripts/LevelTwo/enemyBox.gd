extends Area2D

@export var moveSpeed: float = 120.0

var player: Node2D = null

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Set up collision - ONLY detect player, ignore obstacles
	collision_layer = 0
	collision_mask = 1  # Only detect player (layer 1)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Visual - make it orange, match player size (192x264)
	if has_node("ColorRect"):
		$ColorRect.size = Vector2(192, 264)
		$ColorRect.position = Vector2(-96, -264)  # Offset up by full height
		$ColorRect.color = Color(1, 0.5, 0)  # Orange
	
	# Make collision shape match player size
	if has_node("CollisionShape2D"):
		var shape = $CollisionShape2D.shape
		if shape and shape is RectangleShape2D:
			shape.size = Vector2(192, 264)
		$CollisionShape2D.position = Vector2(0, -132)  # Offset up by half height
	
	# Position at left edge, BOTTOM of enemy touches ground
	# Ground is at y=620, so enemy position should be at y=620
	position = Vector2(0,580)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/LevelTwo/gameOver.tscn")
