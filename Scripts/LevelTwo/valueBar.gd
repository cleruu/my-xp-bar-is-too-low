extends ColorRect

signal game_over

@export var max_value: int = 50000
@export var min_value: int = 0
@export var current_value: int = 50000

var bar_width: float = 300.0

func _ready():
	bar_width = size.x
	update_display()

func update_display():
	# Calculate percentage
	var percentage = float(current_value - min_value) / float(max_value - min_value)
	percentage = clamp(percentage, 0.0, 1.0)
	
	# Update this node's width (itself)
	size.x = bar_width * percentage
	
	# Update color based on value
	if percentage > 0.6:
		color = Color(0, 1, 0)  # Green
	elif percentage > 0.3:
		color = Color(1, 1, 0)  # Yellow
	else:
		color = Color(1, 0, 0)  # Red

func deduct_score(amount: int):
	current_value -= amount
	if current_value < min_value:
		current_value = min_value
	update_display()
	
	# Check if value reached zero
	if current_value <= 0:
		game_over.emit()

func get_value() -> int:
	return current_value
