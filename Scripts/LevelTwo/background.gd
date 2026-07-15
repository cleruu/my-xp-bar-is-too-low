extends Parallax2D

@export var scrollSpeed: float = 300.0
@export var texturePath: String = "res://Assets/Sprites/LevelTwoBg.PNG"

func _ready():
	var texture: Texture2D = $Sprite2D.texture
	if texture == null:
		texture = load(texturePath)
		$Sprite2D.texture = texture

	if texture:
		# Only auto-calc repeat_size if it wasn't already tuned by hand
		# in the editor (a manually-set value is left alone).
		if repeat_size.x <= 0:
			var scaled_width: float = texture.get_width() * $Sprite2D.scale.x
			repeat_size = Vector2(scaled_width, 0)

		# Make sure enough copies exist that one is ALWAYS on screen,
		# no matter how wide the viewport is relative to the tile.
		var viewport_width: float = get_viewport_rect().size.x
		var needed_copies: int = ceili(viewport_width / repeat_size.x) + 1
		repeat_times = maxi(2, needed_copies)
	else:
		push_warning("Background texture failed to load: " + texturePath)

	autoscroll = Vector2(-scrollSpeed, 0)
