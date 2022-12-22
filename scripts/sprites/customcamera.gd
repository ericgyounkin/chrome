extends Camera2D

var smooth_zoom = 2.5
var target_zoom = 2.5

const ZOOM_SPEED = 5

func _process(delta):
	smooth_zoom = lerp(smooth_zoom, target_zoom, ZOOM_SPEED * delta)
	if smooth_zoom != target_zoom:
		set_zoom(Vector2(smooth_zoom, smooth_zoom))