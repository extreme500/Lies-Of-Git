extends CharacterBody2D
class_name RunnerPlayer

signal crashed

@export var jump_velocity: float = -520.0
@export var gravity: float = 1400.0

var can_double_jump: bool = false
var is_sliding: bool = false
var is_dead: bool = false

@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual
@onready var dust_particles: CPUParticles2D = $DustParticles

var default_col_size: Vector2 = Vector2(26, 48)
var slide_col_size: Vector2 = Vector2(40, 20)

func _ready() -> void:
	if col_shape and col_shape.shape is RectangleShape2D:
		default_col_size = col_shape.shape.size

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
		if dust_particles:
			dust_particles.emitting = false
	else:
		can_double_jump = true
		if dust_particles:
			dust_particles.emitting = true

	# Pulo
	var wants_jump = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept")
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up") or (wants_jump and Input.is_key_pressed(KEY_SPACE) and not Input.is_action_pressed("ui_down")):
		if is_on_floor():
			velocity.y = jump_velocity
			can_double_jump = true
			SoundManager.play(get_tree(), "jump", 0.1)
			apply_stretch(Vector2(0.7, 1.3))
		elif can_double_jump:
			velocity.y = jump_velocity * 0.9
			can_double_jump = false
			SoundManager.play(get_tree(), "jump", 0.25)
			apply_stretch(Vector2(0.7, 1.3))

	# Deslizar / Agachar (Slide)
	var wants_slide = Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")
	if wants_slide and not is_sliding:
		start_slide()
	elif not wants_slide and is_sliding:
		stop_slide()

	move_and_slide()

func start_slide() -> void:
	is_sliding = true
	SoundManager.play(get_tree(), "step", 0.2)
	if col_shape and col_shape.shape is RectangleShape2D:
		col_shape.shape.size = slide_col_size
		col_shape.position.y = 14.0
	if visual:
		visual.scale = Vector2(1.4, 0.45)
		visual.position.y = 12.0

func stop_slide() -> void:
	is_sliding = false
	if col_shape and col_shape.shape is RectangleShape2D:
		col_shape.shape.size = default_col_size
		col_shape.position.y = 0.0
	if visual:
		visual.scale = Vector2.ONE
		visual.position.y = 0.0

func apply_stretch(target_scale: Vector2) -> void:
	if visual == null or is_sliding:
		return
	var tween = create_tween()
	visual.scale = target_scale
	tween.tween_property(visual, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func hit_obstacle() -> void:
	if is_dead:
		return
	is_dead = true
	SoundManager.play(get_tree(), "hit", 0.1)
	crashed.emit()

	var tween = create_tween()
	modulate = Color(2.0, 0.3, 0.3, 1.0)
	tween.tween_property(visual, "rotation_degrees", 90.0, 0.2)
	tween.parallel().tween_property(self, "position:y", position.y + 20, 0.2)
