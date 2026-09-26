extends Node2D
class_name GameManager

@export var survival_time: float = 6000.0 # Segundos necessários para vencer a Fase 1
@export var min_failure_interval: float = 4.0
@export var max_failure_interval: float = 6.5

var time_remaining: float = 60.0
var game_finished: bool = false
var failure_timer: float = 3.0 # Primeiro defeito surge aos 3s
var stations: Array = []

var maquina: CentralMaquina = null
var auto_failures_enabled: bool = true
var is_machine_paused: bool = false
var debug_panel: PanelContainer = null
var debug_pause_btn: Button = null
var debug_fail_btn: Button = null
var debug_msg_label: Label = null
var _debug_msg_timer: float = 0.0

var background_textures: Array = []
var current_bg_index: int = 0

@onready var hud: CanvasLayer = $HUD
@onready var timer_label: Label = find_child("TimerLabel", true, false)
@onready var integrity_label: Label = find_child("IntegrityLabel", true, false)
@onready var integrity_bar: ProgressBar = find_child("IntegrityBar", true, false)
@onready var faults_label: Label = find_child("FaultsLabel", true, false)
@onready var victory_panel: PanelContainer = find_child("VictoryPanel", true, false)
@onready var game_over_panel: PanelContainer = find_child("GameOverPanel", true, false)
@onready var pause_panel: PanelContainer = find_child("PausePanel", true, false)

var pause_diff_label: Label = null
var pause_music_slider: HSlider = null
var pause_music_label: Label = null
var pause_sfx_slider: HSlider = null
var pause_sfx_label: Label = null

func _ready() -> void:
	add_to_group("game_manager")
	time_remaining = survival_time
	
	process_mode = Node.PROCESS_MODE_ALWAYS # GameManager keeps running for inputs
	
	_load_background_textures()
	play_start_run_intro()
	
	# Trilha sonora em loop suave durante a gameplay
	SoundManager.play_bgm(get_tree(), "res://assets/Ost/MELHOR loop fundo principal.mp3", -15.0)
	
	# Localizar máquina principal de forma segura
	maquina = get_node_or_null("Máquina") as CentralMaquina
	if not maquina:
		maquina = get_node_or_null("Maquina") as CentralMaquina
	if not maquina:
		maquina = find_child("Máquina", true, false) as CentralMaquina
	if not maquina:
		maquina = find_child("Maquina", true, false) as CentralMaquina
	if not maquina:
		for child in get_children():
			if child is CentralMaquina:
				maquina = child
				break
	
	if victory_panel:
		victory_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if pause_panel:
		pause_panel.visible = false

	_setup_pause_menu()
	create_debug_ui()

	# Localizar todas as estações de reparo na cena
	var left_stations: Array = []
	var right_stations: Array = []
	
	# Busca tanto do grupo quanto de $Stations
	var found_stations: Array = []
	for node in get_tree().get_nodes_in_group("repair_stations"):
		if node is RepairStation and not found_stations.has(node):
			found_stations.append(node)
	
	var stations_node = get_node_or_null("Stations")
	if stations_node:
		for child in stations_node.get_children():
			if child is RepairStation and not found_stations.has(child):
				found_stations.append(child)
				
	for st in found_stations:
		register_station(st)
		if st.global_position.x < 640:
			left_stations.append(st)
		else:
			right_stations.append(st)
				
	setup_minigames(left_stations, right_stations)
	
	var sync_terminals = get_tree().get_nodes_in_group("sync_terminals")
	for sync in sync_terminals:
		sync.sync_exploded.connect(game_over)
		if sync.has_method("set_paused"):
			sync.set_paused(not auto_failures_enabled)

