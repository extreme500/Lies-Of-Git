extends Control

@onready var compjam_container: Control = $CompJamContainer
@onready var title_container: Control = $TitleContainer
@onready var menu_buttons: Control = $MenuButtonsContainer
@onready var settings_panel: Control = $SettingsModal
@onready var diff_btn: Button = $MenuButtonsContainer/DifficultyBtn
@onready var diff_desc: Label = $MenuButtonsContainer/DifficultyDesc
@onready var music_slider: HSlider = $SettingsModal/VBox/MusicContainer/MusicSlider
@onready var music_val_label: Label = $SettingsModal/VBox/MusicContainer/MusicValLabel
@onready var sfx_slider: HSlider = $SettingsModal/VBox/SFXContainer/SFXSlider
@onready var sfx_val_label: Label = $SettingsModal/VBox/SFXContainer/SFXValLabel

var intro_done: bool = false
var intro_tween: Tween = null

func _ready() -> void:
	SoundManager.play_music(get_tree(), "res://assets/Ost/loop menu basicão.mp3")
	
	if settings_panel: settings_panel.visible = false
	update_difficulty_display()
	init_settings_sliders()
	start_intro_animation()

func start_intro_animation() -> void:
	compjam_container.modulate.a = 0.0
	compjam_container.position.y = 300.0
	
	title_container.modulate.a = 0.0
	title_container.position.y = 120.0
	
	menu_buttons.modulate.a = 0.0
	menu_buttons.position.y = 340.0
	
	intro_tween = create_tween()
	intro_tween.set_parallel(false)
	
	# 1. Sobe "COMPJAM 2026" com fade-in
	intro_tween.parallel().tween_property(compjam_container, "position:y", 250.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro_tween.parallel().tween_property(compjam_container, "modulate:a", 1.0, 0.9)
	
	# 2. Segura por um breve momento
	intro_tween.tween_interval(0.8)
	
	# 3. Fade-out e sobe levemente
	intro_tween.parallel().tween_property(compjam_container, "position:y", 210.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	intro_tween.parallel().tween_property(compjam_container, "modulate:a", 0.0, 0.6)
	
	# 4. Sobe "KEEP IT TOGETHER!!" com fade-in
	intro_tween.parallel().tween_property(title_container, "position:y", 70.0, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.parallel().tween_property(title_container, "modulate:a", 1.0, 0.8)
	
	# 5. Revela botões do menu
	intro_tween.parallel().tween_property(menu_buttons, "position:y", 280.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro_tween.parallel().tween_property(menu_buttons, "modulate:a", 1.0, 0.7)
	
	intro_tween.finished.connect(func(): intro_done = true)

func skip_intro() -> void:
	if intro_done: return
	intro_done = true
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()
	compjam_container.modulate.a = 0.0
	title_container.modulate.a = 1.0
	title_container.position.y = 70.0
	menu_buttons.modulate.a = 1.0
	menu_buttons.position.y = 280.0

func _gui_input(event: InputEvent) -> void:
	if not intro_done and (event is InputEventMouseButton or event is InputEventKey):
		if event.is_pressed():
			skip_intro()

func _unhandled_input(event: InputEvent) -> void:
	if not intro_done and (event is InputEventKey or event is InputEventMouseButton):
		if event.is_pressed():
			skip_intro()

func update_difficulty_display() -> void:
	if diff_btn:
		diff_btn.text = "⚔ DIFICULDADE: [ " + GameSettings.get_difficulty_name().to_upper() + " ]"
	if diff_desc:
		diff_desc.text = GameSettings.get_difficulty_description()

func init_settings_sliders() -> void:
	if music_slider:
		music_slider.value = SoundManager.get_music_volume() * 100.0
		_on_music_slider_changed(music_slider.value)
		music_slider.value_changed.connect(_on_music_slider_changed)
		
	if sfx_slider:
		sfx_slider.value = SoundManager.get_sfx_volume() * 100.0
		_on_sfx_slider_changed(sfx_slider.value)
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _on_music_slider_changed(val: float) -> void:
	var norm = val / 100.0
	SoundManager.set_music_volume(norm)
	if music_val_label:
		music_val_label.text = "%d%%" % int(val)

func _on_sfx_slider_changed(val: float) -> void:
	var norm = val / 100.0
	SoundManager.set_sfx_volume(norm)
	if sfx_val_label:
		sfx_val_label.text = "%d%%" % int(val)

func _on_play_btn_pressed() -> void:
	SoundManager.play(get_tree(), "powerup", 0.1)
	SoundManager.play_bgm(get_tree(), "res://assets/Ost/MELHOR loop fundo principal.mp3", -15.0)
	get_tree().change_scene_to_file("res://scenes/main_v2.tscn")


func _on_difficulty_btn_pressed() -> void:
	SoundManager.play(get_tree(), "click", 0.15)
	GameSettings.cycle_difficulty()
	update_difficulty_display()

func _on_settings_btn_pressed() -> void:
	SoundManager.play(get_tree(), "click", 0.1)
	if settings_panel:
		settings_panel.visible = true

func _on_close_settings_btn_pressed() -> void:
	SoundManager.play(get_tree(), "click", 0.1)
	if settings_panel:
		settings_panel.visible = false

func _on_quit_btn_pressed() -> void:
	SoundManager.play(get_tree(), "lose", 0.1)
	get_tree().quit()
