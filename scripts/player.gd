extends CharacterBody2D
class_name Player2D

# Configurações de movimentação
@export var speed: float = 320.0
@export var acceleration: float = 2000.0
@export var friction: float = 1600.0
@export var jump_velocity: float = -520.0
@export var jump_cut_multiplier: float = 0.5

# Game feel: Coyote time e Jump buffer
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

var gravity: float = 1300.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var spawn_position: Vector2
var facing_direction: float = 1.0

# Referências visuais
@onready var visual_root: Node2D = $Visual
@onready var trail_particles: CPUParticles2D = $TrailParticles

func _ready() -> void:
	spawn_position = global_position
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 1300.0)

func _physics_process(delta: float) -> void:
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		if not was_on_floor:
			# Squash ao aterrissar
			apply_squash_stretch(Vector2(1.25, 0.75))
			SoundManager.play(get_tree(), "step", 0.2)
	
	was_on_floor = is_on_floor()
	jump_buffer_timer -= delta

	# Input de pulo
	var wants_jump = Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	if wants_jump:
		jump_buffer_timer = jump_buffer_time

	# Executar pulo
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		apply_squash_stretch(Vector2(0.75, 1.3))
		SoundManager.play(get_tree(), "jump", 0.1)

	# Corte de pulo variável (soltar espaço faz cair antes)
	var jump_released = Input.is_action_just_released("ui_accept") or (not Input.is_key_pressed(KEY_SPACE) and not Input.is_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_UP))
	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# Movimento horizontal
	var input_x: float = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0

	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * speed, acceleration * delta)
		facing_direction = input_x
		if visual_root:
			visual_root.scale.x = facing_direction
		if trail_particles:
			trail_particles.emitting = is_on_floor()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		if trail_particles:
			trail_particles.emitting = false

	move_and_slide()

	# Queda do mapa (morte automática)
	if global_position.y > 1000.0:
		die()

func bounce(strength: float = -450.0) -> void:
	velocity.y = strength
	apply_squash_stretch(Vector2(0.8, 1.25))
	SoundManager.play(get_tree(), "jump", 0.2)

func apply_squash_stretch(target_scale: Vector2) -> void:
	if visual_root == null:
		return
	var tween = create_tween()
	visual_root.scale = Vector2(facing_direction * target_scale.x, target_scale.y)
	tween.tween_property(visual_root, "scale", Vector2(facing_direction, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func die() -> void:
	SoundManager.play(get_tree(), "hit", 0.1)
	global_position = spawn_position
	velocity = Vector2.ZERO
	# Notificar Game Manager sobre a morte
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("register_death"):
		gm.register_death()
