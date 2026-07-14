extends Node2D

func _ready() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	print("LevelThree found ", guards.size(), " guards in group")
	for guard in guards:
		guard.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	print("LevelThree: received player_caught signal, reloading")
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("RELOAD FAILED with error code: ", error)
