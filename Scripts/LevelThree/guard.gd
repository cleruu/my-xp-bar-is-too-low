extends CharacterBody2D

# --- Patrol ---
@export var patrol_speed: float = 100.0
@export var chase_speed: float = 160.0
const ARRIVAL_THRESHOLD := 5.0

@onready var patrol_points_node: Node2D = $patrolPoints
@onready var vision_ray: RayCast2D = $visionRay
@onready var sprite: AnimatedSprite2D = $guard

var patrol_points: Array[Vector2] = []
var current_point_index: int = 0
var facing_direction: Vector2 = Vector2.DOWN

# --- Vision ---
@export var vision_range: float = 250.0
@export var vision_angle_degrees: float = 45.0  # half-angle either side of facing direction
@export var time_to_detect: float = 3.0

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
			_patrol()
		State.CHASE:
			_chase()

	_update_vision(delta)
	queue_redraw()  # refresh the cone visual every frame


func _patrol() -> void:
	if patrol_points.is_empty():
		return

	var target = patrol_points[current_point_index]
	var to_target = target - global_position

	if to_target.length() < ARRIVAL_THRESHOLD:
		current_point_index = (current_point_index + 1) % patrol_points.size()
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

	if _can_see_player():
		detection_timer += delta
		if detection_timer >= time_to_detect:
			sawPlayer = true
			current_state = State.CHASE
	else:
		detection_timer = 0.0


func _can_see_player() -> bool:
	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > vision_range:
		return false

	var angle_diff = rad_to_deg(facing_direction.angle_to(to_player.normalized()))
	if abs(angle_diff) > vision_angle_degrees:
		return false

	vision_ray.target_position = to_local(player.global_position)
	vision_ray.force_raycast_update()

	# Ray can only hit the player or a wall (mask excludes other guards),
	# so if it's colliding with something that isn't the player, it's a wall.
	if vision_ray.is_colliding() and vision_ray.get_collider() != player:
		return false

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
