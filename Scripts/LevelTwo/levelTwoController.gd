extends Node2D

@export var obstacleScene: PackedScene
@export var spawnX: float = 1500.0
@export var groundY: float = 620.0
@export var obstacleHalfHeight: float = 45.0
@export var minSpawnDistance: float = 420.0
@export var maxSpawnDistance: float = 700.0
@export var airObstacleChance: float = 0.35
@export var airObstacleYOffset: float = 210.0
@export var obstacleSpeed: float = 260.0

@onready var spawnTimer: Timer = $SpawnTimer
@onready var obstaclesRoot: Node2D = $Obstacles

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

	if obstacleScene == null:
		obstacleScene = load("res://Scenes/LevelTwo/obstacleBox.tscn") as PackedScene

	if obstacleScene == null:
		push_error("obstacleScene is null. Check path or assign in Inspector.")
		return

	spawnTimer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()

func _on_spawn_timer_timeout() -> void:
	if obstacleScene == null:
		return

	var obs: StaticBody2D = obstacleScene.instantiate() as StaticBody2D
	if obs == null:
		push_error("Failed to instantiate obstacleScene")
		return

	var shouldSpawnAir: bool = rng.randf() < airObstacleChance

	var spawnY: float = groundY - obstacleHalfHeight
	if shouldSpawnAir:
		spawnY -= airObstacleYOffset

	obs.position = Vector2(spawnX, spawnY)
	obs.set("moveSpeed", obstacleSpeed)
	obstaclesRoot.add_child(obs)
	_reset_timer()

func _reset_timer() -> void:
	var minGap: float = minSpawnDistance
	var maxGap: float = maxSpawnDistance
	if maxGap < minGap:
		maxGap = minGap

	var gapDistance: float = rng.randf_range(minGap, maxGap)
	spawnTimer.wait_time = gapDistance / maxf(obstacleSpeed, 1.0)
	spawnTimer.start()
