extends Node2D
class_name GameManager

@export var survival_time: float = 60.0 # Segundos necessários para vencer a Fase 1
@export var min_failure_interval: float = 4.0
@export var max_failure_interval: float = 6.5

var time_remaining: float = 60.0
var game_finished: bool = false
var failure_timer: float = 3.0 # Primeiro defeito surge aos 3s
var stations: Array[RepairStation] = []

@onready var maquina: CentralMaquina = $"Máquina"
@onready var hud: CanvasLayer = $HUD
@onready var timer_label: Label = $HUD/TopBar/MarginContainer/HBoxContainer/TimeContainer/TimerLabel
@onready var integrity_label: Label = $HUD/TopBar/MarginContainer/HBoxContainer/IntegrityContainer/IntegrityLabel
@onready var integrity_bar: ProgressBar = $HUD/TopBar/MarginContainer/HBoxContainer/IntegrityContainer/IntegrityBar
@onready var faults_label: Label = $HUD/TopBar/MarginContainer/HBoxContainer/FaultsContainer/FaultsLabel
@onready var victory_panel: PanelContainer = $HUD/VictoryPanel
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel

func _ready() -> void:
	add_to_group("game_manager")
	time_remaining = survival_time
	
	if victory_panel:
		victory_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false

	# Localizar todas as estações de reparo na cena
	for child in get_tree().get_nodes_in_group("repair_stations"):
		if child is RepairStation:
			register_station(child)

	if maquina:
		maquina.integrity_changed.connect(_on_maquina_integrity_changed)
		maquina.machine_exploded.connect(_on_maquina_exploded)

	update_hud()

func register_station(station: RepairStation) -> void:
	stations.append(station)
	station.station_broken.connect(_on_station_broken)
	station.station_fixed.connect(_on_station_fixed)

func _process(delta: float) -> void:
	if game_finished:
		if Input.is_key_pressed(KEY_R) or Input.is_action_just_pressed("restart"):
			restart_game()
		return

	# Reinício rápido a qualquer momento com R
	if Input.is_key_pressed(KEY_R) or Input.is_action_just_pressed("restart"):
		restart_game()
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

func trigger_random_failure() -> void:
	var available: Array[RepairStation] = []
	for s in stations:
		if not s.is_broken():
			available.append(s)

	if available.size() > 0:
		var chosen = available.pick_random()
		chosen.break_down()

func _on_station_broken(_station: RepairStation) -> void:
	if maquina:
		maquina.register_broken_station()
	update_hud()

func _on_station_fixed(_station: RepairStation) -> void:
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
	game_finished = true
	SoundManager.play(get_tree(), "win")
	if victory_panel:
		victory_panel.visible = true
		var summary = victory_panel.get_node_or_null("VBox/SummaryLabel")
		if summary and maquina:
			summary.text = "Vocês mantiveram a máquina operando!\nIntegridade final: %d%%\nParabéns pela cooperação!" % int(maquina.current_integrity)

func game_over() -> void:
	game_finished = true
	if game_over_panel:
		game_over_panel.visible = true
		var summary = game_over_panel.get_node_or_null("VBox/SummaryLabel")
		if summary:
			var survived = survival_time - time_remaining
			summary.text = "A máquina entrou em colapso catastrófico!\nVocês sobreviveram por %.1f segundos.\nTrabalhem juntos e tentem novamente!" % survived

func restart_game() -> void:
	SoundManager.play(get_tree(), "click")
	get_tree().reload_current_scene()

func _on_restart_button_pressed() -> void:
	restart_game()
