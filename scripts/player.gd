extends CharacterBody2D
class_name CoopPlayer2D

@export var player_id: int = 1 # 1 = Player 1 (WASD + E), 2 = Player 2 (Setas + Enter)
@export var speed: float = 300.0
@export var acceleration: float = 1900.0
@export var friction: float = 1500.0
@export var jump_velocity: float = -500.0
@export var jump_cut_multiplier: float = 0.5

@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

var gravity: float = 1300.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var spawn_position: Vector2
var facing_direction: float = 1.0
var is_repairing: bool = false
var carried_item: bool = false
var _password_key_held: bool = false  # Evita múltiplos inputs enquanto tecla está pressionada

var nearby_stations: Array[Node] = []
var nearby_sync_terminal: Node = null
var nearby_conveyor: Node = null

@onready var visual_root: Node2D = $Visual
@onready var body_rect: ColorRect = $Visual/Body
@onready var bandana_rect: ColorRect = $Visual/Bandana
@onready var carried_item_rect: ColorRect = $Visual/CarriedItem
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var prompt_label: Label = $PromptLabel
@onready var repair_sparks: CPUParticles2D = $RepairSparks

func _ready() -> void:
	spawn_position = global_position
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 1300.0)
	apply_player_identity()
	if prompt_label:
		prompt_label.visible = false

func apply_player_identity() -> void:
	if visual_root == null:
		return
	if player_id == 1:
		if body_rect:
			body_rect.color = Color(0.25, 0.65, 0.95, 1.0) # Azul elétrico P1
		if bandana_rect:
			bandana_rect.color = Color(0.95, 0.85, 0.2, 1.0) # Faixa Amarela
	else:
		if body_rect:
			body_rect.color = Color(0.95, 0.45, 0.2, 1.0) # Laranja mecânico P2
		if bandana_rect:
			bandana_rect.color = Color(0.2, 0.85, 0.4, 1.0) # Faixa Verde

func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		if not was_on_floor:
			apply_squash_stretch(Vector2(1.2, 0.8))
			SoundManager.play(get_tree(), "step", 0.2)
	
	was_on_floor = is_on_floor()
	jump_buffer_timer -= delta

	# Input para entrar/sair do modo de interação
	var can_interact = (get_active_broken_station() != null) or (nearby_sync_terminal != null) or (nearby_conveyor != null)
	if player_id == 1:
		if Input.is_key_pressed(KEY_E) and can_interact and not is_repairing:
			is_repairing = true
		elif Input.is_key_pressed(KEY_Q) and is_repairing:
			is_repairing = false
	else:
		if Input.is_key_pressed(KEY_COMMA) and can_interact and not is_repairing:
			is_repairing = true
		elif Input.is_key_pressed(KEY_PERIOD) and is_repairing:
			is_repairing = false
			
	if not can_interact:
		is_repairing = false

	# Inputs específicos de cada jogador
	var wants_jump = false
	var jump_released = false
	var input_x = 0.0
	
	if not is_repairing:
		wants_jump = check_jump_pressed()
		jump_released = check_jump_released()
		input_x = get_horizontal_input()

	if wants_jump:
		jump_buffer_timer = jump_buffer_time

	# Execução de pulo
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		apply_squash_stretch(Vector2(0.8, 1.25))
		SoundManager.play(get_tree(), "jump", 0.1)

	# Corte de pulo
	if jump_released and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# Movimento horizontal
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
	
	if carried_item_rect:
		carried_item_rect.visible = carried_item

	# Interação com estação de reparo
	process_interaction(is_repairing, delta)
	
	# Inputs de minigame (password: só aceita um input por pressionamento)
	if is_repairing:
		var current_station = get_active_broken_station()
		var is_password = current_station != null and current_station.has_method("get_minigame_type") and current_station.get_minigame_type() == "password"
		
		var up_pressed    = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
		var down_pressed  = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
		var left_pressed  = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
		var right_pressed = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
		var any_dir_pressed = up_pressed or down_pressed or left_pressed or right_pressed
		
		if is_password:
			# Modo senha: registra apenas UM input por pressionamento
			if not any_dir_pressed:
				_password_key_held = false  # Tecla solta, pronto para nova leitura
			elif not _password_key_held:
				_password_key_held = true
				if up_pressed:
					send_minigame_input("UP")
				elif down_pressed:
					send_minigame_input("DOWN")
				elif left_pressed:
					send_minigame_input("LEFT")
				elif right_pressed:
					send_minigame_input("RIGHT")
		else:
			# Outros minigames: comportamento original
			if Input.is_action_just_pressed("p1_jump") or up_pressed:
				send_minigame_input("UP")
			if Input.is_action_just_pressed("p1_left") or left_pressed:
				send_minigame_input("LEFT")
			if Input.is_action_just_pressed("p1_right") or right_pressed:
				send_minigame_input("RIGHT")
			if down_pressed:
				send_minigame_input("DOWN")
			if Input.is_action_just_pressed("p1_interact") or Input.is_action_just_pressed("p2_interact") or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_COMMA):
				send_minigame_input("INTERACT") # interagir com "E" caso seja o A e "," caso seja o B

	# isso é para se algué,m for out of bounds
	if global_position.y > 900.0:
		respawn()

func check_jump_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_jump") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE)
	else:
		return Input.is_action_just_pressed("p2_jump") or Input.is_key_pressed(KEY_UP)

func check_jump_released() -> bool:
	if player_id == 1:
		return Input.is_action_just_released("p1_jump") or (not Input.is_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_SPACE))
	else:
		return Input.is_action_just_released("p2_jump") or not Input.is_key_pressed(KEY_UP)

func get_horizontal_input() -> float:
	var x: float = 0.0
	if player_id == 1:
		if Input.is_action_pressed("p1_left") or Input.is_key_pressed(KEY_A):
			x -= 1.0
		if Input.is_action_pressed("p1_right") or Input.is_key_pressed(KEY_D):
			x += 1.0
	else:
		if Input.is_action_pressed("p2_left") or Input.is_key_pressed(KEY_LEFT):
			x -= 1.0
		if Input.is_action_pressed("p2_right") or Input.is_key_pressed(KEY_RIGHT):
			x += 1.0
	return x

func check_interact_pressed() -> bool:
	return is_repairing

func get_active_broken_station() -> Node:
	for station in nearby_stations:
		if is_instance_valid(station) and station.has_method("is_broken") and station.is_broken():
			return station
	return null

func send_minigame_input(val: String) -> void:
	var current_station = get_active_broken_station()
	if current_station and current_station.has_method("receive_minigame_input"):
		# Evitar spam contínuo por is_key_pressed usando _unhandled_key_input seria melhor,
		# mas aqui filtraremos chamando apenas num tick se precisarmos, ou deixamos a station filtrar.
		# A station filtrará pelo estado.
		current_station.receive_minigame_input(val)

func process_interaction(holding_interact: bool, delta: float) -> void:
	# Lógica do Sync Terminal
	if nearby_sync_terminal:
		if holding_interact:
			if player_id == 1 and nearby_sync_terminal.has_method("set_p1_pressing"):
				nearby_sync_terminal.set_p1_pressing(true)
			elif player_id == 2 and nearby_sync_terminal.has_method("set_p2_pressing"):
				nearby_sync_terminal.set_p2_pressing(true)
		else:
			if player_id == 1 and nearby_sync_terminal.has_method("set_p1_pressing"):
				nearby_sync_terminal.set_p1_pressing(false)
			elif player_id == 2 and nearby_sync_terminal.has_method("set_p2_pressing"):
				nearby_sync_terminal.set_p2_pressing(false)

	# Lógica do Conveyor
	var conveyor_interact = Input.is_key_pressed(KEY_E) if player_id == 1 else Input.is_key_pressed(KEY_COMMA)
	if nearby_conveyor and conveyor_interact:
		if player_id == 1 and carried_item:
			if nearby_conveyor.try_insert_item(player_id):
				carried_item = false
		elif player_id == 2 and not carried_item:
			if nearby_conveyor.try_take_item(player_id):
				carried_item = true

	var current_station = get_active_broken_station()
	if current_station:
		if prompt_label:
			prompt_label.visible = true
			if holding_interact:
				var exit_key = "Q" if player_id == 1 else "."
				prompt_label.text = "[%s] Sair" % exit_key
			else:
				var enter_key = "E" if player_id == 1 else ","
				prompt_label.text = "[%s] Consertar" % enter_key
		
		if holding_interact:
			is_repairing = true
			if repair_sparks:
				repair_sparks.emitting = true
			current_station.repair_tick(delta, self)
			apply_squash_stretch(Vector2(1.05, 0.95))
		else:
			is_repairing = false
			if repair_sparks:
				repair_sparks.emitting = false
	else:
		is_repairing = false
		if prompt_label:
			prompt_label.visible = false
		if repair_sparks:
			repair_sparks.emitting = false

func apply_squash_stretch(target_scale: Vector2) -> void:
	if visual_root == null:
		return
	var tween = create_tween()
	visual_root.scale = Vector2(facing_direction * target_scale.x, target_scale.y)
	tween.tween_property(visual_root, "scale", Vector2(facing_direction, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func respawn() -> void:
	SoundManager.play(get_tree(), "hit", 0.1)
	global_position = spawn_position
	velocity = Vector2.ZERO

func _on_interaction_area_entered(area: Area2D) -> void:
	var station = area.get_parent()
	if station and station.has_method("set_p1_pressing"): # É o Sync Terminal!
		nearby_sync_terminal = station
	elif station and station.has_method("try_insert_item"): # É o Conveyor!
		nearby_conveyor = station
	elif station and not nearby_stations.has(station):
		nearby_stations.append(station)

func _on_interaction_area_exited(area: Area2D) -> void:
	var station = area.get_parent()
	if station == nearby_sync_terminal:
		if player_id == 1 and nearby_sync_terminal.has_method("set_p1_pressing"):
			nearby_sync_terminal.set_p1_pressing(false)
		elif player_id == 2 and nearby_sync_terminal.has_method("set_p2_pressing"):
			nearby_sync_terminal.set_p2_pressing(false)
		nearby_sync_terminal = null
	elif station == nearby_conveyor:
		nearby_conveyor = null
	elif station and nearby_stations.has(station):
		nearby_stations.erase(station)
