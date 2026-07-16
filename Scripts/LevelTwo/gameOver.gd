extends Node2D

@export_file("*.tscn") var endCutscene: String

func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/LevelTwo/levelTwo.tscn")

func _on_quit_button_pressed():
	get_tree().change_scene_to_file(endCutscene)
