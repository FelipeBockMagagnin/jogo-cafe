extends Sprite2D



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GlobalScript.checkpoint_pos = $Marker2D.global_position
		if GlobalScript.previous_checkpoint_node:
			GlobalScript.previous_checkpoint_node._update_sprite()
		GlobalScript.previous_checkpoint_node = self
		_update_sprite()
		
		
func _update_sprite() -> void:
	if $Marker2D.global_position == GlobalScript.checkpoint_pos:
		frame = 1
	else: 
		frame = 0
