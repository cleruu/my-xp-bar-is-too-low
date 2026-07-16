extends Node2D
## Witness NPC logic.
## Randomly alternates between "not looking" and "looking" at the player,
## using two Timer child nodes to control the randomized timing, and drives
## the Lola AnimatedSprite2D through the eye-open/eye-close animations.

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
@onready var sprite: AnimatedSprite2D = $Lola

const ANIM_IDLE = "LolaIdle"
const ANIM_OPENING = "LolaOpeningEyes"
const ANIM_OPEN = "LolaOpenEyes"
const ANIM_CLOSING = "LolaClosingEyes"


func _ready() -> void:
	randomize()

	lookAwayTimer.timeout.connect(_onLookAwayTimerTimeout)
	lookDurationTimer.timeout.connect(_onLookDurationTimerTimeout)
	sprite.animation_finished.connect(_onAnimationFinished)

	sprite.play(ANIM_IDLE)
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
	sprite.play(ANIM_OPENING)

	lookDurationTimer.wait_time = randf_range(minLookDuration, maxLookDuration)
	lookDurationTimer.start()


## Called automatically when LookDurationTimer finishes. Look is over.
func _onLookDurationTimerTimeout() -> void:
	if not isActive:
		return

	isLooking = false
	lookEnded.emit()
	sprite.play(ANIM_CLOSING)

	_startLookAwayTimer()


## Hands off from the one-shot transition animations into the correct loop.
func _onAnimationFinished() -> void:
	match sprite.animation:
		ANIM_OPENING:
			sprite.play(ANIM_OPEN)
		ANIM_CLOSING:
			sprite.play(ANIM_IDLE)


## Call this to freeze the NPC (e.g. when the heist ends, win or lose).
func stopWatching() -> void:
	isActive = false
	lookAwayTimer.stop()
	lookDurationTimer.stop()
	if isLooking:
		isLooking = false
		lookEnded.emit()
	sprite.play(ANIM_CLOSING)
