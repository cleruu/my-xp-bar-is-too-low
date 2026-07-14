extends Control

func _ready() -> void:
	get_tree().paused = true

func ContinueGame() -> void:
	get_tree().paused = false
	queue_free()
	print("Killing myself")
