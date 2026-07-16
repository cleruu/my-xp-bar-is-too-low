extends CanvasLayer

func _ready():
	# Make sure UI processes even when game is paused
	process_mode = PROCESS_MODE_ALWAYS

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Start/Starting Screen.tscn")
