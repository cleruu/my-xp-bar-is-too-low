extends Control

signal retry

func _ready() -> void:
	get_tree().paused = true

func ContinueGame() -> void:
	get_tree().paused = false
	queue_free()
	print("Killing myself")
	
func retryGame() -> void:
	get_tree().paused = false
	print("Retrying the Area")
	retry.emit()
