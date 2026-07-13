extends Control

func ContinueGame() -> void:
	GlobalManager.isGamePaused = false
	get_tree().paused = false
	queue_free()
	print("Killing myself")
