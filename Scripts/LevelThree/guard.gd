extends CharacterBody2D

# --- Patrol ---
@export var patrol_speed: float = 100.0
@export var chase_speed: float = 160.0
const ARRIVAL_THRESHOLD := 5.0

@onready var patrol_points_node: Node2D = $patrolPoints
@onready var vision_ray: RayCast2D = $visionRay
@onready var vision_ray2: RayCast2D = $visionRay2
@onready var vision_ray3: RayCast2D = $visionRay3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var patrol_points: Array[Vector2] = []
var current_point_index: int = 0
var facing_direction: Vector2 = Vector2.DOWN
var last_flip_h: bool = false

# This is for smooth rotation
@export var turn_speed: float = 5.0
var desired_direction: Vector2 = Vector2.DOWN

signal player_caught 
var is_detecting: bool = false

signal player_spotted
signal player_lost # NEW: Added missing signal for level manager

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
@export var peripheral_radius: float = 45.0 # Distance where guard ignores angle
@export var suspicion_drain_rate: float = 1.5 # How fast the meter drains when sight is lost
@onready var debug_label: Label = $Label

var is_waiting: bool = false
var wait_timer: float = 0.0
var player: Node2D
var sawPlayer: bool = false
var detection_timer: float = 0.0

enum State { PATROL, CHASE }
var current_state: State = State.PATROL

@export var wander_radius: float = 300.0
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var spawn_position: Vector2

# Pathfinding Optimization 
@export var path_update_interval: float = 0.15 # Update path every 0.15 seconds
var path_update_timer: float = 0.0
# For pathfinding failsafe
@export var stuck_time_limit: float = 0.5
var stuck_timer: float = 0.0
var previous_position: Vector2


func _ready() -> void:
	if patrol_points_node:
		for point in patrol_points_node.get_children():
			patrol_points.append(point.global_position)
			
	player = get_tree().get_first_node_in_group("player")

	# Vision ray only "sees" layers 17 (player) and 18 (walls).
	setRayCast(vision_ray)
	setRayCast(vision_ray2)
	setRayCast(vision_ray3)
	
	spawn_position = global_position
	
	# Wait for the navigation map to fully synchronize before asking it questions
	await get_tree().physics_frame
	_pick_new_wander_target()

func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			if is_detecting:
				if player != null and (player.global_position - global_position).length() > 5.0:
					# NEW: Throttled path updating
					path_update_timer -= delta
					if path_update_timer <= 0.0:
						nav_agent.target_position = player.global_position
						path_update_timer = path_update_interval # Reset timer
					
					var next_path_position: Vector2 = nav_agent.get_next_path_position()
					var target_direction = global_position.direction_to(next_path_position)
					
					desired_direction = desired_direction.lerp(target_direction, 0.5).normalized()
					velocity = desired_direction * chase_speed
					move_and_slide()
			elif is_waiting:
				wait_timer += delta
				velocity = Vector2.ZERO
				if wait_timer >= patrol_wait_time:
					is_waiting = false
					# FIXED: Removed the old patrol array index code here!
			else:
				_patrol()
		State.CHASE:
			_chase(delta)
			
	facing_direction = facing_direction.slerp(desired_direction, turn_speed * delta)

	# --- Sprite flip logic (mirrors player script) ---
	if facing_direction.x > 0:
		last_flip_h = true
		sprite.flip_h = true
	elif facing_direction.x < 0:
		last_flip_h = false
		sprite.flip_h = false
	elif facing_direction.y != 0:
		sprite.flip_h = not last_flip_h

	_update_vision(delta)
	queue_redraw()
	
	if current_state == State.PATROL and not is_waiting and not is_detecting:
		
		var distance_moved = global_position.distance_to(previous_position)
		if distance_moved < (patrol_speed * delta * 0.1):
			stuck_timer += delta
			if stuck_timer >= stuck_time_limit:
				print("DEBUG: Guard got stuck! Forcing a new path.")
				_pick_new_wander_target()
				stuck_timer = 0.0
		else:
			# We are moving fine, reset the timer
			stuck_timer = 0.0
			
	# Always update the previous position for the next frame's math
	previous_position = global_position

func _pick_new_wander_target() -> void:
	var max_attempts = 10
	var found_valid_point = false
	
	# Try up to 10 times to find a point we can actually walk to
	for i in range(max_attempts):
		var random_angle = randf() * TAU 
		var random_distance = randf_range(50.0, wander_radius) 
		var random_target = spawn_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
		
		# Ensure the target is actually on the navigable floor
		var map_rid = get_world_2d().navigation_map
		var safe_target = NavigationServer2D.map_get_closest_point(map_rid, random_target)
		
		# Feed the coordinate to the agent so it calculates a path
		nav_agent.target_position = safe_target
		
		if nav_agent.is_target_reachable():
			found_valid_point = true
			break 
			
	if not found_valid_point:
		nav_agent.target_position = spawn_position

