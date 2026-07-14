extends CharacterBody2D

@export var speed: float = 220.0
@export var jumpForce: float = -540.0
@export var gravity: float = 1000.0
@export var crouchSpeedMultiplier: float = 0.45

@export var standSize: Vector2 = Vector2(192, 264)
@export var crouchSize: Vector2 = Vector2(192, 156)

@onready var collisionShape: CollisionShape2D = $CollisionShape2D
@onready var collisionRect: RectangleShape2D = collisionShape.shape as RectangleShape2D
@onready var visualRect: ColorRect = $ColorRect

var isCrouching: bool = false

func _ready() -> void:
	_apply_stand_shape()
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Crouch intent
	if Input.is_action_pressed("moveDown"):
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
	collisionRect.size = standSize
	collisionShape.position = Vector2(0, -standSize.y * 0.5)
	visualRect.size = standSize
	visualRect.position = Vector2(-standSize.x * 0.5, -standSize.y)

func _apply_crouch_shape() -> void:
	collisionRect.size = crouchSize
	collisionShape.position = Vector2(0, -crouchSize.y * 0.5)
	visualRect.size = crouchSize
	visualRect.position = Vector2(-crouchSize.x * 0.5, -crouchSize.y)
