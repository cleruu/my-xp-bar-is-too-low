extends CharacterBody2D

@export var movement_speed : float = 500
var character_direction : Vector2
var last_flip_h : bool = false

var footstep_sfx: AudioStreamPlayer
var footstep_stream: AudioStreamWAV

func _ready() -> void:
	footstep_stream = preload("res://Assets/Sounds/sfx/Walking Sound Effects.wav")
	footstep_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	footstep_sfx = AudioStreamPlayer.new()
	footstep_sfx.stream = footstep_stream
	footstep_sfx.volume_db = 0.0
	footstep_sfx.bus = "Master"
	add_child(footstep_sfx)
	print("ROBS_DEBUG: footstep _ready done, node: ", footstep_sfx != null)

func _physics_process(delta):
	character_direction.x = Input.get_axis("moveLeft", "moveRight")
	character_direction.y = Input.get_axis("moveUp", "moveDown")

	if character_direction.x > 0:
		last_flip_h = true
		%charaSprite.flip_h = true
	elif character_direction.x < 0:
		last_flip_h = false
		%charaSprite.flip_h = false
	elif character_direction.y != 0:
		%charaSprite.flip_h = not last_flip_h

	if character_direction:
		velocity = character_direction * movement_speed
		if %charaSprite.animation != "walk_r": %charaSprite.animation = "walk_r"
		if not footstep_sfx.playing:
			footstep_sfx.play()
			print("ROBS_DEBUG: footstep play called")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		if %charaSprite.animation != "idle": %charaSprite.animation = "idle"
		if footstep_sfx.playing:
			footstep_sfx.stop()

	move_and_slide()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass
