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
	var mg_types = ["password", "item", "skillcheck", "simon"]
	var assigned_types = []
	var count = min(left_arr.size(), right_arr.size())
	for i in range(count):
		assigned_types.append(mg_types[i % mg_types.size()])
	assigned_types.shuffle()
	
	var colors = [Color(1, 0.4, 0.4), Color(0.4, 0.4, 1), Color(0.4, 1, 0.4), Color(1, 1, 0.4), Color(1, 0.4, 1)]
	colors.shuffle()
	
	left_arr.shuffle()
	right_arr.shuffle()
	
	for i in range(count):
		var left_st = left_arr[i]
		var right_st = right_arr[i]
		var m_type = assigned_types[i]
		
		var c = colors[i % colors.size()]
		var l_base = left_st.get_node_or_null("Visual/Base")
		if l_base is ColorRect: l_base.color = c
		var r_base = right_st.get_node_or_null("Visual/Base")
		if r_base is ColorRect: r_base.color = c
		
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

	# Gerador de falhas periódicas
	failure_timer -= delta
	if failure_timer <= 0.0:
		trigger_random_failure()
		failure_timer = randf_range(min_failure_interval, max_failure_interval)

	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		restart_game()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if not game_finished:
			toggle_pause()

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
