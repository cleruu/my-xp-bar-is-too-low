extends CharacterBody2D

@export var movement_speed : float = 500

var character_direction : Vector2

func _physics_process(delta):
	character_direction.x = Input.get_axis("moveLeft", "moveRight")
	character_direction.y = Input.get_axis("moveUp", "moveDown")
	
	#flip
	if character_direction.x > 0: %charaSprite.flip_h = false
		
	if character_direction:
		velocity = character_direction * movement_speed
		if %charaSprite.animation != "walk_r": %charaSprite.animation = "walk_r"
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		if %charaSprite.animation != "idle": %charaSprite.animation = "idle"
	
	move_and_slide()
