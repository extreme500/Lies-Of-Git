extends CharacterBody2D
class_name CoopPlayer2D

@export var player_id: int = 1 # 1 = Player 1 (WASD + E), 2 = Player 2 (Setas + Enter)
@export var speed: float = 300.0
@export var acceleration: float = 1900.0
@export var friction: float = 1500.0
@export var jump_velocity: float = -580.0
@export var jump_cut_multiplier: float = 0.5

@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

# ==============================================================================
# 🎮 CONFIGURAÇÃO DE ANIMAÇÕES DOS ROBÔS (PLAYER 1 & PLAYER 2)
# ==============================================================================
@export_group("Animation Settings")
## Escala visual do sprite (o pixel art original é 32x32)
@export var sprite_scale: Vector2 = Vector2(2.0, 2.0)
## Deslocamento do sprite para o Player 1 (Azul) - Pés alinhados perfeitamente com o chão
@export var sprite_offset_p1: Vector2 = Vector2(0, 8)
## Deslocamento do sprite para o Player 2 (Laranja) - Pés alinhados com o chão
@export var sprite_offset_p2: Vector2 = Vector2(0, -2)

@export_subgroup("Animation Speeds (FPS)")
## Velocidade (frames por segundo) da animação Idle (parado)
@export var idle_fps: float = 4.0
## Velocidade da animação Run (correndo)
@export var run_fps: float = 8.0
## Velocidade da animação Fix (consertando a estação)
@export var fix_fps: float = 8.0
## Velocidade da animação de Transição (Run -> Fix) do Player 2
@export var transition_fps: float = 12.0
## Velocidade da animação de Pulo
@export var jump_fps: float = 10.0

@export_subgroup("Jump Frame Configuration")
## Se true, usa controle inteligente de frames de pulo (impulso, no ar, descida)
@export var enable_jump_air_control: bool = true
## Frame que representa o robô NO AR ("on air" / ápice do pulo)
## Dica: Player 1 = 3 (ou entre 2 e 4) | Player 2 = 4 (ou entre 4 e 6)
@export var jump_air_frame: int = 3
## Frame de impulso / subida inicial do pulo
@export var jump_takeoff_frame: int = 1
## Frame de descida / queda livre
@export var jump_fall_frame: int = 4

var gravity: float = 1300.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var spawn_position: Vector2
var facing_direction: float = 1.0
var is_repairing: bool = false
var carried_item: bool = false
var _password_key_held: bool = false  # Evita múltiplos inputs enquanto tecla está pressionada
var is_transitioning_to_fix: bool = false
var _interact_key_was_pressed: bool = false

var nearby_stations: Array[Node] = []
var nearby_sync_terminal: Node = null
var nearby_conveyor: Node = null

var frames_p1: SpriteFrames = preload("res://assets/players/player_1_frames.tres")
var frames_p2: SpriteFrames = preload("res://assets/players/player_2_frames.tres")

@onready var visual_root: Node2D = $Visual
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var body_rect: ColorRect = get_node_or_null("Visual/Body")
@onready var bandana_rect: ColorRect = get_node_or_null("Visual/Bandana")
@onready var carried_item_rect: ColorRect = $Visual/CarriedItem
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var prompt_label: Label = $PromptLabel
@onready var repair_sparks: CPUParticles2D = $RepairSparks

var fixing_audio: AudioStreamPlayer2D = null

func _ready() -> void:
	spawn_position = global_position
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 1300.0)
	apply_player_identity()
	if prompt_label:
		prompt_label.visible = false
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	
	# Efeito sonoro de conserto/interação contínua ("Novos/Fixing.ogg") - bem baixinho
	fixing_audio = AudioStreamPlayer2D.new()
	fixing_audio.name = "FixingAudio"
	var fix_stream = load("res://sfx/Novos/Fixing.ogg")
	if fix_stream:
		fixing_audio.stream = fix_stream
	fixing_audio.volume_db = -18.0
	fixing_audio.finished.connect(func():
		if is_repairing and is_instance_valid(fixing_audio):
			fixing_audio.pitch_scale = randf_range(0.92, 1.08)
			fixing_audio.play()
	)
	add_child(fixing_audio)

func apply_player_identity() -> void:
	if animated_sprite == null:
		return
	
	if player_id == 1:
		# Player 1 = Robô Azul
		animated_sprite.sprite_frames = frames_p1
		animated_sprite.position = sprite_offset_p1
	else:
		# Player 2 = Robô Laranja
		animated_sprite.sprite_frames = frames_p2
		animated_sprite.position = sprite_offset_p2
		# Ajusta valores padrão para os 8 frames de pulo do Player 2 se estiverem nos padrões
		if jump_air_frame == 3:
			jump_air_frame = 4
		if jump_fall_frame == 4:
			jump_fall_frame = 6
	
	animated_sprite.scale = sprite_scale
	animated_sprite.play("idle")

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

	# Input para entrar/sair do modo de interação e ações diretas
	var interact_down = Input.is_key_pressed(KEY_E) if player_id == 1 else Input.is_key_pressed(KEY_COMMA)
	var interact_just_pressed = interact_down and not _interact_key_was_pressed
	_interact_key_was_pressed = interact_down
	
	var exit_down = Input.is_key_pressed(KEY_Q) if player_id == 1 else Input.is_key_pressed(KEY_PERIOD)
	
	var active_station = get_active_broken_station()
	if is_repairing and (active_station == null or not active_station.is_broken() or exit_down):
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
	process_interaction(interact_down, interact_just_pressed, delta)
	
	# Atualiza o estado da animação dos sprites (Idle, Run, Jump, Fix, Transition)
	update_animation_state(delta)
	
	# Inputs de minigame (password e simon: só aceita um input por pressionamento do jogador correto)
	if is_repairing:
		var up_pressed: bool = false
		var down_pressed: bool = false
		var left_pressed: bool = false
		var right_pressed: bool = false
		
		if player_id == 1:
			up_pressed = Input.is_key_pressed(KEY_W)
			down_pressed = Input.is_key_pressed(KEY_S)
			left_pressed = Input.is_key_pressed(KEY_A)
			right_pressed = Input.is_key_pressed(KEY_D)
		else:
			up_pressed = Input.is_key_pressed(KEY_UP)
			down_pressed = Input.is_key_pressed(KEY_DOWN)
			left_pressed = Input.is_key_pressed(KEY_LEFT)
			right_pressed = Input.is_key_pressed(KEY_RIGHT)
		
		var any_dir_pressed = up_pressed or down_pressed or left_pressed or right_pressed
		
		# Registra apenas UM input por pressionamento (evita spam e contaminação entre jogadores)
		if not any_dir_pressed:
			_password_key_held = false
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

func process_interaction(interact_down: bool, interact_just_pressed: bool, delta: float) -> void:
	# Lógica do Sync Terminal
	if nearby_sync_terminal:
		if player_id == 1 and nearby_sync_terminal.has_method("set_p1_pressing"):
			nearby_sync_terminal.set_p1_pressing(interact_down)
		elif player_id == 2 and nearby_sync_terminal.has_method("set_p2_pressing"):
			nearby_sync_terminal.set_p2_pressing(interact_down)

	# Lógica do Conveyor
	if nearby_conveyor and interact_just_pressed:
		if player_id == 1 and carried_item:
			if nearby_conveyor.try_insert_item(player_id, global_position.y):
				carried_item = false
		elif player_id == 2 and not carried_item:
			if nearby_conveyor.try_take_item(player_id, global_position.y):
				carried_item = true

	# Lógica das estações de reparo
	var current_station = get_active_broken_station()
	if current_station:
		var mg_type = current_station.minigame_type
		var role = current_station.role
		
		# Minigames de ação única (Dispenser, Entrega, Gerador)
		if mg_type == "item":
			if role == "A":
				# Dispenser (Player 1) - Não trava o jogador em modo reparo
				if prompt_label:
					prompt_label.visible = true
					if current_station.mg_state.get("has_item", false):
						prompt_label.text = "[E] Pegar Peça"
					elif current_station.anim_sprite and current_station.anim_sprite.animation == "dispense":
						prompt_label.text = "Dispensando..."
					else:
						prompt_label.text = "Aguardando..."
				if interact_just_pressed:
					current_station.try_dispenser_pickup(self)
				is_repairing = false
			elif role == "B":
				# Entrega (Player 2) - Entrega direta ao apertar interagir
				if prompt_label:
					prompt_label.visible = true
					prompt_label.text = "[,] Entregar Peça" if carried_item else "Precisa de Peça"
				if interact_just_pressed and carried_item:
					current_station.try_deliver_item(self)
				is_repairing = false
		elif mg_type == "skillcheck":
			if role == "B":
				# Gerador de Calibragem (Player 2) - Calibra ao apertar interagir
				if prompt_label:
					prompt_label.visible = true
					prompt_label.text = "[,] Sincronizar"
				if interact_just_pressed:
					current_station.try_skillcheck_calibrate()
				is_repairing = false
			elif role == "A":
				# Gerador (Player 1) - Apenas indicador visual
				if prompt_label:
					prompt_label.visible = true
					prompt_label.text = "Calibrador Ativo"
				is_repairing = false
		elif mg_type == "password" and role == "A":
			# Receptor de Senha (Player 1) - apenas exibe o código para o Player 2
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "Código de Acesso"
			is_repairing = false
		else:
			# Minigames com sequência de setas (Password B e Simon A/B)
			var enter_key = "E" if player_id == 1 else ","
			var exit_key = "Q" if player_id == 1 else "."
			if prompt_label:
				prompt_label.visible = true
				if is_repairing:
					prompt_label.text = "[%s] Sair" % exit_key
				else:
					prompt_label.text = "[%s] Interagir" % enter_key
			
			if interact_just_pressed and not is_repairing:
				is_repairing = true
			
			if is_repairing:
				if repair_sparks:
					repair_sparks.emitting = true
				if fixing_audio and not fixing_audio.playing:
					fixing_audio.pitch_scale = randf_range(0.95, 1.05)
					fixing_audio.play()
				if current_station.has_method("set_interacting"):
					current_station.set_interacting(true)
				current_station.repair_tick(delta, self)
			else:
				if repair_sparks:
					repair_sparks.emitting = false
				if fixing_audio and fixing_audio.playing:
					fixing_audio.stop()
				if current_station.has_method("set_interacting"):
					current_station.set_interacting(false)
	elif nearby_conveyor:
		is_repairing = false
		if repair_sparks:
			repair_sparks.emitting = false
		if fixing_audio and fixing_audio.playing:
			fixing_audio.stop()
		if prompt_label:
			if player_id == 1:
				if carried_item:
					prompt_label.visible = true
					prompt_label.text = "[E] Colocar Peça"
				else:
					prompt_label.visible = false
			elif player_id == 2:
				if not carried_item and nearby_conveyor.has_method("has_piece_on_belt") and nearby_conveyor.has_piece_on_belt():
					prompt_label.visible = true
					prompt_label.text = "[,] Pegar Peça"
				else:
					prompt_label.visible = false
	else:
		is_repairing = false
		if prompt_label:
			prompt_label.visible = false
		if repair_sparks:
			repair_sparks.emitting = false
		if fixing_audio and fixing_audio.playing:
			fixing_audio.stop()

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
		if station.has_method("set_interacting"):
			station.set_interacting(false)
		nearby_stations.erase(station)
		if fixing_audio and fixing_audio.playing:
			fixing_audio.stop()

# ==============================================================================
# 🎬 SISTEMA DE ANIMAÇÃO DOS ROBÔS
# ==============================================================================
func update_animation_state(_delta: float) -> void:
	if animated_sprite == null:
		return

	if is_repairing:
		if player_id == 2:
			# Player 2: Para ir de walking/run para fix, precisa passar por transition
			if is_transitioning_to_fix:
				# Continua executando a animação de transição até o fim
				pass
			elif animated_sprite.animation != "fix":
				# Iniciando conserto: toca a animação de transição primeiro!
				is_transitioning_to_fix = true
				play_anim("transition", transition_fps)
		else:
			# Player 1: Transiciona diretamente para o fix
			play_anim("fix", fix_fps)
	else:
		# Não está consertando: cancela transição caso estivesse no meio
		is_transitioning_to_fix = false
		
		if not is_on_floor():
			# No ar / pulando
			if enable_jump_air_control:
				if velocity.y < -120.0:
					# Subida / Decolagem
					play_jump_frame(jump_takeoff_frame)
				elif abs(velocity.y) <= 120.0:
					# Ápice / No ar ("on air")
					play_jump_frame(jump_air_frame)
				else:
					# Queda / Descida
					play_jump_frame(jump_fall_frame)
			else:
				play_anim("jump", jump_fps)
		else:
			# No chão
			if abs(velocity.x) > 10.0:
				play_anim("run", run_fps)
			else:
				play_anim("idle", idle_fps)

func play_anim(anim_name: String, speed_fps: float) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)
	
	# Ajusta a velocidade de reprodução baseada no FPS configurado
	var default_speed = animated_sprite.sprite_frames.get_animation_speed(anim_name)
	if default_speed > 0.0:
		animated_sprite.speed_scale = speed_fps / default_speed

func play_jump_frame(frame_idx: int) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation("jump"):
		return
	
	if animated_sprite.animation != "jump":
		animated_sprite.play("jump")
	
	animated_sprite.pause()
	var total_frames = animated_sprite.sprite_frames.get_frame_count("jump")
	animated_sprite.frame = clamp(frame_idx, 0, total_frames - 1)

func _on_animated_sprite_animation_finished() -> void:
	# Quando a animação de transition do Player 2 chega ao final, começa a animação de fix
	if is_transitioning_to_fix:
		is_transitioning_to_fix = false
		if is_repairing:
			play_anim("fix", fix_fps)
