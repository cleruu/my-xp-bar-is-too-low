extends Label

signal game_over 

var score: int = 50000

func _ready():
	update_display()

func update_display():
	text = "Php " + format_number(score)

func format_number(number: int) -> String:
	var str_num = str(number)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		result = str_num[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	
	return result

func deduct_score(amount: int):
	score -= amount
	if score < 0:
		score = 0
	update_display()
	
	# Check if score reached zero
	if score <= 0:
		game_over.emit()  # Emit the signal
