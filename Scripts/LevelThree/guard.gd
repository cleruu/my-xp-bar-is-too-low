extends CharacterBody2D

# --- Patrol ---
@export var patrol_speed: float = 100.0
@export var chase_speed: float = 160.0
const ARRIVAL_THRESHOLD := 5.0

@onready var patrol_points_node: Node2D = $patrolPoints
@onready var vision_ray: RayCast2D = $visionRay
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var patrol_points: Array[Vector2] = []
var current_point_index: int = 0
var facing_direction: Vector2 = Vector2.DOWN
signal player_caught 
var is_detecting: bool = false


signal player_spotted

# --- Escape / Aggro loss ---
@export var chase_lose_time: float = 2.0
var lost_sight_timer: float = 0.0

# --- Catch / Game Over ---
@export var catch_distance: float = 30.0
@export var catch_time: float = 1.0
var catch_timer: float = 0.0


# --- Vision ---
@export var vision_range: float = 250.0
@export var vision_angle_degrees: float = 45.0  # half-angle either side of facing direction
@export var time_to_detect: float = 3.0
@export var patrol_wait_time: float = 1.5   # seconds to pause at each point
@onready var debug_label: Label = $Label

var is_waiting: bool = false
var wait_timer: float = 0.0
var player: Node2D
var sawPlayer: bool = false
var detection_timer: float = 0.0

enum State { PATROL, CHASE }
var current_state: State = State.PATROL


func _ready() -> void:
	for point in patrol_points_node.get_children():
		patrol_points.append(point.global_position)
	player = get_tree().get_first_node_in_group("player")

	# Vision ray only "sees" layers 17 (player) and 18 (walls).
	# Layer 19 (other guards) is excluded, so guards never block each other's sight.
	vision_ray.collision_mask = 0
	vision_ray.set_collision_mask_value(17, true)
	vision_ray.set_collision_mask_value(18, true)
	vision_ray.enabled = true


func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			if is_detecting:
				velocity = Vector2.ZERO
				move_and_slide()
			elif is_waiting:
				wait_timer += delta
				velocity = Vector2.ZERO
				if wait_timer >= patrol_wait_time:
					is_waiting = false
					current_point_index = (current_point_index + 1) % patrol_points.size()
			else:
				_patrol()
		State.CHASE:
			_chase()

	_update_vision(delta)
	queue_redraw()


func _patrol() -> void:
	if patrol_points.is_empty():
		return

	if is_waiting:
		return

	var target = patrol_points[current_point_index]
	var to_target = target - global_position

	if to_target.length() < ARRIVAL_THRESHOLD:
		is_waiting = true
		wait_timer = 0.0
		# Face the direction the marker was rotated to point
		var marker = patrol_points_node.get_child(current_point_index)
		facing_direction = Vector2.RIGHT.rotated(marker.rotation)
	else:
		facing_direction = to_target.normalized()
		velocity = facing_direction * patrol_speed
		move_and_slide()


func _chase() -> void:
	if player == null:
		return

	var to_player = player.global_position - global_position
	if to_player.length() > 5.0:
		facing_direction = to_player.normalized()
		velocity = facing_direction * chase_speed
		move_and_slide()



func _update_vision(delta: float) -> void:
	if player == null:
		return

	match current_state:
		State.PATROL:
			if _can_see_player():
				facing_direction = (player.global_position - global_position).normalized()
				is_detecting = true
				detection_timer += delta

				if detection_timer >= time_to_detect:
					sawPlayer = true
					is_detecting = false
					current_state = State.CHASE
					lost_sight_timer = 0.0
					print("Guard: player spotted, starting chase")
					player_spotted.emit()
			else:
				if is_detecting:
					print("Guard: lost sight during detection, resuming patrol")
				is_detecting = false
				detection_timer = 0.0

		State.CHASE:
			_update_chase_tracking(delta)

func _update_chase_tracking(delta: float) -> void:
	if _can_see_player():
		lost_sight_timer = 0.0
	else:
		lost_sight_timer += delta
		if lost_sight_timer >= chase_lose_time:
			print("Guard: lost the player, giving up chase")
			_reset_to_patrol()
			return

	# Catch check: only matters while actively chasing
	var distance = (player.global_position - global_position).length()
	if distance <= catch_distance:
		catch_timer += delta
		if catch_timer >= catch_time:
			print("Guard: caught the player! GAME OVER")
			player_caught.emit()
	else:
		catch_timer = 0.0


func _reset_to_patrol() -> void:
	current_state = State.PATROL
	sawPlayer = false
	detection_timer = 0.0
	is_detecting = false
	lost_sight_timer = 0.0
	catch_timer = 0.0

func _can_see_player() -> bool:
	if player == null:
		print("DEBUG: player is null")
		return false

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > vision_range:
		print("DEBUG: too far, distance=", distance, " range=", vision_range)
		return false

	var angle_diff = rad_to_deg(facing_direction.angle_to(to_player.normalized()))
	if abs(angle_diff) > vision_angle_degrees:
		print("DEBUG: outside angle, angle_diff=", angle_diff, " max=", vision_angle_degrees)
		return false

	vision_ray.target_position = to_local(player.global_position)
	vision_ray.force_raycast_update()

	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		print("DEBUG: ray hit ", collider.name, " expected player=", player.name)
		if collider != player:
			return false

	print("DEBUG: player detected!")
	return true


func _draw() -> void:
	var color = Color(1, 0, 0, 0.35) if current_state == State.CHASE else Color(1, 1, 0, 0.25)
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)

	var steps := 20
	for i in range(steps + 1):
		var angle = -vision_angle_degrees + (2 * vision_angle_degrees) * i / steps
		var dir = facing_direction.rotated(deg_to_rad(angle))
		points.append(dir * vision_range)

	draw_colored_polygon(points, color)

	# Detection meter bar, only visible while filling
	if is_detecting:
		var bar_width: float = 40.0
		var bar_height: float = 6.0
		var bar_pos: Vector2 = Vector2(-bar_width / 2, -50)
		var fill_ratio: float = clamp(detection_timer / time_to_detect, 0.0, 1.0)


		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bar_pos, Vector2(bar_width * fill_ratio, bar_height)), Color(1, 0.2, 0.2, 0.9))

func _process(_delta: float) -> void:
	debug_label.text = "state: %s | detect: %.1f | lost: %.1f | catch: %.1f" % [
		State.keys()[current_state], detection_timer, lost_sight_timer, catch_timer
	]
