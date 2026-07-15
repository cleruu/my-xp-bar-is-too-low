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

# Enemy throw settings
@export var enemyThrowInterval: float = 5.0
@export var enemyThrowSpeed: float = 250.0
@export var enemyThrowCurve: float = 1.5

@onready var spawnTimer: Timer = $SpawnTimer
@onready var obstaclesRoot: Node2D = $Obstacles
@onready var enemy: Area2D = $Enemy
@onready var scoreLabel: Label = $ScoreLabel 

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var throw_timer: Timer = null
var thrown_obstacle_scene: PackedScene = null

func _ready() -> void:
	add_to_group("level_controller")
	rng.randomize()

	if obstacleScene == null:
		obstacleScene = load("res://Scenes/LevelTwo/obstacleBox.tscn") as PackedScene

	if obstacleScene == null:
		push_error("obstacleScene is null. Check path or assign in Inspector.")
		return

	if scoreLabel and scoreLabel.has_signal("game_over"):
		scoreLabel.game_over.connect(_on_game_over)

	# Load thrown obstacle scene
	thrown_obstacle_scene = load("res://Scenes/LevelTwo/thrownObstacle.tscn")
	if thrown_obstacle_scene == null:
		push_error("thrownObstacle.tscn not found!")

	spawnTimer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()
	
	_setup_enemy_throwing()

func _setup_enemy_throwing():
	if not enemy:
		return
	
	throw_timer = Timer.new()
	throw_timer.wait_time = 5.0
	throw_timer.one_shot = false
	throw_timer.timeout.connect(_enemy_throw_obstacle)
	add_child(throw_timer)
	throw_timer.start()
	
	print("Enemy throwing every 5 seconds!")

func _enemy_throw_obstacle():
	if not enemy or not thrown_obstacle_scene:
		return
	
	var obstacle = thrown_obstacle_scene.instantiate()
	if not obstacle:
		return
	
	# Add to group for cleanup
	obstacle.add_to_group("thrown_obstacle")
	
	var start_pos = enemy.global_position + Vector2(50, -50)
	obstacle.position = start_pos
	
	if obstacle.has_method("set_throw_speed"):
		obstacle.set_throw_speed(enemyThrowSpeed, enemyThrowCurve)
	
	get_parent().add_child(obstacle)
	print("Enemy threw a slipper!")

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
		if obs.has_method("set_air_obstacle"):
			obs.set_air_obstacle(true)

	obs.position = Vector2(spawnX, spawnY)
	obs.set("moveSpeed", obstacleSpeed)
	obstaclesRoot.add_child(obs)
	_reset_timer()

func _reset_timer() -> void:
	var minGap: float = minSpawnDistance * 1.5
	var maxGap: float = maxSpawnDistance * 1.5
	if maxGap < minGap:
		maxGap = minGap

	var gapDistance: float = rng.randf_range(minGap, maxGap)
	spawnTimer.wait_time = gapDistance / maxf(obstacleSpeed, 1.0)
	spawnTimer.start()
	
func deduct_score(amount: int = 5000):
	if scoreLabel and scoreLabel.has_method("deduct_score"):
		scoreLabel.deduct_score(amount)

func _on_game_over():
	# CLEAN UP: Remove all thrown obstacles before game over
	var thrown_obstacles = get_tree().get_nodes_in_group("thrown_obstacle")
	for obstacle in thrown_obstacles:
		obstacle.queue_free()
	print("Cleared ", thrown_obstacles.size(), " thrown obstacles")
	
	call_deferred("_change_to_game_over")

func _change_to_game_over():
	get_tree().change_scene_to_file("res://Scenes/LevelTwo/gameOver.tscn")
