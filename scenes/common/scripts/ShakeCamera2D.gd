extends Camera2D
class_name ShakeCamera2D

@export var decay = 0.8
@export var max_offset = Vector2(100, 75)
@export var max_roll = 0.1
@export var target: NodePath

var trauma = 0.0  
var trauma_power = 2.5

@onready var noise = FastNoiseLite.new()
var noise_y = 0

func _ready():
	add_to_group("camera")
	randomize()
	noise.seed = randi()
	noise.frequency = 0.16
	noise.fractal_octaves = 2

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
	
func _process(delta):
	if trauma > 0.0:
		print("Trauma", trauma)
		trauma = max(trauma - decay * delta, 0.0)
		shake()
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO

func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
