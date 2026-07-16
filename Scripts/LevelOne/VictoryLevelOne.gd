extends Node2D

@export_file("*.tscn") var goToLevelTwo: String

@onready var victorySound: AudioStreamPlayer = $VictorySound

func _ready() -> void:
	victorySound.play()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file(goToLevelTwo)
