@tool
extends AnimatedSprite2D

@export var line_length: float = 40.0:
	set(value):
		line_length = value
		queue_redraw()

@export var line_color: Color = Color(0.15, 0.15, 0.15)
@export var line_width: float = 2.0
@export var gravity: float = 200.0 # pixels por segundo quadrado


var has_fallen: bool = false
var is_triggered: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	stop()
	frame = 0
	animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if has_fallen:
		global_position.y += gravity * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	if body is CharacterBody2D and !is_triggered:
		is_triggered = true
		play("cracking")

func _on_animation_finished() -> void:
	if Engine.is_editor_hint():
		return
	if animation == "cracking" and !has_fallen:
		start_fall()
	elif animation == "falling":
		queue_free()

func start_fall() -> void:
	has_fallen = true
	play("falling")
	queue_redraw()
	
	if has_node("StaticBody2D/CollisionShape2D"):
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	if has_node("Area2D/CollisionShape2D"):
		$Area2D/CollisionShape2D.set_deferred("disabled", true)


func _draw() -> void:
	if has_fallen:
		return
	draw_line(Vector2(0, 0), Vector2(0, 0 - line_length), line_color, line_width)
