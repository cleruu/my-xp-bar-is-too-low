extends Node2D

func _ready():
	pass

func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/LevelTwo/levelTwo.tscn")
