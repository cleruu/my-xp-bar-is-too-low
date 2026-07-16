extends ParallaxBackground

## How fast the background scrolls, in pixels per second.
@export var scrollSpeed: float = 100.0

func _process(delta: float) -> void:
	scroll_offset.x -= scrollSpeed * delta
