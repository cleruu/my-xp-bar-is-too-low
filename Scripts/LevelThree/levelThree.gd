extends Node2D

@onready var bgm: AudioStreamPlayer = $BGMPlayer

var bgm_nocatch := preload("res://Assets/Sounds/BGM/L3_Sneaky_NoCatch.wav")
var bgm_catch := preload("res://Assets/Sounds/BGM/L3_Sneaky_Catch.wav")

var guards_chasing: int = 0

# For pausing the game
@export var PauseMenu: PackedScene

func _ready() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	for guard in guards:
		guard.player_caught.connect(_on_player_caught)
		guard.player_spotted.connect(_on_player_spotted.bind(guard))
		guard.player_lost.connect(_on_player_lost.bind(guard))

	bgm.finished.connect(_on_bgm_finished)
	bgm.stream = bgm_nocatch
	bgm.bus = "Master"
	bgm.volume_db = -12.0
	bgm.play()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Esc"):
		pauseGame()

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

	var goal = get_tree().get_first_node_in_group("goal")
	if goal:
		goal.player_reached_goal.connect(_on_player_reached_goal)
	else:
		print("LevelThree: no goal zone found in 'goal' group!")

func _on_player_caught() -> void:
	bgm.stop()
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("RELOAD FAILED with error code: ", error)

func _on_player_reached_goal() -> void:
	print("LevelThree: player reached the goal! YOU WIN")

# Helper functions for pausing the game
func pauseGame() -> void:
	var pause = PauseMenu.instantiate()
	pause.retry.connect(resetGame)
	get_node("%CanvasLayer").add_child(pause)

func resetGame() -> void:
	get_tree().reload_current_scene()
