extends StaticBody2D

@export var moveSpeed: float = 260.0

@onready var hitbox: Area2D = $Hitbox

func _ready():
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
	else:
		print("ERROR: No Hitbox found!")

func _physics_process(delta: float) -> void:
	position.x -= moveSpeed * delta
	if position.x < -200:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Try direct reference first
		var controller = get_tree().current_scene
		if controller and controller.has_method("deduct_score"):
			controller.deduct_score(5000)
