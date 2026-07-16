extends Node2D

@export_file("*.tscn") var level3: String

var atEnd := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Input.is_action_just_pressed("Next"):
		if atEnd:
			get_tree().change_scene_to_file(level3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func isAtEnd() -> void:
	atEnd = true
