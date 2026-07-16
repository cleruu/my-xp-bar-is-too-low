extends Sprite2D

const moveDistance = 250.0
const moveTime = 1.5

const leftLimit = -350.0
const rightLimit = 350.0

func _ready():
	randomize()

func _on_timer_timeout():
	var direction = randi_range(-1, 1)

	if direction == 0:
		return

	var target_position = position
	target_position.x += direction * moveDistance
	target_position.x = clamp(target_position.x, leftLimit, rightLimit)

	var tween = create_tween()
	tween.tween_property(self, "position", target_position, moveTime)
