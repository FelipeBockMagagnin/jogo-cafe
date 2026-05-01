extends CharacterBody2D
class_name PlayerCharacterBody2D

@onready var ledge_detector_r: LedgeDetector = %LedgeDetectorR
@onready var ledge_detector_l: LedgeDetector = %LedgeDetectorL
@onready var state_machine: CharacterControllerStateMachine = %StateMachine
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

@export var character_size: Vector2

@export_group("Control Variables")
@export var looking_left := false

func _on_ready() -> void:
	add_to_group("Player")
	
	if GlobalScript.checkpoint_pos != Vector2(-999, -999):
		global_position = GlobalScript.checkpoint_pos
	
func _physics_process(_delta: float) -> void:
	move_and_slide()

func _process(delta: float) -> void:
	animated_sprite_2d.flip_h = looking_left
