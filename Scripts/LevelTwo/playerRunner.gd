extends CharacterBody2D

@export var speed: float = 220.0
@export var jumpForce: float = -540.0
@export var gravity: float = 1000.0
@export var crouchSpeedMultiplier: float = 0.45

@export var standSize: Vector2 = Vector2(192, 264)
@export var crouchSize: Vector2 = Vector2(192, 156)

@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var collisionRect: RectangleShape2D = collisionShape.shape as RectangleShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var isCrouching: bool = false
var was_in_air: bool = false  # Track if we were just in air

func _ready() -> void:
	_apply_stand_shape()
	add_to_group("player")
	
	# Start with run animation
	if animated_sprite:
		animated_sprite.play("run")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Crouch intent - ONLY allow on ground
	if Input.is_action_pressed("moveDown") and is_on_floor():
		_enter_crouch()
	else:
		_try_exit_crouch()

	# Horizontal
	var dir := Input.get_axis("moveLeft", "moveRight")
	var currentSpeed := speed * (crouchSpeedMultiplier if isCrouching else 1.0)
	velocity.x = dir * currentSpeed

	# Jump
	if Input.is_action_just_pressed("moveUp") and is_on_floor() and not isCrouching:
		velocity.y = jumpForce

	move_and_slide()
	
	# Update animation
	_update_animation()

func _update_animation() -> void:
	if not animated_sprite:
		return
	
	# IN THE AIR - Play jump animation
	if not is_on_floor():
		# Play jump animation (2 frames)
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
			animated_sprite.frame = 0  # Start from first frame
		was_in_air = true
		return
	
	# LANDING - Transition back to ground animation
	if was_in_air and is_on_floor():
		was_in_air = false
		# Immediately play run or idle
		if abs(velocity.x) > 10:
			animated_sprite.play("run")
		else:
			animated_sprite.play("run")  # Keep run animation (no idle)
			animated_sprite.pause()
			animated_sprite.frame = 0
	
	# On ground - check if crouching
	if isCrouching:
		if animated_sprite.animation != "duck":
			animated_sprite.play("duck")
		if not animated_sprite.is_playing():
			animated_sprite.play()
		return
	
	# On ground - running
	if animated_sprite.animation != "run":
		animated_sprite.play("run")
	
	# Make sure it's playing
	if not animated_sprite.is_playing():
		animated_sprite.play()
	
	# Flip sprite based on direction
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

func _enter_crouch() -> void:
	if isCrouching:
		return
	isCrouching = true
	_apply_crouch_shape()

func _try_exit_crouch() -> void:
	if not isCrouching:
		return

	# Check space above head before standing
	var spaceNeeded := standSize.y - crouchSize.y
	if spaceNeeded <= 0.0:
		isCrouching = false
		_apply_stand_shape()
		return

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = RectangleShape2D.new()
	(params.shape as RectangleShape2D).size = Vector2(standSize.x, spaceNeeded)

	# area to check just above crouched top
	params.transform = Transform2D(
		0.0,
		global_position + Vector2(0, -(crouchSize.y * 0.5) - (spaceNeeded * 0.5))
	)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [self]

	var result := get_world_2d().direct_space_state.intersect_shape(params, 1)
	if result.is_empty():
		isCrouching = false
		_apply_stand_shape()
	# else: blocked above, stay crouched

func _apply_stand_shape() -> void:
	collisionRect.size = standSize  # (192, 264)
	collisionShape.position = Vector2(0, -standSize.y * 0.5)  # (0, -132)
	
	# AnimatedSprite stays at stand position (no resize)
	if animated_sprite:
		animated_sprite.position = Vector2(0, -standSize.y * 0.5)

func _apply_crouch_shape() -> void:
	# Only resize the hitbox (collision shape)
	collisionRect.size = crouchSize  # (192, 156)
	collisionShape.position = Vector2(0, -crouchSize.y * 0.5)  # (0, -78)