func setup_minigames(left_arr: Array, right_arr: Array) -> void:
	var pairs: Array = []
	var remaining_left: Array = left_arr.duplicate()
	var remaining_right: Array = right_arr.duplicate()
	
	# 1. Emparelha estações com minigame_type idêntico pré-configurado
	var matched_left: Array = []
	for l in remaining_left:
		if l.minigame_type != "":
			for r in remaining_right:
				if r.minigame_type == l.minigame_type:
					pairs.append({"left": l, "right": r, "type": l.minigame_type})
					matched_left.append(l)
					remaining_right.erase(r)
					break
	for l in matched_left:
		remaining_left.erase(l)
	
	# 2. Emparelha as estações restantes
	var mg_types = ["password", "item", "skillcheck", "simon"]
	var assigned_types = []
	var count = min(remaining_left.size(), remaining_right.size())
	for i in range(count):
		assigned_types.append(mg_types[i % mg_types.size()])
	assigned_types.shuffle()
	
	for i in range(count):
		var l = remaining_left[i]
		var r = remaining_right[i]
		var m_type = l.minigame_type if l.minigame_type != "" else (r.minigame_type if r.minigame_type != "" else assigned_types[i])
		pairs.append({"left": l, "right": r, "type": m_type})
	
	var colors = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1), Color(0.4, 1, 0.4), Color(1, 1, 0.4), Color(1, 0.4, 1)]
	colors.shuffle()
	
	for i in range(pairs.size()):
		var p = pairs[i]
		var left_st = p["left"]
		var right_st = p["right"]
		var m_type = p["type"]
		
		var c = colors[i % colors.size()]
		var l_base = left_st.get_node_or_null("Visual/Base")
		if l_base: l_base.modulate = c
		var r_base = right_st.get_node_or_null("Visual/Base")
		if r_base: r_base.modulate = c
		
		left_st.setup_minigame(m_type, "A", right_st)
		right_st.setup_minigame(m_type, "B", left_st)

	if maquina:
		maquina.integrity_changed.connect(_on_maquina_integrity_changed)
		maquina.machine_exploded.connect(_on_maquina_exploded)

	update_hud()

func register_station(station) -> void:
	if not stations.has(station):
		stations.append(station)
		station.station_broken.connect(_on_station_broken)
		station.station_fixed.connect(_on_station_fixed)

func _process(delta: float) -> void:
	if game_finished or get_tree().paused:
		return

	# Contagem regressiva de sobrevivência
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		win_game()

	# Gerador de falhas periódicas (se ativado pelo debug)
	if auto_failures_enabled:
		failure_timer -= delta
		if failure_timer <= 0.0:
			trigger_random_failure()
			failure_timer = randf_range(min_failure_interval, max_failure_interval)

	if _debug_msg_timer > 0.0:
		_debug_msg_timer -= delta
		if _debug_msg_timer <= 0.0 and debug_msg_label:
			debug_msg_label.text = ""

	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		restart_game()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if not game_finished:
			toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				break_simon_terminal(3)
			KEY_F2:
				break_simon_terminal(5)
			KEY_F3:
				break_skillcheck_terminal()
			KEY_F4:
				trigger_random_failure()
			KEY_P:
				toggle_machine_pause()
			KEY_O:
				toggle_auto_failures()
			KEY_1: break_pair(1)
			KEY_2: break_pair(2)
			KEY_3: break_pair(3)
			KEY_4: break_pair(4)
			KEY_5: break_pair(5)
			KEY_8, KEY_KP_8:
				if debug_panel and debug_panel.visible:
					cycle_background(-1)
			KEY_0, KEY_KP_0:
				if debug_panel and debug_panel.visible:
					cycle_background(1)
			KEY_H: toggle_debug_ui()

func toggle_debug_ui() -> void:
	if debug_panel:
		debug_panel.visible = not debug_panel.visible

