extends CharacterBody2D


@onready var player_node: CharacterBody2D = get_parent().get_node("Player")
@export_range(0, 100) var speed: float = 60.0
var gravity = 15

@export_range(-1, 1) var dir: int = 1

func ready() -> void: 
	if dir == 0:
		dir = 1
	$AnimatedSprite2D.flip_h = false if dir == 1 else true
	
func _physics_process(delta: float) -> void:
	if dir == 1 and (!$RightRay.is_colliding() or $RightWallRay.is_colliding()):
		$AnimatedSprite2D.flip_h = false
		dir = 0
		wait_dir_change(-1)
		
	if dir == -1 and (!$LeftRay.is_colliding() or $LeftWallRay.is_colliding()):
		$AnimatedSprite2D.flip_h = true
		dir = 0
		wait_dir_change(1)
		
	velocity.x = lerp(velocity.x, dir * speed, 10.0 * delta)
	velocity.y = gravity
	move_and_slide()

func wait_dir_change(desired_dir: int): 
	await get_tree().create_timer(0.5).timeout
	dir = desired_dir

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player_node:
		await player_node.die()
		get_tree().call_deferred("reload_current_scene")
