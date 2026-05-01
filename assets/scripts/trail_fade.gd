extends Sprite2D

var color = Color(0.25, 0.594, 0.86, 0.5)

func _process(_delta):
	modulate = color
	color.a *= 0.90
	if (color.a < 0.001): queue_free()
