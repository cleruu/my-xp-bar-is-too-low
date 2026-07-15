extends Node2D
signal theftSucceeded
signal theftFailed(reason: String)

const fillSpeed = 20.0
const drainSpeed = 4.0

## Total time (in seconds) the player has to complete the theft.
@export var timeLimit: float = 20.0

## looking before it counts as getting caught. Gives a small buffer for
## accidental taps.
@export var catchDelay: float = 0.35

## Path to the WitnessNPC node. Set this in the editor once the NPC node exists.
@export var witnessPath: NodePath

## Scene to load immediately when the theft succeeds.
@export_file("*.tscn") var victoryLevelOnePath: String

## Scene to load immediately when the theft fails (caught or time up).
@export_file("*.tscn") var gameOverLevelOnePath: String

# For pausing the game
@export var PauseMenu: PackedScene

var isOnBar = false
var witnessIsLooking = false
var pressedWhileLookingTime = 0.0

var timeRemaining: float
var gameOver = false

@onready var witness: Node = get_node_or_null(witnessPath)


func _ready() -> void:
	timeRemaining = timeLimit
	%LookingLabel.visible = false
	$CharacterAnimation.play("Idle")

	if witness:
		witness.lookStarted.connect(_onWitnessLookStarted)
		witness.lookEnded.connect(_onWitnessLookEnded)
	else:
		push_warning("FishingSystem: witnessPath not set, catch logic disabled.")


func _on_area_2d_body_entered(body: Node2D) -> void:
	isOnBar = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	isOnBar = false


func _onWitnessLookStarted() -> void:
	witnessIsLooking = true
	%LookingLabel.visible = true


func _onWitnessLookEnded() -> void:
	witnessIsLooking = false
	%LookingLabel.visible = false


func _process(delta: float) -> void:
	if gameOver:
		return
	
	if Input.is_action_just_pressed("Esc"):
		pauseGame()
	
	_handleMeter(delta)
	_handleTimer(delta)
	_handleCatchCheck(delta)
	_handleAnimation()


func _handleMeter(delta: float) -> void:
	if isOnBar:
		%TextureProgressBar.value += fillSpeed * delta
	else:
		%TextureProgressBar.value -= drainSpeed * delta

	%TextureProgressBar.value = clamp(%TextureProgressBar.value, 0, 100)

	if %TextureProgressBar.value >= 100:
		_succeed()


func _handleTimer(delta: float) -> void:
	timeRemaining -= delta
	if timeRemaining <= 0:
		timeRemaining = 0
		_fail("time_up")


func _handleCatchCheck(delta: float) -> void:
	var isPressing = Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if witnessIsLooking:
		if isPressing:
			pressedWhileLookingTime += delta
			if pressedWhileLookingTime >= catchDelay:
				_fail("caught")
	else:
		pressedWhileLookingTime = 0.0


## Handles swapping the character sprite animation based on whether the
## player is currently pressing the grab input, independent of the
## witness/catch logic above.
func _handleAnimation() -> void:
	var isPressing = Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if isPressing:
		if $CharacterAnimation.animation != "PlayerGoingToGrab":
			$CharacterAnimation.play("PlayerGoingToGrab")
	else:
		if $CharacterAnimation.animation != "Idle":
			$CharacterAnimation.play("Idle")


func _goToVictory() -> void:
	if victoryLevelOnePath.is_empty():
		push_warning("FishingSystem: victoryLevelOnePath not set, cannot change scene.")
		return
	get_tree().change_scene_to_file(victoryLevelOnePath)


func _succeed() -> void:
	if gameOver:
		return
	gameOver = true
	if witness:
		witness.stopWatching()
	print("SUCCESS: The theft was successful!")
	$CharacterAnimation.play("PlayerGrabbing")
	theftSucceeded.emit()

	_goToVictory()


func _fail(reason: String) -> void:
	if gameOver:
		return
	gameOver = true
	if witness:
		witness.stopWatching()

	if reason == "caught":
		print("FAILED: You got caught by the witness!")
	elif reason == "time_up":
		print("FAILED: Ran out of time!")
	else:
		print("FAILED: ", reason)

	theftFailed.emit(reason)

	if gameOverLevelOnePath.is_empty():
		push_warning("FishingSystem: gameOverLevelOnePath not set, cannot change scene.")
		return
	get_tree().change_scene_to_file(gameOverLevelOnePath)

# Helper functions for pausing the game
func pauseGame() -> void:
	var pause = PauseMenu.instantiate()
	pause.retry.connect(resetGame)
	get_node("%CanvasLayer").add_child(pause)

func resetGame() -> void:
	get_tree().reload_current_scene()
