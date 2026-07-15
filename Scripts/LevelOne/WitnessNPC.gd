extends Node2D
## Witness NPC logic.
## Randomly alternates between "not looking" and "looking" at the player,
## using two Timer child nodes to control the randomized timing.

signal lookStarted
signal lookEnded

## How long (in seconds) the NPC looks away before glancing at the player.
@export var minLookAwayTime: float = 1.75
@export var maxLookAwayTime: float = 4.5

## How long (in seconds) the NPC's glance/look lasts once it starts.
@export var minLookDuration: float = 1.25
@export var maxLookDuration: float = 4.5

var isLooking: bool = false 
var isActive: bool = true

@onready var lookAwayTimer: Timer = $LookAwayTimer
@onready var lookDurationTimer: Timer = $LookDurationTimer


func _ready() -> void:
	randomize()

	# Connect the timers' timeout signals to our own functions.
	lookAwayTimer.timeout.connect(_onLookAwayTimerTimeout)
	lookDurationTimer.timeout.connect(_onLookDurationTimerTimeout)

	_startLookAwayTimer()


## Starts the "not looking" phase: picks a random wait time and starts the timer.
func _startLookAwayTimer() -> void:
	if not isActive:
		return

	lookAwayTimer.wait_time = randf_range(minLookAwayTime, maxLookAwayTime)
	lookAwayTimer.start()


## Called automatically when LookAwayTimer finishes. Time to start looking.
func _onLookAwayTimerTimeout() -> void:
	if not isActive:
		return

	isLooking = true
	lookStarted.emit()

	lookDurationTimer.wait_time = randf_range(minLookDuration, maxLookDuration)
	lookDurationTimer.start()


## Called automatically when LookDurationTimer finishes. Look is over.
func _onLookDurationTimerTimeout() -> void:
	if not isActive:
		return

	isLooking = false
	lookEnded.emit()

	_startLookAwayTimer()


## Call this to freeze the NPC (e.g. when the heist ends, win or lose).
func stopWatching() -> void:
	isActive = false
	lookAwayTimer.stop()
	lookDurationTimer.stop()
	if isLooking:
		isLooking = false
		lookEnded.emit()