func create_debug_ui() -> void:
	if not hud: return
	
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	debug_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	debug_panel.offset_left = 12.0
	debug_panel.offset_top = 58.0
	debug_panel.offset_right = 265.0
	debug_panel.offset_bottom = 370.0
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.90)
	style.border_color = Color(0.25, 0.6, 0.9, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	debug_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	debug_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🛠️ DEBUG CONTROLS"
	title.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)
	
	# Botões [1] a [5] para os 5 pares
	var btn_p1 = Button.new()
	btn_p1.text = "[1] Par 1: Geradores (Skillcheck)"
	btn_p1.add_theme_font_size_override("font_size", 11)
	btn_p1.pressed.connect(func(): break_pair(1))
	vbox.add_child(btn_p1)
	
	var btn_p2 = Button.new()
	btn_p2.text = "[2] Par 2: Senha"
	btn_p2.add_theme_font_size_override("font_size", 11)
	btn_p2.pressed.connect(func(): break_pair(2))
	vbox.add_child(btn_p2)
	
	var btn_p3 = Button.new()
	btn_p3.text = "[3] Par 3: Dispensador/Entrega"
	btn_p3.add_theme_font_size_override("font_size", 11)
	btn_p3.pressed.connect(func(): break_pair(3))
	vbox.add_child(btn_p3)
	
	var btn_p4 = Button.new()
	btn_p4.text = "[4] Par 4: Simon Says"
	btn_p4.add_theme_font_size_override("font_size", 11)
	btn_p4.pressed.connect(func(): break_pair(4))
	vbox.add_child(btn_p4)
	
	var btn_p5 = Button.new()
	btn_p5.text = "[5] Par 5: Terminal Urgente"
	btn_p5.add_theme_font_size_override("font_size", 11)
	btn_p5.pressed.connect(func(): break_pair(5))
	vbox.add_child(btn_p5)
	
	# Botão F4: Quebrar Aleatório
	var btn_rand = Button.new()
	btn_rand.text = "[F4] Quebrar Aleatório"
	btn_rand.add_theme_font_size_override("font_size", 11)
	btn_rand.pressed.connect(func(): trigger_random_failure())
	vbox.add_child(btn_rand)
	
	# Botão P: Pausar Máquina
	debug_pause_btn = Button.new()
	debug_pause_btn.text = "[P] Pausar Máquina"
	debug_pause_btn.add_theme_font_size_override("font_size", 11)
	debug_pause_btn.pressed.connect(func(): toggle_machine_pause())
	vbox.add_child(debug_pause_btn)
	
	# Botão O: Parar Falhas Auto
	debug_fail_btn = Button.new()
	debug_fail_btn.text = "[O] Parar Falhas Auto"
	debug_fail_btn.add_theme_font_size_override("font_size", 11)
	debug_fail_btn.pressed.connect(func(): toggle_auto_failures())
	vbox.add_child(debug_fail_btn)
	
	# Botões [8] e [0]: Alternar fundo
	var hbox_bg = HBoxContainer.new()
	hbox_bg.add_theme_constant_override("separation", 4)
	
	var btn_bg_prev = Button.new()
	btn_bg_prev.text = "[8] Fundo Ant."
	btn_bg_prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bg_prev.add_theme_font_size_override("font_size", 10)
	btn_bg_prev.pressed.connect(func(): cycle_background(-1))
	hbox_bg.add_child(btn_bg_prev)
	
	var btn_bg_next = Button.new()
	btn_bg_next.text = "[0] Fundo Próx."
	btn_bg_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bg_next.add_theme_font_size_override("font_size", 10)
	btn_bg_next.pressed.connect(func(): cycle_background(1))
	hbox_bg.add_child(btn_bg_next)
	
	vbox.add_child(hbox_bg)
	
	# Dica teclas
	var hint = Label.new()
	hint.text = "Teclas [1] a [5]: Quebrar pares\n[8] / [0]: Alternar Fundo\nTecla [H]: Ocultar/Mostrar menu"
	hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.8))
	hint.add_theme_font_size_override("font_size", 10)
	vbox.add_child(hint)
	
	# Label feedback
	debug_msg_label = Label.new()
	debug_msg_label.text = ""
	debug_msg_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	debug_msg_label.add_theme_font_size_override("font_size", 10)
	debug_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(debug_msg_label)
	
	hud.add_child(debug_panel)
	_update_debug_ui()

func _update_debug_ui() -> void:
	if debug_pause_btn:
		if is_machine_paused:
			debug_pause_btn.text = "[P] Máquina: PAUSADA"
			debug_pause_btn.modulate = Color(1.0, 0.7, 0.2)
		else:
			debug_pause_btn.text = "[P] Pausar Máquina"
			debug_pause_btn.modulate = Color.WHITE
			
	if debug_fail_btn:
		if not auto_failures_enabled:
			debug_fail_btn.text = "[O] Falhas Auto: PARADAS"
			debug_fail_btn.modulate = Color(1.0, 0.4, 0.4)
		else:
			debug_fail_btn.text = "[O] Parar Falhas Auto"
			debug_fail_btn.modulate = Color.WHITE

func _show_debug_msg(msg: String) -> void:
	if debug_msg_label:
		debug_msg_label.text = msg
		_debug_msg_timer = 3.0

