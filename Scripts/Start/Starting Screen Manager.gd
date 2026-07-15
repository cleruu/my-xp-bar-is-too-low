extends Node2D

@export_file("*.tscn") var startingCutscene: String
@export_file("*.tscn") var arcadeScene: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func goToStartingCutscene() -> void:
	get_tree().change_scene_to_file(startingCutscene)

func goToArcade() -> void:
	get_tree().change_scene_to_file(arcadeScene)
	
