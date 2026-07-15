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

var isOnBar = false
var witnessIsLooking = false
var pressedWhileLookingTime = 0.0

var timeRemaining: float
var gameOver = false

@onready var witness: Node = get_node_or_null(witnessPath)


func _ready() -> void:
	timeRemaining = timeLimit
	%LookingLabel.visible = false

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

	_handleMeter(delta)
	_handleTimer(delta)
	_handleCatchCheck(delta)


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


func _succeed() -> void:
	if gameOver:
		return
	gameOver = true
	if witness:
		witness.stopWatching()
	print("SUCCESS: The theft was successful!")
	theftSucceeded.emit()
	
	get_tree().quit()


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

	get_tree().quit()