func _load_background_textures() -> void:
	background_textures.clear()
	var bg_dir_path = "res://assets/background"
	var dir = DirAccess.open(bg_dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var file_paths: Array[String] = []
		while file_name != "":
			if not dir.current_is_dir() and not file_name.ends_with(".import"):
				var ext = file_name.get_extension().to_lower()
				if ext in ["png", "jpg", "jpeg", "webp"]:
					file_paths.append(bg_dir_path.path_join(file_name))
			file_name = dir.get_next()
		file_paths.sort()
		for fp in file_paths:
			var tex = load(fp)
			if tex is Texture2D:
				background_textures.append(tex)
	
	if background_textures.is_empty():
		var fallbacks = ["res://assets/background/2.jpg", "res://assets/background/1.png", "res://assets/background/3.png"]
		for p in fallbacks:
			if ResourceLoader.exists(p):
				var tex = load(p)
				if tex is Texture2D:
					background_textures.append(tex)

	# Fundo 2.jpg como oficial padrão fixo
	for i in range(background_textures.size()):
		if "2.jpg" in background_textures[i].resource_path:
			current_bg_index = i
			break

func cycle_background(dir_step: int) -> void:
	# Função estritamente acoplada ao debug menu
	if not (debug_panel and debug_panel.visible):
		return
	if background_textures.is_empty():
		_load_background_textures()
	if background_textures.is_empty():
		return
	
	current_bg_index = (current_bg_index + dir_step) % background_textures.size()
	if current_bg_index < 0:
		current_bg_index += background_textures.size()
	
	var chosen_tex = background_textures[current_bg_index]
	var bg_p1 = get_node_or_null("Background/Chamber1View/BG_P1") as TextureRect
	var bg_p2 = get_node_or_null("Background/Chamber2View/BG_P2") as TextureRect
	if bg_p1:
		bg_p1.texture = chosen_tex
	if bg_p2:
		bg_p2.texture = chosen_tex
	
	var file_name = chosen_tex.resource_path.get_file()
	_show_debug_msg("🖼️ Fundo: %s (%d/%d)" % [file_name, current_bg_index + 1, background_textures.size()])

func play_start_run_intro() -> void:
	# 1. Toca aleatoriamente um dos 4 áudios de voz (volume moderado/agradável)
	var voice_clips: Array[String] = [
		"res://assets/voice/Keep it 1.mp3",
		"res://assets/voice/Keep it 2.mp3",
		"res://assets/voice/Keep it 3.mp3",
		"res://assets/voice/Keep it 4.mp3"
	]
	var valid_clips: Array[String] = []
	for clip_path in voice_clips:
		if ResourceLoader.exists(clip_path):
			valid_clips.append(clip_path)
	
	if not valid_clips.is_empty():
		var chosen_clip = valid_clips.pick_random()
		var stream = load(chosen_clip)
		if stream is AudioStream:
			var voice_player = AudioStreamPlayer.new()
			voice_player.stream = stream
			voice_player.volume_db = -8.0 # Não muito alto
			voice_player.bus = "Master"
			add_child(voice_player)
			voice_player.play()
			voice_player.finished.connect(func(): voice_player.queue_free())
	
	# 2. Animação de texto em CAPS com fonte estilizada: KEEP IT TOGETHER!!!
	_show_keep_it_together_banner()

func _show_keep_it_together_banner() -> void:
	var font_res = load("res://assets/Xeriko-R9R1A.otf") if ResourceLoader.exists("res://assets/Xeriko-R9R1A.otf") else null
	
	var banner_layer = CanvasLayer.new()
	banner_layer.layer = 15
	add_child(banner_layer)
	
	var center_ctrl = Control.new()
	center_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_layer.add_child(center_ctrl)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_ctrl.add_child(center_container)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.12, 0.92)
	style.border_color = Color(1.0, 0.82, 0.2, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	center_container.add_child(panel)
	
	var label = Label.new()
	label.text = "KEEP IT TOGETHER!!!"
	if font_res:
		label.add_theme_font_override("font", font_res)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	label.add_theme_color_override("font_shadow_color", Color(0.95, 0.35, 0.1, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.06, 0.12, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
	panel.scale = Vector2(0.2, 0.2)
	panel.modulate.a = 0.0
	
	# Animação cinematográfica: Surge com impacto -> para por 1.4s -> sai com fade e zoom
	var intro_tween = create_tween().set_parallel(true)
	intro_tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	
	var seq_tween = create_tween()
	seq_tween.tween_interval(0.26)
	seq_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
	seq_tween.tween_interval(1.4)
	
	var out_tween = seq_tween.parallel()
	out_tween.tween_property(panel, "scale", Vector2(1.25, 1.25), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	
	seq_tween.tween_callback(func(): banner_layer.queue_free())

func break_pair(pair_num: int) -> void:
	match pair_num:
		1:
			break_skillcheck_terminal()
		2:
			break_password_terminal()
		3:
			break_item_terminal()
		4:
			break_simon_terminal(3)
		5:
			break_sync_terminal()
		_:
			_show_debug_msg("Par %d desconhecido!" % pair_num)

func break_simon_terminal(n_iterations: int = 3) -> void:
	var count = 0
	for st in stations:
		if st.minigame_type == "simon":
			st.break_down(n_iterations)
			count += 1
	if count > 0:
		_show_debug_msg("Par 4 (Simon Says - %d rodadas) quebrado!" % n_iterations)
	else:
		_show_debug_msg("Nenhum terminal Simon encontrado!")

func break_skillcheck_terminal() -> void:
	var count = 0
	for st in stations:
		if st.minigame_type == "skillcheck":
			st.break_down()
			count += 1
	if count > 0:
		_show_debug_msg("Par 1 (Skillcheck / Geradores) quebrado!")
	else:
		_show_debug_msg("Nenhum terminal Skillcheck encontrado!")

func break_password_terminal() -> void:
	var count = 0
	for st in stations:
		if st.minigame_type == "password":
			st.break_down()
			count += 1
	if count > 0:
		_show_debug_msg("Par 2 (Senha) quebrado!")
	else:
		_show_debug_msg("Nenhum terminal Senha encontrado!")

func break_item_terminal() -> void:
	var count = 0
	for st in stations:
		if st.minigame_type == "item":
			st.break_down()
			count += 1
	if count > 0:
		_show_debug_msg("Par 3 (Peças / Entrega) quebrado!")
	else:
		_show_debug_msg("Nenhum terminal de Peças encontrado!")

func break_sync_terminal() -> void:
	var sync_terminals = get_tree().get_nodes_in_group("sync_terminals")
	if sync_terminals.is_empty():
		_show_debug_msg("Nenhum Terminal Urgente encontrado!")
		return
	for sync in sync_terminals:
		if sync.has_method("trigger_sync_event"):
			sync.trigger_sync_event()
	_show_debug_msg("Par 5 (Terminal Urgente) acionado!")

func break_terminal_by_index(idx: int) -> void:
	if idx >= 0 and idx < stations.size():
		var st = stations[idx]
		st.break_down()
		_show_debug_msg("Terminal %d (%s) quebrado!" % [idx + 1, st.station_name])
	else:
		_show_debug_msg("Terminal %d não existe!" % [idx + 1])

func toggle_machine_pause() -> void:
	is_machine_paused = not is_machine_paused
	if maquina and maquina.has_method("set_machine_paused"):
		maquina.set_machine_paused(is_machine_paused)
	_update_debug_ui()
	_show_debug_msg("Máquina: " + ("PAUSADA" if is_machine_paused else "RETOMADA"))

func toggle_auto_failures() -> void:
	auto_failures_enabled = not auto_failures_enabled
	for sync in get_tree().get_nodes_in_group("sync_terminals"):
		if sync.has_method("set_paused"):
			sync.set_paused(not auto_failures_enabled)
	_update_debug_ui()
	_show_debug_msg("Quebra Automática: " + ("LIGADA" if auto_failures_enabled else "PARADA"))

func trigger_random_failure() -> void:
	var available: Array = []
	for s in stations:
		if not s.is_broken():
			available.append(s)

	if available.size() > 0:
		var chosen = available.pick_random()
		chosen.break_down()

func _on_station_broken(_station) -> void:
	if maquina:
		maquina.register_broken_station()
	update_hud()

func _on_station_fixed(_station) -> void:
	if maquina:
		maquina.register_fixed_station()
	update_hud()

func _on_maquina_integrity_changed(_new_integrity: float) -> void:
	update_hud()

func _on_maquina_exploded() -> void:
	game_over()

func update_hud() -> void:
	var minutes: int = int(time_remaining / 60.0)
	var seconds: int = int(time_remaining) % 60
	if timer_label:
		timer_label.text = "⏱️ Manter por: %02d:%02d" % [minutes, seconds]

	if maquina:
		var cur = maquina.current_integrity
		if integrity_label:
			integrity_label.text = "Integridade da Máquina: %d%%" % int(cur)
		if integrity_bar:
			integrity_bar.value = cur
			# Cores na barra conforme integridade
			if cur > 50:
				integrity_bar.modulate = Color(0.2, 0.9, 0.4, 1.0)
			elif cur > 25:
				integrity_bar.modulate = Color(1.0, 0.8, 0.2, 1.0)
			else:
				integrity_bar.modulate = Color(1.0, 0.25, 0.25, 1.0)
		
		if faults_label:
			faults_label.text = "⚠️ Defeitos Ativos: %d" % maquina.broken_stations_count

func win_game() -> void:
	if game_finished: return
	game_finished = true
	get_tree().paused = true
	SoundManager.play(get_tree(), "win")
	if victory_panel:
		victory_panel.visible = true
		var summary = victory_panel.find_child("SummaryLabel", true, false)
		if summary and maquina:
			summary.text = "Vocês mantiveram a máquina operando!\nIntegridade final: %d%%\nParabéns pela cooperação!" % int(maquina.current_integrity)

func game_over() -> void:
	if game_finished: return
	game_finished = true
	get_tree().paused = true
	if game_over_panel:
		game_over_panel.visible = true
		var summary = game_over_panel.find_child("SummaryLabel", true, false)
		if summary:
			var survived = survival_time - time_remaining
			summary.text = "A máquina entrou em colapso catastrófico!\nVocês sobreviveram por %.1f segundos.\nTrabalhem juntos e tentem novamente!" % survived

func _setup_pause_menu() -> void:
	if not pause_panel: return
	
	pause_diff_label = pause_panel.find_child("DiffCurrentLabel", true, false)
	pause_music_slider = pause_panel.find_child("MusicSlider", true, false)
	pause_music_label = pause_panel.find_child("MusicLabel", true, false)
	pause_sfx_slider = pause_panel.find_child("SFXSlider", true, false)
	pause_sfx_label = pause_panel.find_child("SFXLabel", true, false)
	
	if pause_diff_label:
		pause_diff_label.text = "Dificuldade: [ %s ]" % GameSettings.get_difficulty_name().to_upper()
	if pause_music_slider:
		pause_music_slider.value = SoundManager.get_music_volume() * 100.0
		pause_music_slider.value_changed.connect(_on_pause_music_slider_changed)
		_update_pause_music_label(pause_music_slider.value)
	if pause_sfx_slider:
		pause_sfx_slider.value = SoundManager.get_sfx_volume() * 100.0
		pause_sfx_slider.value_changed.connect(_on_pause_sfx_slider_changed)
		_update_pause_sfx_label(pause_sfx_slider.value)

func _on_pause_music_slider_changed(val: float) -> void:
	SoundManager.set_music_volume(val / 100.0)
	_update_pause_music_label(val)

func _update_pause_music_label(val: float) -> void:
	if pause_music_label:
		pause_music_label.text = "Música: %d%%" % int(val)

func _on_pause_sfx_slider_changed(val: float) -> void:
	SoundManager.set_sfx_volume(val / 100.0)
	_update_pause_sfx_label(val)

func _update_pause_sfx_label(val: float) -> void:
	if pause_sfx_label:
		pause_sfx_label.text = "Efeitos (SFX): %d%%" % int(val)

func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	if pause_panel:
		pause_panel.visible = new_pause_state
		if new_pause_state:
			if pause_diff_label:
				pause_diff_label.text = "Dificuldade: [ %s ]" % GameSettings.get_difficulty_name().to_upper()
			if pause_music_slider:
				pause_music_slider.value = SoundManager.get_music_volume() * 100.0
				_update_pause_music_label(pause_music_slider.value)
			if pause_sfx_slider:
				pause_sfx_slider.value = SoundManager.get_sfx_volume() * 100.0
				_update_pause_sfx_label(pause_sfx_slider.value)

func restart_game() -> void:
	get_tree().paused = false
	SoundManager.play(get_tree(), "click")
	get_tree().reload_current_scene()

func _on_restart_button_pressed() -> void:
	restart_game()

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	SoundManager.play(get_tree(), "click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
