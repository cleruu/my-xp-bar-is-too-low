extends Node2D

@export_file("*.tscn") var level1: String
@export_file("*.tscn") var level2: String
@export_file("*.tscn") var level3: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func goToLevel1() -> void:
	get_tree().change_scene_to_file(level1)
	
func goToLevel2() -> void:
	get_tree().change_scene_to_file(level2)
	
func goToLevel3() -> void:
	get_tree().change_scene_to_file(level3)
