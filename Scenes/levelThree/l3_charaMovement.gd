extends CharacterBody2D

@export var movement_speed : float = 500
var character_direction : Vector2
var last_flip_h : bool = false  # tracks the flip state from last horizontal movement

func _physics_process(delta):
	character_direction.x = Input.get_axis("moveLeft", "moveRight")
	character_direction.y = Input.get_axis("moveUp", "moveDown")

	# flip based on horizontal input, and remember it
	if character_direction.x > 0:
		last_flip_h = true
		%charaSprite.flip_h = true
	elif character_direction.x < 0:
		last_flip_h = false
		%charaSprite.flip_h = false
	elif character_direction.y != 0:
		# no horizontal input, but moving vertically:
		# face the OPPOSITE of the last horizontal direction used
		%charaSprite.flip_h = not last_flip_h

	if character_direction:
		velocity = character_direction * movement_speed
		if %charaSprite.animation != "walk_r": %charaSprite.animation = "walk_r"
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		if %charaSprite.animation != "idle": %charaSprite.animation = "idle"

	move_and_slide()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
