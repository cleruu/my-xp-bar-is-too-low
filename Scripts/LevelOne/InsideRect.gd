extends RigidBody2D

const vectorSpeed = 500

func _physics_process(delta):
	if Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		linear_velocity.x = vectorSpeed 
	else:
		linear_velocity.x = -vectorSpeed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lock_rotation = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
