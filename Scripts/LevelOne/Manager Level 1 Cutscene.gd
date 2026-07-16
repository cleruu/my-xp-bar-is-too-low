extends Node2D

var atEnd := false

@export_file("*.tscn") var level2: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blinkText()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Next"):
		if atEnd:
			get_tree().change_scene_to_file(level2)
		else:
			pass # Fast forward maybe?

# Blinking text template
func blinkText() -> void:
	atEnd = true

func paraPoPlay() -> void:
	get_parent().get_child(4).get_node("%Para po").play()
	
func nakawPlay() -> void:
	get_parent().get_child(4).get_node("%Magnanakaw").play()
	
func iphonePlay() -> void:
	get_parent().get_child(4).get_node("%Iphone").play()
	
