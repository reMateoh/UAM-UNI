extends CharacterBody2D

signal fell_off_screen
signal score_updated(new_score: int)

const SPEED = 300.0
const JUMP_FORCE = -800.0
const GRAVITY = 1200.0

var camera: Camera2D
var max_camera_y: float = 0.0
var start_y: float = 0.0
var score: int = 0

@onready var animacion = $AnimatedSprite2D

func _ready():
	camera = $Camera2D
	max_camera_y = global_position.y
	start_y = global_position.y

func _physics_process(delta: float) -> void:
	# --- Movimiento horizontal ---
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	
	# --- Gravedad ---
	velocity.y += GRAVITY * delta
	
	# --- Salto automático al tocar plataforma ---
	if is_on_floor():
		velocity.y = JUMP_FORCE
	
	# --- Animaciones ---
	if direction > 0:
		animacion.play("salto lateral")
	else:
		animacion.play("salto frontal")
	
	move_and_slide()
	
	# --- Cámara solo sube + calcular score ---
	if global_position.y < max_camera_y:
		max_camera_y = global_position.y
		
		var new_score = int((start_y - global_position.y) / 10.0)
		if new_score > score:
			score = new_score
			score_updated.emit(score)
	
	# --- Envolver horizontal ---
	var screen_width = get_viewport_rect().size.x
	if global_position.x > screen_width:
		global_position.x = 0
	elif global_position.x < 0:
		global_position.x = screen_width
	
	# --- Game Over ---
	if global_position.y > max_camera_y + 600.0:
		fell_off_screen.emit()
		set_physics_process(false)