func setRayCast(rc: RayCast2D) -> void:
	rc.set_collision_mask_value(17, true)
	rc.set_collision_mask_value(18, true)
	rc.enabled = true

		
func _patrol() -> void:
	if is_waiting:
		return
	
	if nav_agent.is_navigation_finished():
		is_waiting = true
		wait_timer = 0.0
		
		# Look around randomly while waiting
		desired_direction = Vector2.RIGHT.rotated(randf() * TAU)
		
		# Queue up the next location
		_pick_new_wander_target()
		return
	
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	desired_direction = global_position.direction_to(next_path_position)

	if is_on_wall():
		desired_direction = (desired_direction + get_wall_normal() * 0.8).normalized()


	velocity = desired_direction * patrol_speed
	move_and_slide()


func _chase(delta: float) -> void:
	if player == null:
		return

	var to_player = player.global_position - global_position
	if to_player.length() > 5.0:

		path_update_timer -= delta
		if path_update_timer <= 0.0:
			nav_agent.target_position = player.global_position
			path_update_timer = path_update_interval # Reset timer
		
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		desired_direction = global_position.direction_to(next_path_position)

		if is_on_wall():
			desired_direction = (desired_direction + get_wall_normal() * 0.8).normalized()
		# -----------------------------------------------

		velocity = desired_direction * chase_speed
		move_and_slide()



func _update_vision(delta: float) -> void:
	if player == null:
		return

	match current_state:
		State.PATROL:
			if _can_see_player():
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
				vision_ray.enabled = false
				vision_ray2.enabled = false
				vision_ray3.enabled = false
				
				# Suspicion Decay instead of instant reset
				if detection_timer > 0.0:
					detection_timer -= delta * suspicion_drain_rate
					if detection_timer <= 0.0:
						print("Guard: lost sight during detection, resuming patrol")
						is_detecting = false
						detection_timer = 0.0
				else:
					is_detecting = false

		State.CHASE:
			_update_chase_tracking(delta)

func _update_chase_tracking(delta: float) -> void:
	if _can_see_player():
		lost_sight_timer = 0.0
	else:
		lost_sight_timer += delta
		if lost_sight_timer >= chase_lose_time:
			print("Guard: lost the player, giving up chase")
			player_lost.emit() # NEW: Tell LevelManager to change the music!
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
	
	# Recalculate a new path when giving up the chase
	_pick_new_wander_target()

func _can_see_player() -> bool:
	if player == null:
		return false
	
	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > vision_range:
		return false
	
	# Peripheral Vision / "Sixth Sense"
	if distance > peripheral_radius:
		var angle_diff = rad_to_deg(facing_direction.angle_to(to_player.normalized()))
		if abs(angle_diff) > vision_angle_degrees:
			return false
	
	var direction_to_player = (player.global_position - global_position).normalized()
	var perpendicular = direction_to_player.orthogonal()
	var spread_distance = 15.0 

	raycastEnable(vision_ray, perpendicular * spread_distance)   # Left edge
	raycastEnable(vision_ray2, Vector2.ZERO)                     # Dead center
	raycastEnable(vision_ray3, -perpendicular * spread_distance) # Right edge
	
	var hit_player = false
	var rays := [vision_ray, vision_ray2, vision_ray3]
	for ray in rays:
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider != player:
				continue
			hit_player = true

	return hit_player

func raycastEnable(rc: RayCast2D, height_offset: Vector2 = Vector2.ZERO) -> void:
	rc.enabled = true
	# Add the offset to the player's position so the rays spread out
	rc.target_position = to_local(player.global_position + height_offset)
	rc.force_raycast_update()

func _draw() -> void:
	# 1. Draw Vision Cone
	var color = Color(1, 0, 0, 0.35) if current_state == State.CHASE else Color(1, 1, 0, 0.25)
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)

	var steps := 20
	for i in range(steps + 1):
		var angle = -vision_angle_degrees + (2 * vision_angle_degrees) * i / steps
		var dir = facing_direction.rotated(deg_to_rad(angle))
		points.append(dir * (vision_range + 335))

	draw_colored_polygon(points, color)
	
	# 2. Draw a faint inner circle to visualize the peripheral "Sixth Sense" radius
	draw_arc(Vector2.ZERO, peripheral_radius, 0, TAU, 32, Color(1, 1, 1, 0.2), 1.0)

	# 4. Detection meter bar
	if is_detecting:
		var bar_width: float = 40.0
		var bar_height: float = 6.0
		var bar_pos: Vector2 = Vector2(-bar_width / 2, -50)
		var fill_ratio: float = clamp(detection_timer / time_to_detect, 0.0, 1.0)

		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.5))

func _process(_delta: float) -> void:
	debug_label.text = "state: %s | detect: %.1f | lost: %.1f | catch: %.1f" % [
		State.keys()[current_state], detection_timer, lost_sight_timer, catch_timer
	]
