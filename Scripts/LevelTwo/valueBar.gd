extends TextureProgressBar

signal game_over

@export var max_money := 50000

func _ready():
	min_value = 0
	max_value = max_money
	value = max_money

func deduct_score(amount: int):
	value = max(value - amount, 0)

	if value <= 0:
		game_over.emit()

func get_current_money() -> int:
	return int(value)
