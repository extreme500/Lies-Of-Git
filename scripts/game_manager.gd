extends Node2D
class_name GameManager

@export var survival_time: float = 60.0 # Segundos necessários para vencer a Fase 1
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

@onready var hud: CanvasLayer = $HUD
@onready var timer_label: Label = $HUD/TopBar/MarginContainer/HBoxContainer/TimeContainer/TimerLabel
@onready var integrity_label: Label = $HUD/TopBar/MarginContainer/HBoxContainer/IntegrityContainer/IntegrityLabel
@onready var integrity_bar: ProgressBar = $HUD/TopBar/MarginContainer/HBoxContainer/IntegrityContainer/IntegrityBar
@onready var faults_label: Label = $HUD/TopBar/MarginContainer/HBoxContainer/FaultsContainer/FaultsLabel
@onready var victory_panel: PanelContainer = $HUD/VictoryPanel
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var pause_panel: PanelContainer = $HUD/PausePanel

func _ready() -> void:
	add_to_group("game_manager")
	time_remaining = survival_time
	
	process_mode = Node.PROCESS_MODE_ALWAYS # GameManager keeps running for inputs
	
	# Localizar máquina principal de forma segura
	maquina = get_node_or_null("Máquina") as CentralMaquina
	if not maquina:
		maquina = get_node_or_null("Maquina") as CentralMaquina
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

	create_debug_ui()

	# Localizar todas as estações de reparo na cena
	var left_stations: Array = []
	var right_stations: Array = []
	for child in get_tree().get_nodes_in_group("repair_stations"):
		if child is RepairStation:
			register_station(child)
			if child.global_position.x < 640:
				left_stations.append(child)
			else:
				right_stations.append(child)
				
	setup_minigames(left_stations, right_stations)
	
	var sync_terminals = get_tree().get_nodes_in_group("sync_terminals")
	for sync in sync_terminals:
		sync.sync_exploded.connect(game_over)

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
			KEY_1: break_terminal_by_index(0)
			KEY_2: break_terminal_by_index(1)
			KEY_3: break_terminal_by_index(2)
			KEY_4: break_terminal_by_index(3)
			KEY_5: break_terminal_by_index(4)
			KEY_6: break_terminal_by_index(5)
			KEY_7: break_terminal_by_index(6)
			KEY_8: break_terminal_by_index(7)

func create_debug_ui() -> void:
	if not hud: return
	
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	debug_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	debug_panel.offset_left = 12.0
	debug_panel.offset_top = 58.0
	debug_panel.offset_right = 265.0
	debug_panel.offset_bottom = 295.0
	
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
	
	# Botão F1: Quebrar Simon (3 iter)
	var btn_simon3 = Button.new()
	btn_simon3.text = "[F1] Estragar Simon (3 iter)"
	btn_simon3.add_theme_font_size_override("font_size", 11)
	btn_simon3.pressed.connect(func(): break_simon_terminal(3))
	vbox.add_child(btn_simon3)
	
	# Botão F2: Quebrar Simon (5 iter)
	var btn_simon5 = Button.new()
	btn_simon5.text = "[F2] Estragar Simon (5 iter)"
	btn_simon5.add_theme_font_size_override("font_size", 11)
	btn_simon5.pressed.connect(func(): break_simon_terminal(5))
	vbox.add_child(btn_simon5)
	
	# Botão F3: Quebrar Skillcheck
	var btn_sc = Button.new()
	btn_sc.text = "[F3] Estragar Skillcheck"
	btn_sc.add_theme_font_size_override("font_size", 11)
	btn_sc.pressed.connect(func(): break_skillcheck_terminal())
	vbox.add_child(btn_sc)
	
	# Botão F4: Quebrar Aleatório
	var btn_rand = Button.new()
	btn_rand.text = "[F4] Estragar Aleatório"
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
	
	# Dica teclas 1 a 8
	var hint = Label.new()
	hint.text = "Teclas [1] a [8]: Estragar terminal"
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

func break_simon_terminal(n_iterations: int = 3) -> void:
	var simon_found = false
	for st in stations:
		if st.minigame_type == "simon":
			simon_found = true
			st.break_down(n_iterations)
			_show_debug_msg("Simon quebrado (%d rodadas)!" % n_iterations)
			break
	if not simon_found:
		_show_debug_msg("Nenhum terminal Simon encontrado!")

func break_skillcheck_terminal() -> void:
	var sc_found = false
	for st in stations:
		if st.minigame_type == "skillcheck":
			sc_found = true
			st.break_down()
			_show_debug_msg("Skillcheck quebrado!")
			break
	if not sc_found:
		_show_debug_msg("Nenhum terminal Skillcheck encontrado!")

func break_password_terminal() -> void:
	for st in stations:
		if st.minigame_type == "password":
			st.break_down()
			_show_debug_msg("Senha quebrada!")
			break

func break_terminal_by_index(idx: int) -> void:
	if idx >= 0 and idx < stations.size():
		var st = stations[idx]
		st.break_down()
		_show_debug_msg("Terminal %d (%s) quebrado!" % [idx + 1, st.station_name])
	else:
		_show_debug_msg("Terminal %d não existe!" % [idx + 1])

func toggle_machine_pause() -> void:
	is_machine_paused = not is_machine_paused
	if maquina:
		maquina.set_machine_paused(is_machine_paused)
	_update_debug_ui()
	_show_debug_msg("Máquina: " + ("PAUSADA" if is_machine_paused else "RETOMADA"))

func toggle_auto_failures() -> void:
	auto_failures_enabled = not auto_failures_enabled
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
		timer_label.text = "FUDEU!  Manter por: %02d:%02d" % [minutes, seconds]

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
		var summary = victory_panel.get_node_or_null("VBox/SummaryLabel")
		if summary and maquina:
			summary.text = "Vocês mantiveram a máquina operando!\nIntegridade final: %d%%\nParabéns pela cooperação!" % int(maquina.current_integrity)

func game_over() -> void:
	if game_finished: return
	game_finished = true
	get_tree().paused = true
	if game_over_panel:
		game_over_panel.visible = true
		var summary = game_over_panel.get_node_or_null("VBox/SummaryLabel")
		if summary:
			var survived = survival_time - time_remaining
			summary.text = "A máquina entrou em colapso catastrófico!\nVocês sobreviveram por %.1f segundos.\nTrabalhem juntos e tentem novamente!" % survived

func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	if pause_panel:
		pause_panel.visible = new_pause_state

func restart_game() -> void:
	get_tree().paused = false
	SoundManager.play(get_tree(), "click")
	get_tree().reload_current_scene()

func _on_restart_button_pressed() -> void:
	restart_game()

func _on_resume_button_pressed() -> void:
	toggle_pause()
