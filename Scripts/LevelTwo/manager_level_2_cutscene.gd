extends Node2D

@export_file("*.tscn") var Level3: String

var atEnd := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().get_child(3).get_child(0).get_child(5).text = str(50000 - GlobalManager.damage)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Next"):
		if atEnd:
			print("test")
			get_tree().change_scene_to_file(Level3)

func isAtEnd() -> void:
	atEnd = true

func playPanting() -> void:
	get_parent().get_child(4).get_node("%Panting").play()

func playLanding() -> void:
	get_parent().get_child(4).get_node("%Landing").play()
