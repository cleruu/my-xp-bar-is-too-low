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

# Dodge challenge settings
@export var dodge_target: int = 10
@export var challenge_time_limit: float = 45.0

# Enemy throw settings
@export var enemyThrowInterval: float = 5.0
@export var enemyThrowSpeed: float = 250.0
@export var enemyThrowCurve: float = 1.5

@onready var spawnTimer: Timer = $SpawnTimer
@onready var obstaclesRoot: Node2D = $Obstacles
@onready var enemy: Area2D = $Enemy
@onready var value_bar: ColorRect = $ValueBarBackground/ValueBar
@onready var dodge_counter: Label = $DodgeCounter
@onready var timer_label: Label = $TimerLabel  # CHANGED to TimerLabel

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var throw_timer: Timer = null
var thrown_obstacle_scene: PackedScene = null

# Dodge variables
var dodge_count: int = 0
var game_active: bool = true
var game_won: bool = false
var challenge_timer: Timer = null
var time_remaining: float = 60.0

# Track which obstacles have been counted
var counted_obstacles: Array = []
#damage popups
var damage_popup_scene: PackedScene = null

# For pausing the game
@export var PauseMenu: PackedScene

func _ready() -> void:
	add_to_group("level_controller")
	rng.randomize()
	
	if obstacleScene == null:
		obstacleScene = load("res://Scenes/LevelTwo/obstacleBox.tscn") as PackedScene

	if obstacleScene == null:
		push_error("obstacleScene is null. Check path or assign in Inspector.")
		return

	if value_bar and value_bar.has_signal("game_over"):
		value_bar.game_over.connect(_on_game_over)

	# Load thrown obstacle scene
	thrown_obstacle_scene = load("res://Scenes/LevelTwo/thrownObstacle.tscn")
	if thrown_obstacle_scene == null:
		push_error("thrownObstacle.tscn not found!")
	
	damage_popup_scene = load("res://Scenes/LevelTwo/damagePopup.tscn")
	if damage_popup_scene == null:
		push_error("damagePopup.tscn not found!")
		
	# Initialize displays
	time_remaining = challenge_time_limit
	_update_timer_display()
	_update_dodge_display()

	spawnTimer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()
	
	_setup_enemy_throwing()
	_setup_challenge_timer()
	


func _process(delta: float) -> void:
	if not game_active:
		return
	
	if Input.is_action_just_pressed("Esc"):
		pauseGame()
	
	# Update timer
	time_remaining -= delta
	_update_timer_display()
	
	# Check if time ran out - VICTORY!
	if time_remaining <= 0:
		time_remaining = 0
		_update_timer_display()
		_win_challenge()  # WIN, not game over!
		return
	
	# Check obstacles that passed the enemy
	_check_dodged_obstacles()

func _update_timer_display():
	if timer_label:
		var seconds = ceil(time_remaining)
		timer_label.text = "⏱️ " + str(seconds)
		
		# Change color based on time
		if seconds > 30:
			timer_label.modulate = Color(0, 1, 0)  # Green
		elif seconds > 15:
			timer_label.modulate = Color(1, 1, 0)  # Yellow
		else:
			timer_label.modulate = Color(1, 0, 0)  # Red

func _check_dodged_obstacles():
	if not enemy:
		return
	
	var enemy_x = enemy.global_position.x
	
	# Check all obstacles in obstaclesRoot
	for child in obstaclesRoot.get_children():
		# Skip if already counted
		if child in counted_obstacles:
			continue
		
		# Check if obstacle passed the enemy (obstacle x < enemy x)
		if child.position.x < enemy_x:
			counted_obstacles.append(child)
			increment_dodge()

func _setup_challenge_timer():
	challenge_timer = Timer.new()
	challenge_timer.wait_time = challenge_time_limit
	challenge_timer.one_shot = true
	challenge_timer.timeout.connect(_on_challenge_timeout)
	add_child(challenge_timer)
	challenge_timer.start()

func _on_challenge_timeout():
	if not game_active:
		return
	_on_game_over()

func _setup_enemy_throwing():
	if not enemy:
		return
	
	throw_timer = Timer.new()
	throw_timer.wait_time = 5.0
	throw_timer.one_shot = false
	throw_timer.timeout.connect(_enemy_throw_obstacle)
	add_child(throw_timer)
	throw_timer.start()

func _enemy_throw_obstacle():
	if not enemy or not thrown_obstacle_scene or not game_active:
		return
	
	var obstacle = thrown_obstacle_scene.instantiate()
	if not obstacle:
		return
	
	obstacle.add_to_group("thrown_obstacle")
	
	var start_pos = enemy.global_position + Vector2(50, -50)
	obstacle.position = start_pos
	
	if obstacle.has_method("set_throw_speed"):
		obstacle.set_throw_speed(enemyThrowSpeed, enemyThrowCurve)
	
	get_parent().add_child(obstacle)

func _update_dodge_display():
	if dodge_counter:
		dodge_counter.text = "⚡ " + str(dodge_count) + " / " + str(dodge_target)
		
		if dodge_count >= dodge_target:
			dodge_counter.modulate = Color(1, 0.8, 0)  # Gold
		elif dodge_count >= dodge_target * 0.7:
			dodge_counter.modulate = Color(0, 1, 0)  # Green
		elif dodge_count >= dodge_target * 0.4:
			dodge_counter.modulate = Color(1, 1, 0)  # Yellow
		else:
			dodge_counter.modulate = Color(1, 1, 1)  # White

func increment_dodge():
	if not game_active:
		return
	
	dodge_count += 1
	_update_dodge_display()
	
	if dodge_count >= dodge_target:
		_win_challenge()

func reset_dodge():
	if not game_active:
		return
	
	dodge_count = 0
	counted_obstacles.clear()
	_update_dodge_display()

func _win_challenge():
	if game_won:
		return
	
	game_won = true
	game_active = false
	
	spawnTimer.stop()
	if throw_timer:
		throw_timer.stop()
	if challenge_timer:
		challenge_timer.stop()
	
	
	var thrown_obstacles = get_tree().get_nodes_in_group("thrown_obstacle")
	for obstacle in thrown_obstacles:
		obstacle.queue_free()
	
	call_deferred("_change_to_victory")

func _change_to_victory():
	get_tree().change_scene_to_file("res://Scenes/LevelTwo/victory.tscn")

func _on_spawn_timer_timeout() -> void:
	if not game_active or obstacleScene == null:
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
	if value_bar.has_method("deduct_score"):
		value_bar.deduct_score(amount)
	else:
		print("❌ value_bar does NOT have deduct_score method!")
		
func get_current_score() -> int:
	if value_bar and value_bar.has_method("get_value"):
		return value_bar.get_value()
	return 50000

func show_damage_popup(position: Vector2, amount: int = 5000):
	if not damage_popup_scene:
		return
	
	var popup = damage_popup_scene.instantiate()
	if not popup:
		return
	
	popup.position = position
	add_child(popup)

func _on_game_over():
	if not game_active:
		return
	
	game_active = false
	
	var thrown_obstacles = get_tree().get_nodes_in_group("thrown_obstacle")
	for obstacle in thrown_obstacles:
		obstacle.queue_free()
	
	call_deferred("_change_to_game_over")

func _change_to_game_over():
	get_tree().change_scene_to_file("res://Scenes/LevelTwo/gameOver.tscn")

# Helper functions for pausing the game
func pauseGame() -> void:
	var pause = PauseMenu.instantiate()
	pause.retry.connect(resetGame)
	get_node("%CanvasLayer").add_child(pause)

func resetGame() -> void:
	get_tree().reload_current_scene()
