extends Node2D

@onready var bgm: AudioStreamPlayer = $BGMPlayer

var bgm_nocatch := preload("res://Assets/Sounds/BGM/L3_Sneaky_NoCatch.wav")
var bgm_catch := preload("res://Assets/Sounds/BGM/L3_Sneaky_Catch.wav")

var guards_chasing: int = 0

func _ready() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	for guard in guards:
		guard.player_caught.connect(_on_player_caught)
		guard.player_spotted.connect(_on_player_spotted.bind(guard))
		guard.player_lost.connect(_on_player_lost.bind(guard))

	bgm.finished.connect(_on_bgm_finished)
	bgm.stream = bgm_nocatch
	bgm.bus = "Master"
	bgm.play()

func _on_bgm_finished() -> void:
	bgm.play()

func _on_player_spotted(_guard: Node) -> void:
	guards_chasing += 1
	if guards_chasing == 1:
		bgm.stream = bgm_catch
		bgm.play()

func _on_player_lost(_guard: Node) -> void:
	guards_chasing -= 1
	if guards_chasing <= 0:
		guards_chasing = 0
		bgm.stream = bgm_nocatch
		bgm.play()

func _on_player_caught() -> void:
	bgm.stop()
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("RELOAD FAILED with error code: ", error)
