extends Node2D

@export var float_speed: float = 100.0
@export var lifetime: float = 1.0

@onready var label: Label = $DamageLabel

func _ready():
	# Play animation
	var tween = create_tween()
	
	# Move up and fade out
	tween.parallel().tween_property(self, "position:y", position.y - 100, lifetime)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), lifetime)
	
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()
