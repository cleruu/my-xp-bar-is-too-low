extends Node2D

func _ready():
	pass
	

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LevelOne/LevelOne.tscn")


func _on_button_2_pressed() -> void:
	get_tree().quit()
