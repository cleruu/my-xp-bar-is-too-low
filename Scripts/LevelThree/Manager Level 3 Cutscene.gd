extends Node2D

@export_file("*.tscn") var endCutscene: String

var atEnd := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Input.is_action_just_pressed("Next"):
		if atEnd:
			get_tree().change_scene_to_file(endCutscene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func isAtEnd() -> void:
	atEnd = true

func playGremlin() -> void:
	get_parent().get_child(4).get_node("%Gremlin").play()
	
func playOpen() -> void:
	get_parent().get_child(4).get_node("%Open").play()
