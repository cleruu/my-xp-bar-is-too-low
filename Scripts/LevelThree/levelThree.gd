extends Node2D

func _ready() -> void:
	var guards = get_tree().get_nodes_in_group("guards")
	print("LevelThree found ", guards.size(), " guards in group")
	for guard in guards:
		guard.player_caught.connect(_on_player_caught)

	var goal = get_tree().get_first_node_in_group("goal")
	if goal:
		goal.player_reached_goal.connect(_on_player_reached_goal)
	else:
		print("LevelThree: no goal zone found in 'goal' group!")

func _on_player_caught() -> void:
	print("LevelThree: received player_caught signal, reloading")
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("RELOAD FAILED with error code: ", error)

func _on_player_reached_goal() -> void:
	print("LevelThree: player reached the goal! YOU WIN")
