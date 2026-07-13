extends StaticBody2D

@export var moveSpeed: float = 260.0

func _physics_process(delta: float) -> void:
	position.x -= moveSpeed * delta
	if position.x < -200:
		queue_free()
