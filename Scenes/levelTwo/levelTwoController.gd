extends Node2D

@export var obstacleScene: PackedScene
@export var spawnX: float = 1500.0
@export var groundY: float = 620.0
@export var obstacleHalfHeight: float = 30.0
@export var minSpawnTime: float = 0.9
@export var maxSpawnTime: float = 1.6
@export var obstacleSpeed: float = 260.0

@onready var spawnTimer: Timer = $SpawnTimer
@onready var obstaclesRoot: Node2D = $Obstacles

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	if obstacleScene == null:
		obstacleScene = load("res://Scenes/levelTwo/obstacleBox.tscn") as PackedScene

	if obstacleScene == null:
		push_error("obstacleScene is null. Check path or assign in Inspector.")
		return

	spawnTimer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()

func _on_spawn_timer_timeout() -> void:
	if obstacleScene == null:
		return

	var obs := obstacleScene.instantiate() as StaticBody2D
	if obs == null:
		push_error("Failed to instantiate obstacleScene")
		return

	obs.position = Vector2(spawnX, groundY - obstacleHalfHeight)
	obs.set("moveSpeed", obstacleSpeed)
	obstaclesRoot.add_child(obs)
	_reset_timer()

func _reset_timer() -> void:
	spawnTimer.wait_time = rng.randf_range(minSpawnTime, maxSpawnTime)
	spawnTimer.start()
