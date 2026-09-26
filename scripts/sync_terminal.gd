extends Node2D

signal sync_exploded

@export var cooldown_min: float = 20.0
@export var cooldown_max: float = 35.0
@export var time_to_press: float = 12.0

var status: String = "OK" # "OK", "WARNING", "ALERT", "EXPLODED"
var timer: float = 0.0
var explosion_timer: float = 0.0
var warning_timer: float = 0.0
var is_paused: bool = false

var p1_pressing: bool = false
var p2_pressing: bool = false

@onready var p1_button: AnimatedSprite2D = $P1_Button
@onready var p2_button: AnimatedSprite2D = $P2_Button
@onready var screen_p1: AnimatedSprite2D = $Screen_P1 if has_node("Screen_P1") else null
@onready var screen_p2: AnimatedSprite2D = $Screen_P2 if has_node("Screen_P2") else null
@onready var screen_anim: AnimatedSprite2D = $Screen if has_node("Screen") else null
@onready var alert_label: Label = $AlertLabel

func _ready() -> void:
	timer = randf_range(cooldown_min, cooldown_max)
	if alert_label: alert_label.hide()
	
	if p1_button:
		p1_button.animation_finished.connect(_on_p1_anim_finished)
	if p2_button:
		p2_button.animation_finished.connect(_on_p2_anim_finished)
	if screen_p1:
		screen_p1.animation_finished.connect(_on_screen_anim_finished)
	elif screen_anim:
		screen_anim.animation_finished.connect(_on_screen_anim_finished)
		
	update_visual()
	call_deferred("snap_to_surface")

func set_paused(val: bool) -> void:
	is_paused = val

func _on_screen_anim_finished() -> void:
	if status == "WARNING":
		start_alert_phase()

func _on_p1_anim_finished() -> void:
	if p1_button:
		if p1_button.animation == "opening":
			p1_button.play("open_idle")
		elif p1_button.animation == "closing":
			p1_button.play("idle")

func _on_p2_anim_finished() -> void:
	if p2_button:
		if p2_button.animation == "opening":
			p2_button.play("open_idle")
		elif p2_button.animation == "closing":
			p2_button.play("idle")

func snap_to_surface() -> void:
	if not is_inside_tree() or not get_world_2d():
		return
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return
	var from_pos = global_position - Vector2(0, 30)
	var to_pos = global_position + Vector2(0, 500)
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 1 # Chão e plataformas
	var result = space_state.intersect_ray(query)
	if result and not result.is_empty():
		global_position.y = result.position.y - 20.0

func _process(delta: float) -> void:
	if status == "ALERT" and p1_pressing and p2_pressing:
		resolve_sync()
		return
#dark souls 2 esteve aqui
	if is_paused:
		return
		
	if status == "OK":
		timer -= delta
		if timer <= 0.0:
			trigger_sync_event()
	elif status == "WARNING":
		warning_timer -= delta
		if warning_timer <= 0.0:
			start_alert_phase()
	elif status == "ALERT":
		explosion_timer -= delta

		if explosion_timer <= 0.0:
			explode()

func trigger_sync_event() -> void:
	if status == "ALERT" or status == "WARNING":
		return
	status = "WARNING"
	warning_timer = 1.0 # Duração da animação de transição da tela
	if screen_p1: screen_p1.play("transition")
	if screen_p2: screen_p2.play("transition")
	if screen_anim: screen_anim.play("transition")
	SoundManager.play(get_tree(), "hit", 0.1)

func start_alert_phase() -> void:
	if status != "WARNING":
		return
	status = "ALERT"
	explosion_timer = time_to_press
	if alert_label: alert_label.show()
	SoundManager.play(get_tree(), "lose", 0.25)
	
	# Transição de fechado para aberto nos botões e telas em alerta (aguardando)
	if p1_button: p1_button.play("opening")
	if p2_button: p2_button.play("opening")
	if screen_p1: screen_p1.play("alert")
	if screen_p2: screen_p2.play("alert")
	if screen_anim: screen_anim.play("alert")

func resolve_sync() -> void:
	status = "OK"
	timer = randf_range(cooldown_min, cooldown_max)
	if alert_label: alert_label.hide()
	SoundManager.play(get_tree(), "powerup", 0.5)
	p1_pressing = false
	p2_pressing = false
	
	# Transição de aberto para fechado
	if p1_button: p1_button.play("closing")
	if p2_button: p2_button.play("closing")
	if screen_p1: screen_p1.play("idle")
	if screen_p2: screen_p2.play("idle")
	if screen_anim: screen_anim.play("idle")

func explode() -> void:
	status = "EXPLODED"
	sync_exploded.emit()

func update_visual() -> void:
	if status == "OK":
		if p1_button: p1_button.play("idle")
		if p2_button: p2_button.play("idle")
		if screen_p1: screen_p1.play("idle")
		if screen_p2: screen_p2.play("idle")
		if screen_anim: screen_anim.play("idle")
	elif status == "ALERT":
		if screen_p1: screen_p1.play("alert")
		if screen_p2: screen_p2.play("alert")
		if screen_anim: screen_anim.play("alert")
		if p1_button:
			p1_button.play("pressed" if p1_pressing else "open_idle")
		if p2_button:
			p2_button.play("pressed" if p2_pressing else "open_idle")

# Chamado pelas áreas de interação separadas de P1 e P2
func set_p1_pressing(val: bool) -> void:
	p1_pressing = val
	if status == "ALERT" and p1_button:
		p1_button.play("pressed" if val else "open_idle")

func set_p2_pressing(val: bool) -> void:
	p2_pressing = val
	if status == "ALERT" and p2_button:
		p2_button.play("pressed" if val else "open_idle")
