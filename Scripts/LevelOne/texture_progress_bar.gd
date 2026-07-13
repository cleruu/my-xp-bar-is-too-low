extends TextureProgressBar

func _ready():
	value = 0

func _process(delta):
	if Input.is_action_pressed("ui_accept"): # Space key
		value += 50 * delta
	else:
		value -= 50 * delta

	value = clamp(value, min_value, max_value)
