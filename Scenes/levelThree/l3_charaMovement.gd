extends CharacterBody2D

@export var movement_speed : float = 500
var character_direction : Vector2
var last_flip_h : bool = false

@onready var footstep_sfx: AudioStreamPlayer = $FootstepSFX

func _ready() -> void:
	footstep_sfx.stream = preload("res://Assets/Sounds/sfx/Walking Sound Effects.wav")
	footstep_sfx.volume_db = 12.0
	footstep_sfx.bus = "Master"
	if footstep_sfx.stream:
		var s = footstep_sfx.stream as AudioStreamWAV
		print("ROBS_DEBUG: class=", footstep_sfx.stream.get_class(), " format=", s.format, " rate=", s.mix_rate, " stereo=", s.stereo)
		print("ROBS_DEBUG: data_size=", s.data.size())
	else:
		print("ROBS_DEBUG: stream is null!")

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
			print("ROBS_DEBUG: play() called")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		if %charaSprite.animation != "idle": %charaSprite.animation = "idle"
		if footstep_sfx.playing:
			footstep_sfx.stop()

	move_and_slide()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass
