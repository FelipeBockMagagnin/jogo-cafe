extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, WALL_SLIDE, DASH }

@export var ACCELERATION = 3000.0
@export var MAX_SPEED = 150.0
@export var LIMIT_SPEED_Y = 400.0
@export var JUMP_VELOCITY = -400.0
@export var MIN_JUMP_VELOCITY = -400.0
@export var MAX_COYOTE_TIME = 0.1
@export var JUMP_BUFFER_TIME = 0.16
@export var WALL_JUMP_X = 150.0
@export var WALL_JUMP_TIME = 0.16
@export var GRAVITY = 1500.0
@export var DASH_SPEED = 300.0
@export var DASH_DURATION = 0.15
@export var WALL_SLIDE_FACTOR = 0.4

var current_state = State.IDLE

var axis = Vector2.ZERO
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var wall_jump_timer = 0.0
var dash_timer = 0.0

var has_dashed = false
var dash_direction = Vector2.ZERO

@onready var rotatable = $Rotatable
@onready var anim = $Rotatable/AnimatedSprite2D
@onready var wall_raycast = $Rotatable/RayCast2D

@export var trail_script : GDScript =  null

func _on_ready() -> void:
	add_to_group("Player")
	if GlobalScript.checkpoint_pos != Vector2(-999, -999):
		global_position = GlobalScript.checkpoint_pos

func _physics_process(delta):
	axis = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	update_timers(delta)
	handle_jump_input()
	
	match current_state:
		State.IDLE:
			handle_idle(delta)
		State.RUN:
			handle_run(delta)
		State.JUMP:
			handle_jump_state(delta)
		State.FALL:
			handle_fall(delta)
		State.WALL_SLIDE:
			handle_wall_slide(delta)
		State.DASH:
			handle_dash(delta)

	move_and_slide()

func update_timers(delta):
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if wall_jump_timer > 0:
		wall_jump_timer -= delta

func handle_jump_input():
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	if Input.is_action_just_released("jump") or Input.is_action_just_released("ui_up"):
		if velocity.y < MIN_JUMP_VELOCITY:
			velocity.y = MIN_JUMP_VELOCITY

func apply_gravity(delta):
	if velocity.y < LIMIT_SPEED_Y:
		velocity.y += GRAVITY * delta

func apply_friction(delta):
	velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)

func apply_horizontal_movement(delta):
	if axis.x != 0:
		velocity.x = move_toward(velocity.x, MAX_SPEED * sign(axis.x), ACCELERATION * delta)
		rotatable.scale.x = sign(axis.x)
	else:
		apply_friction(delta)

func check_dash_transition():
	if not has_dashed and Input.is_action_just_pressed("dash"):
		start_dash()
		return true
	return false

func start_dash():
	current_state = State.DASH
	dash_timer = DASH_DURATION
	has_dashed = true
	dash_direction = axis.normalized() if axis != Vector2.ZERO else Vector2(rotatable.scale.x, 0)
	velocity = dash_direction * DASH_SPEED
	Input.start_joy_vibration(0, 1, 1, 0.2)

func jump():
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0
	jump_buffer_timer = 0

func wall_jump():
	velocity.y = JUMP_VELOCITY
	velocity.x = -WALL_JUMP_X * rotatable.scale.x
	rotatable.scale.x = -rotatable.scale.x
	wall_jump_timer = WALL_JUMP_TIME
	jump_buffer_timer = 0

func check_ground_jump():
	if (is_on_floor() or coyote_timer > 0) and jump_buffer_timer > 0:
		jump()
		current_state = State.JUMP
		return true
	return false

func check_wall_jump():
	if not is_on_floor() and wall_raycast.is_colliding() and jump_buffer_timer > 0:
		wall_jump()
		current_state = State.JUMP
		return true
	return false

func check_wall_transition():
	if not is_on_floor() and wall_raycast.is_colliding():
		current_state = State.WALL_SLIDE
	return false

func reset_dash_on_floor():
	if is_on_floor() and velocity.y >= 0:
		has_dashed = false

func play_anim(anim_name: String):
	# Garantir que a animação existe no AnimatedSprite2D antes de tocar
	if anim.sprite_frames and anim.sprite_frames.has_animation(anim_name) and anim.animation != anim_name:
		anim.play(anim_name)


# --- ESTADOS DA MÁQUINA DE ESTADOS (FSM) ---

func handle_idle(delta):
	reset_dash_on_floor()
	coyote_timer = MAX_COYOTE_TIME
	apply_friction(delta)
	apply_gravity(delta)
	
	play_anim("idle")
	
	if check_dash_transition(): return
	if check_ground_jump(): return
	
	if axis.x != 0:
		current_state = State.RUN
	elif not is_on_floor():
		current_state = State.FALL

func handle_run(delta):
	reset_dash_on_floor()
	coyote_timer = MAX_COYOTE_TIME
	apply_horizontal_movement(delta)
	apply_gravity(delta)
	
	play_anim("run")
	
	if check_dash_transition(): return
	if check_ground_jump(): return
	
	if axis.x == 0 and velocity.x == 0:
		current_state = State.IDLE
	elif not is_on_floor():
		current_state = State.FALL

func handle_jump_state(delta):
	if wall_jump_timer <= 0:
		apply_horizontal_movement(delta)
	apply_gravity(delta)
	
	play_anim("jump")
	
	if check_dash_transition(): return
	if check_wall_jump(): return
	if check_wall_transition(): return
	
	if velocity.y >= 0:
		current_state = State.FALL

func handle_fall(delta):
	if wall_jump_timer <= 0:
		apply_horizontal_movement(delta)
	apply_gravity(delta)
	
	play_anim("fall")
	
	if check_dash_transition(): return
	if check_wall_jump(): return
	if check_wall_transition(): return
	if check_ground_jump(): return
	
	if is_on_floor():
		if axis.x != 0:
			current_state = State.RUN
		else:
			current_state = State.IDLE

func handle_wall_slide(delta):
	apply_gravity(delta)
	# Desliza
	velocity.y *= WALL_SLIDE_FACTOR
	
	# Permite sair da parede
	if not wall_raycast.is_colliding() or (axis.x != 0 and sign(axis.x) != sign(rotatable.scale.x)):
		apply_horizontal_movement(delta)
		
	play_anim("wall_slide")
	
	if check_wall_jump(): return
	
	if check_dash_transition(): return
		
	if not wall_raycast.is_colliding() or is_on_floor():
		if is_on_floor():
			current_state = State.IDLE
		else:
			current_state = State.FALL

func handle_dash(delta):
	dash_timer -= delta
	velocity = dash_direction * DASH_SPEED
	
	if dash_timer <= 0:
		if is_on_floor():
			current_state = State.IDLE if axis.x == 0 else State.RUN
		else:
			current_state = State.FALL

# Este método presumivelmente estava conectado a um nó Timer do projeto original
func _on_trailTimer_timeout():
	if current_state == State.DASH:
		var trail_sprite = Sprite2D.new()
		# Pega a textura do frame atual da animação e desenha no trail
		trail_sprite.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
		#trail_sprite.scale.x = rotatable.scale.x * 2 * 1.2
		#trail_sprite.scale.y = 2 * 1.2
		trail_sprite.set_script(trail_script)
		
		get_parent().add_child(trail_sprite)
		trail_sprite.position = position
		trail_sprite.modulate = Color(1, 0.08, 0.58, 0.5)
		trail_sprite.z_index = -49
