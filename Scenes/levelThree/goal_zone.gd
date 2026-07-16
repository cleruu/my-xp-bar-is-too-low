extends Area2D

signal player_reached_goal

@export_file("*.tscn") var endCutscene: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player reached the goal!")
		get_tree().change_scene_to_file(endCutscene)
		player_reached_goal.emit()
