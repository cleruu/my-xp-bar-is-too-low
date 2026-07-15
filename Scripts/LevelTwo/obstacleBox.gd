extends StaticBody2D

@export var moveSpeed: float = 260.0

# Ground obstacle settings (arrays, one per texture)
@export var ground_textures: Array[Texture2D] = []
@export var ground_target_widths: Array[float] = []  # One per texture
@export var ground_target_heights: Array[float] = []  # One per texture
@export var ground_y_offsets: Array[float] = []  # One per texture
@export var ground_hitbox_widths: Array[float] = []  # One per texture
@export var ground_hitbox_heights: Array[float] = []  # One per texture

# Air obstacle settings (single)
@export var air_texture: Texture2D = null
@export var air_target_width: float = 192.0
@export var air_target_height: float = 200.0
@export var air_y_offset: float = -50.0
@export var air_hitbox_width: float = 150.0
@export var air_hitbox_height: float = 180.0

@onready var sprite: Sprite2D = $Sprite2D

var is_air_obstacle: bool = false
var hitbox: Area2D = null

func _ready():
	_create_hitbox()
	_apply_texture_and_hitbox()

func _create_hitbox():
	hitbox = Area2D.new()
	hitbox.name = "Hitbox"
	
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	shape.shape = rect_shape
	
	hitbox.add_child(shape)
	add_child(hitbox)
	
	hitbox.collision_layer = 2
	hitbox.collision_mask = 1
	hitbox.body_entered.connect(_on_body_entered)

func _apply_texture_and_hitbox():
	if not sprite:
		return
	
	var chosen_texture: Texture2D = null
	var target_size: Vector2
	var hitbox_size: Vector2
	var y_offset: float = 0.0
	var index: int = 0
	
	if is_air_obstacle and air_texture:
		# AIR OBSTACLE
		chosen_texture = air_texture
		target_size = Vector2(air_target_width, air_target_height)
		hitbox_size = Vector2(air_hitbox_width, air_hitbox_height)
		y_offset = air_y_offset
		print("Air obstacle! Hitbox: ", hitbox_size)
		
	elif ground_textures.size() > 0:
		# GROUND OBSTACLE - pick random
		index = randi() % ground_textures.size()
		chosen_texture = ground_textures[index]
		
		# Use individual settings for this texture
		var tw = ground_target_widths[index] if index < ground_target_widths.size() else 192.0
		var th = ground_target_heights[index] if index < ground_target_heights.size() else 264.0
		var hw = ground_hitbox_widths[index] if index < ground_hitbox_widths.size() else 192.0
		var hh = ground_hitbox_heights[index] if index < ground_hitbox_heights.size() else 264.0
		var yo = ground_y_offsets[index] if index < ground_y_offsets.size() else 0.0
		
		target_size = Vector2(tw, th)
		hitbox_size = Vector2(hw, hh)
		y_offset = yo
		print("Ground obstacle #", index, "! Hitbox: ", hitbox_size)
	
	if chosen_texture and hitbox:
		# Apply texture
		sprite.texture = chosen_texture
		sprite.scale = Vector2(
			target_size.x / chosen_texture.get_size().x,
			target_size.y / chosen_texture.get_size().y
		)
		sprite.centered = true
		sprite.position = Vector2(
			0, 
			-hitbox_size.y * 0.5 + (hitbox_size.y - target_size.y) * 0.5 + y_offset
		)
		
		# Apply hitbox
		var shape = hitbox.get_child(0) as CollisionShape2D
		if shape and shape.shape is RectangleShape2D:
			shape.shape.size = hitbox_size
			shape.position = Vector2(0, -hitbox_size.y * 0.5)

func set_air_obstacle(is_air: bool):
	is_air_obstacle = is_air
	_apply_texture_and_hitbox()

func _physics_process(delta: float) -> void:
	position.x -= moveSpeed * delta
	if position.x < -200:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var controller = get_tree().current_scene
		if controller and controller.has_method("deduct_score"):
			controller.deduct_score(5000)
		queue_free()
