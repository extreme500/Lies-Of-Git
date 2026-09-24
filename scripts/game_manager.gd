extends Node2D

var coins: int = 0
var deaths: int = 0
var time_elapsed: float = 0.0
var game_won: bool = false

@onready var coins_label: Label = $HUD/MarginContainer/VBoxContainer/CoinsLabel
@onready var deaths_label: Label = $HUD/MarginContainer/VBoxContainer/DeathsLabel
@onready var timer_label: Label = $HUD/MarginContainer/VBoxContainer/TimerLabel
@onready var victory_panel: PanelContainer = $HUD/VictoryPanel

func _ready() -> void:
	add_to_group("game_manager")
	if victory_panel:
		victory_panel.visible = false
	update_hud()

func _process(delta: float) -> void:
	if not game_won:
		time_elapsed += delta
		var minutes: int = int(time_elapsed / 60.0)
		var seconds: int = int(time_elapsed) % 60
		if timer_label:
			timer_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

	# Reiniciar fase a qualquer momento com R
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func add_coin() -> void:
	coins += 1
	update_hud()

func register_death() -> void:
	deaths += 1
	update_hud()

func update_hud() -> void:
	if coins_label:
		coins_label.text = "Moedas: %d" % coins
	if deaths_label:
		deaths_label.text = "Mortes: %d" % deaths

func win_game() -> void:
	game_won = true
	if victory_panel:
		victory_panel.visible = true
		var summary = victory_panel.get_node_or_null("VBox/SummaryLabel")
		if summary:
			summary.text = "Você concluiu a fase!\nMoedas coletadas: %d\nMortes: %d\nTempo total: %.1fs" % [coins, deaths, time_elapsed]

func _on_restart_button_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	get_tree().reload_current_scene()
