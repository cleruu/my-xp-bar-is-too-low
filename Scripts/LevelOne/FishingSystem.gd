extends Node2D

var isOnBar = false
const fillSpeed = 15.0
const drainSpeed = 10.0

func _on_area_2d_body_entered(body: Node2D) -> void:
	isOnBar = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	isOnBar = false

func _process(delta):
	if isOnBar:
		%TextureProgressBar.value += fillSpeed * delta
	else:
		%TextureProgressBar.value -= drainSpeed * delta
	if %TextureProgressBar.value >= 100:
		print("Success")

	%TextureProgressBar.value = clamp(%TextureProgressBar.value, 0, 100)
#	print("isOnBar:", isOnBar, " value:", %TextureProgressBar.value)
