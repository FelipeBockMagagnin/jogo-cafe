extends Camera2D



@export var player
	

func _process(delta):
	position.x=player.position.x
	position.y=player.position.y
