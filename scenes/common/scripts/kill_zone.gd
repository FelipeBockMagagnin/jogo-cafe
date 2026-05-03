extends Area2D

@onready var player_node: CharacterBody2D = get_parent().get_node("Player")

func _on_body_entered(body: Node2D) -> void:
	print('aaa')
	if body == player_node:
		await player_node.die()
		get_tree().call_deferred("reload_current_scene")
