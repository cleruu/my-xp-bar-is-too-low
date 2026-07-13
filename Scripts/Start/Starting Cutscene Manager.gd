extends Node2D

var isAtEnd := false
@export var PauseMenu: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Next"):
		if isAtEnd:
			goToLevel1()
		else:
			print("test")
			
	if Input.is_action_just_pressed("Esc"):
		if GlobalManager.isGamePaused == true:
			return
		pauseGame()

func goToLevel1() -> void:
	get_tree().change_scene_to_file("res://Scenes/levelTwo/levelTwo.tscn")

func canGoToL1() -> void:
	isAtEnd = true

func pauseGame() -> void:
	get_tree().paused = true
	GlobalManager.isGamePaused = true
	var pause = PauseMenu.instantiate()
	get_parent().get_child(4).add_child(pause)
	
