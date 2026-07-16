extends Area2D

@export var min_throw_speed: float = 200.0
@export var max_throw_speed: float = 400.0
@export var min_arc_height: float = 50.0
@export var max_arc_height: float = 200.0
@export var fall_speed: float = 300.0
@export var lifetime: float = 4.0
@export var hit_sound: AudioStream = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var throw_speed: float = 300.0
var arc_height: float = 100.0
var start_y: float = 0.0
var velocity_y: float = 0.0
var direction: int = 1
var rotation_speed: float = 0.0
var has_been_dodged: bool = false  # ADD THIS

func _ready():
	# Set collision
	collision_layer = 2
	collision_mask = 1
	
	# Add to group for cleanup
	add_to_group("thrown_obstacle")
	
	# Set visual to 100x100
	if sprite and sprite.texture:
		var size = sprite.texture.get_size()
		sprite.scale = Vector2(100.0 / size.x, 100.0 / size.y)
		sprite.centered = true
		sprite.position = Vector2(0, -50)
	
	# Set hitbox to 50x50 (centered)
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(50, 50)
		collision_shape.position = Vector2(0, -35)
	
	# RANDOMIZE
	throw_speed = randf_range(min_throw_speed, max_throw_speed)
	arc_height = randf_range(min_arc_height, max_arc_height)
	direction = 1 if randi() % 2 == 0 else -1
	
	rotation_speed = randf_range(-1.0, 1.0)
	
	# Initial velocity
	velocity_y = -arc_height * direction
	
	start_y = global_position.y
	
	# Connect signal
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	print("Rocket spawned! Visual: 100x100, Hitbox: 50x50")

func _physics_process(delta: float) -> void:
	# Move right
	position.x += throw_speed * delta
	
	# Apply fall speed
	velocity_y += fall_speed * delta * direction * 0.5
	position.y += velocity_y * delta
	
	# SLOW rotation
	if sprite:
		sprite.rotation += rotation_speed * delta
	
	# CHECK IF THROWN OBSTACLE WAS DODGED
	if not has_been_dodged:
		# Find air obstacle Y position
		var air_y = 9999
		var obstacles = get_tree().get_nodes_in_group("obstacle")
		for obs in obstacles:
			if obs.has_method("is_air_obstacle") and obs.is_air_obstacle:
				air_y = obs.global_position.y
				break
		
		# If thrown obstacle goes above air obstacle OR reaches top of screen (Y <= 0)
		if position.y <= air_y or position.y <= 0:
			has_been_dodged = true
			var controller = get_tree().current_scene
			if controller and controller.has_method("increment_dodge"):
				controller.increment_dodge()
				print("Thrown obstacle dodged! +1")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Play hit sound
		if audio_player and hit_sound:
			audio_player.stream = hit_sound
			audio_player.play()
		# Show damage popup at player position
		var controller = get_tree().current_scene
		if controller and controller.has_method("show_damage_popup"):
			controller.show_damage_popup(body.global_position + Vector2(0, -100), 5000)
		
		if controller and controller.has_method("reset_dodge"):
			controller.reset_dodge()
		
		if controller and controller.has_method("deduct_score"):
			controller.deduct_score(5000)
		
		queue_free()

func set_throw_speed(speed: float, curve: float):
	throw_speed = speed
	arc_height = curve
