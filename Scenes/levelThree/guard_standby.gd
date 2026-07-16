extends CharacterBody2D

@export var chase_speed: float = 160.0

@onready var vision_ray: RayCast2D = $visionRay
@onready var vision_ray2: RayCast2D = $visionRay2
@onready var vision_ray3: RayCast2D = $visionRay3
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing_direction: Vector2 = Vector2.DOWN
var last_flip_h: bool = false
@export var turn_speed: float = 5.0
var desired_direction: Vector2 = Vector2.DOWN

signal player_caught 
signal player_spotted
signal player_lost 

# --- Vision & Detection ---
@export var vision_range: float = 250.0
@export var vision_angle_degrees: float = 45.0
@export var time_to_detect: float = 0.3
@export var patrol_wait_time: float = 1.5   # How often they snap to a new direction
@export var peripheral_radius: float = 45.0 
@export var suspicion_drain_rate: float = 1.5 

# --- Chase Timers ---
@export var chase_lose_time: float = 2.0
var lost_sight_timer: float = 0.0
@export var catch_distance: float = 30.0
@export var catch_time: float = 1.0
var catch_timer: float = 0.0

var is_detecting: bool = false
var wait_timer: float = 0.0
var player: Node2D
var sawPlayer: bool = false
var detection_timer: float = 0.0

enum State { IDLE, CHASE }
var current_state: State = State.IDLE

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@export var path_update_interval: float = 0.15 
var path_update_timer: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	setRayCast(vision_ray)
	setRayCast(vision_ray2)
	setRayCast(vision_ray3)

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			
			if is_detecting:
				if player != null and (player.global_position - global_position).length() > 5.0:
					path_update_timer -= delta
					if path_update_timer <= 0.0:
						nav_agent.target_position = player.global_position
						path_update_timer = path_update_interval 
					
					var next_path_position: Vector2 = nav_agent.get_next_path_position()
					var target_direction = global_position.direction_to(next_path_position)
					
					desired_direction = desired_direction.lerp(target_direction, 0.5).normalized()
					velocity = desired_direction * chase_speed
					move_and_slide()
			else:
				# Stand still and occasionally rotate
				wait_timer += delta
				if wait_timer >= patrol_wait_time:
					wait_timer = 0.0
					desired_direction = Vector2.RIGHT.rotated(randf() * TAU)
		
		State.CHASE:
			_chase(delta)
			
	facing_direction = facing_direction.slerp(desired_direction, turn_speed * delta)

	# Sprite flip logic
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

func setRayCast(rc: RayCast2D) -> void:
	rc.set_collision_mask_value(17, true)
	rc.set_collision_mask_value(18, true)
	rc.enabled = true

func _chase(delta: float) -> void:
	if player == null:
		return

	var to_player = player.global_position - global_position
	if to_player.length() > 5.0:
		path_update_timer -= delta
		if path_update_timer <= 0.0:
			nav_agent.target_position = player.global_position
			path_update_timer = path_update_interval
		
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		desired_direction = global_position.direction_to(next_path_position)

		if is_on_wall():
			desired_direction = (desired_direction + get_wall_normal() * 0.8).normalized()

		velocity = desired_direction * chase_speed
		move_and_slide()

func _update_vision(delta: float) -> void:
	if player == null:
		return

	match current_state:
		State.IDLE:
			if _can_see_player():
				is_detecting = true
				detection_timer += delta
			
				if detection_timer >= time_to_detect:
					sawPlayer = true
					is_detecting = false
					current_state = State.CHASE
					lost_sight_timer = 0.0
					player_spotted.emit()
			else:
				vision_ray.enabled = false
				vision_ray2.enabled = false
				vision_ray3.enabled = false
				
				if detection_timer > 0.0:
					detection_timer -= delta * suspicion_drain_rate
					if detection_timer <= 0.0:
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
			player_lost.emit()
			_reset_to_idle()
			return

	var distance = (player.global_position - global_position).length()
	if distance <= catch_distance:
		catch_timer += delta
		if catch_timer >= catch_time:
			player_caught.emit()
	else:
		catch_timer = 0.0

func _reset_to_idle() -> void:
	current_state = State.IDLE
	sawPlayer = false
	detection_timer = 0.0
	is_detecting = false
	lost_sight_timer = 0.0
	catch_timer = 0.0
	velocity = Vector2.ZERO

func _can_see_player() -> bool:
	if player == null:
		return false
	
	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > vision_range:
		return false
	
	if distance > peripheral_radius:
		var angle_diff = rad_to_deg(facing_direction.angle_to(to_player.normalized()))
		if abs(angle_diff) > vision_angle_degrees:
			return false
	
	var direction_to_player = (player.global_position - global_position).normalized()
	var perpendicular = direction_to_player.orthogonal()
	var spread_distance = 15.0 

	raycastEnable(vision_ray, perpendicular * spread_distance)
	raycastEnable(vision_ray2, Vector2.ZERO)
	raycastEnable(vision_ray3, -perpendicular * spread_distance)
	
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
	rc.target_position = to_local(player.global_position + height_offset)
	rc.force_raycast_update()

func _draw() -> void:
	# Only draw the vision cone and peripheral circle when aggressive
	if current_state == State.CHASE:
		var color = Color(1, 0, 0, 0.35)
		var points := PackedVector2Array()
		points.append(Vector2.ZERO)

		var steps := 20
		for i in range(steps + 1):
			var angle = -vision_angle_degrees + (2 * vision_angle_degrees) * i / steps
			var dir = facing_direction.rotated(deg_to_rad(angle))
			points.append(dir * (vision_range + 335))

		draw_colored_polygon(points, color)
		draw_arc(Vector2.ZERO, peripheral_radius, 0, TAU, 32, Color(1, 1, 1, 0.2), 1.0)
