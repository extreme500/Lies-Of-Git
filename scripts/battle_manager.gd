extends Control
class_name BattleManager

enum BattleState { START, HERO_SELECT, ANIMATING, ENEMY_TURN, VICTORY, DEFEAT }

var state: BattleState = BattleState.START
var active_hero_index: int = 0

@onready var hero_warrior: RPGCombatant = $BattleArea/Heroes/Warrior
@onready var hero_mage: RPGCombatant = $BattleArea/Heroes/Mage
@onready var enemy_boss: RPGCombatant = $BattleArea/Enemies/Boss
@onready var enemy_minion: RPGCombatant = $BattleArea/Enemies/Minion

@onready var action_panel: PanelContainer = $ActionPanel
@onready var current_hero_label: Label = $ActionPanel/MarginContainer/HBox/VBoxInfo/CurrentHeroLabel
@onready var btn_attack: Button = $ActionPanel/MarginContainer/HBox/GridActions/BtnAttack
@onready var btn_skill: Button = $ActionPanel/MarginContainer/HBox/GridActions/BtnSkill
@onready var btn_heal: Button = $ActionPanel/MarginContainer/HBox/GridActions/BtnHeal
@onready var btn_defend: Button = $ActionPanel/MarginContainer/HBox/GridActions/BtnDefend

@onready var target_panel: PanelContainer = $TargetPanel
@onready var target_title: Label = $TargetPanel/MarginContainer/VBox/Title
@onready var btn_target_boss: Button = $TargetPanel/MarginContainer/VBox/TargetsGrid/BtnTargetBoss
@onready var btn_target_minion: Button = $TargetPanel/MarginContainer/VBox/TargetsGrid/BtnTargetMinion
@onready var btn_target_warrior: Button = $TargetPanel/MarginContainer/VBox/TargetsGrid/BtnTargetWarrior
@onready var btn_target_mage: Button = $TargetPanel/MarginContainer/VBox/TargetsGrid/BtnTargetMage
@onready var btn_cancel_target: Button = $TargetPanel/MarginContainer/VBox/BtnCancelTarget

@onready var log_label: RichTextLabel = $LogPanel/MarginContainer/LogLabel
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title: Label = $ResultPanel/VBox/ResultTitle
@onready var result_desc: Label = $ResultPanel/VBox/ResultDesc

var selected_action: String = "" # "attack", "skill", "heal", "defend"
var heroes: Array[RPGCombatant] = []
var enemies: Array[RPGCombatant] = []

func _ready() -> void:
	heroes = [hero_warrior, hero_mage]
	enemies = [enemy_boss, enemy_minion]
	if result_panel:
		result_panel.visible = false
	if target_panel:
		target_panel.visible = false

	log_message("[color=#89b4fa]A batalha começou! Prepare-se![/color]")
	start_round()

func start_round() -> void:
	if check_battle_end():
		return

	# Selecionar o primeiro herói vivo
	active_hero_index = 0
	while active_hero_index < heroes.size() and not heroes[active_hero_index].is_alive:
		active_hero_index += 1

	if active_hero_index < heroes.size():
		prompt_hero_turn()
	else:
		start_enemy_turn()

func prompt_hero_turn() -> void:
	var hero = heroes[active_hero_index]
	state = BattleState.HERO_SELECT
	action_panel.visible = true
	target_panel.visible = false

	for h in heroes:
		h.set_active_turn(h == hero)

	if current_hero_label:
		current_hero_label.text = "Vez de: %s (HP: %d | MP: %d)" % [hero.combatant_name, hero.current_hp, hero.current_mp]

	# Atualizar textos dos botões de acordo com o herói
	if hero == hero_warrior:
		btn_skill.text = "Golpe Brutal (15 MP)"
		btn_heal.text = "Curativo (10 MP)"
	else:
		btn_skill.text = "Bola de Fogo (20 MP)"
		btn_heal.text = "Luz Curativa (15 MP)"

func _on_attack_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	selected_action = "attack"
	show_target_selection(false)

func _on_skill_pressed() -> void:
	var hero = heroes[active_hero_index]
	var cost = 15 if hero == hero_warrior else 20
	if hero.current_mp < cost:
		log_message("[color=#f38ba8]MP insuficiente para usar Habilidade![/color]")
		SoundManager.play(get_tree(), "hit")
		return
	SoundManager.play(get_tree(), "click")
	selected_action = "skill"
	show_target_selection(false)

func _on_heal_pressed() -> void:
	var hero = heroes[active_hero_index]
	var cost = 10 if hero == hero_warrior else 15
	if hero.current_mp < cost:
		log_message("[color=#f38ba8]MP insuficiente para Curar![/color]")
		SoundManager.play(get_tree(), "hit")
		return
	SoundManager.play(get_tree(), "click")
	selected_action = "heal"
	show_target_selection(true)

func _on_defend_pressed() -> void:
	var hero = heroes[active_hero_index]
	action_panel.visible = false
	state = BattleState.ANIMATING
	hero.set_defending(true)
	hero.regain_mp(8)
	SoundManager.play(get_tree(), "coin")
	var text_pos = hero.global_position - $BattleArea.global_position + Vector2(30, -10)
	spawn_damage_text(text_pos, "DEFENDENDO!", Color(0.4, 0.8, 1.0))
	log_message("[color=#89b4fa]%s assumiu postura defensiva e recuperou 8 MP![/color]" % hero.combatant_name)

	await get_tree().create_timer(0.8).timeout
	next_hero_turn()

func show_target_selection(is_healing: bool = false) -> void:
	action_panel.visible = false
	target_panel.visible = true

	if is_healing:
		if target_title:
			target_title.text = "Selecione quem deseja Curar:"
		btn_target_boss.visible = false
		btn_target_minion.visible = false
		btn_target_warrior.visible = hero_warrior.is_alive
		btn_target_mage.visible = hero_mage.is_alive
		btn_target_warrior.text = "🛡️ Valente (%d/%d HP)" % [hero_warrior.current_hp, hero_warrior.max_hp]
		btn_target_mage.text = "🔮 Luna (%d/%d HP)" % [hero_mage.current_hp, hero_mage.max_hp]
	else:
		if target_title:
			target_title.text = "Selecione o Inimigo Alvo:"
		btn_target_boss.visible = enemy_boss.is_alive
		btn_target_minion.visible = enemy_minion.is_alive
		btn_target_warrior.visible = false
		btn_target_mage.visible = false

func _on_target_boss_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	_on_target_selected(enemy_boss)

func _on_target_minion_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	_on_target_selected(enemy_minion)

func _on_target_warrior_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	_on_target_selected(hero_warrior)

func _on_target_mage_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	_on_target_selected(hero_mage)

func _on_cancel_target_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	target_panel.visible = false
	action_panel.visible = true
	state = BattleState.HERO_SELECT

func _on_target_selected(target: RPGCombatant) -> void:
	if target == null or not is_instance_valid(target) or not target.is_alive:
		log_message("[color=#f38ba8]Alvo inválido ou derrotado![/color]")
		target_panel.visible = false
		action_panel.visible = true
		state = BattleState.HERO_SELECT
		return
	target_panel.visible = false
	execute_hero_action(target)

func execute_hero_action(target: RPGCombatant) -> void:
	state = BattleState.ANIMATING
	var hero = heroes[active_hero_index]
	hero.step_forward()

	var text_pos = target.global_position - $BattleArea.global_position + Vector2(40, 20)

	if selected_action == "attack":
		SoundManager.play(get_tree(), "hit")
		var dmg = hero.base_attack + randi_range(-3, 6)
		var actual_dmg = target.take_damage(dmg)
		hero.regain_mp(5)
		spawn_damage_text(text_pos, "-%d" % actual_dmg, Color(1, 0.4, 0.4))
		log_message("%s atacou %s causando [b]%d[/b] de dano!" % [hero.combatant_name, target.combatant_name, actual_dmg])

	elif selected_action == "skill":
		if hero == hero_warrior:
			hero.spend_mp(15)
			SoundManager.play(get_tree(), "hit", 0.3)
			var dmg = 45 + randi_range(-4, 10)
			var actual_dmg = target.take_damage(dmg)
			spawn_damage_text(text_pos, "-%d CRÍTICO!" % actual_dmg, Color(1, 0.2, 0.2))
			log_message("[color=#f38ba8]%s desferiu GOLPE BRUTAL em %s causando %d de dano![/color]" % [hero.combatant_name, target.combatant_name, actual_dmg])
		else:
			hero.spend_mp(20)
			SoundManager.play(get_tree(), "shoot", 0.2)
			var dmg = 50 + randi_range(-2, 12)
			var actual_dmg = target.take_damage(dmg)
			spawn_damage_text(text_pos, "-%d FOGO!" % actual_dmg, Color(1, 0.6, 0.1))
			log_message("[color=#fab387]%s conjurou BOLA DE FOGO em %s causando %d de dano![/color]" % [hero.combatant_name, target.combatant_name, actual_dmg])

	elif selected_action == "heal":
		var cost = 10 if hero == hero_warrior else 15
		hero.spend_mp(cost)
		SoundManager.play(get_tree(), "powerup")
		var heal_amt = 35 if hero == hero_warrior else 55
		var recovered = target.heal(heal_amt)
		var heal_text_pos = target.global_position - $BattleArea.global_position + Vector2(40, -10)
		spawn_damage_text(heal_text_pos, "+%d HP" % recovered, Color(0.4, 1.0, 0.4))
		log_message("[color=#a6e3a1]%s curou %s em %d HP![/color]" % [hero.combatant_name, target.combatant_name, recovered])

	await get_tree().create_timer(1.0).timeout
	if not check_battle_end():
		next_hero_turn()

func next_hero_turn() -> void:
	active_hero_index += 1
	# Procurar próximo herói vivo
	while active_hero_index < heroes.size() and not heroes[active_hero_index].is_alive:
		active_hero_index += 1

	if active_hero_index < heroes.size():
		prompt_hero_turn()
	else:
		# Vez dos inimigos
		start_enemy_turn()

func start_enemy_turn() -> void:
	state = BattleState.ENEMY_TURN
	action_panel.visible = false
	target_panel.visible = false
	for h in heroes:
		h.set_active_turn(false)

	log_message("[color=#f38ba8]Vez dos Inimigos...[/color]")
	await get_tree().create_timer(0.6).timeout

	for enemy in enemies:
		if not enemy.is_alive or check_battle_end():
			continue

		# Selecionar alvo vivo
		var alive_heroes: Array[RPGCombatant] = []
		for h in heroes:
			if h.is_alive:
				alive_heroes.append(h)
		if alive_heroes.is_empty():
			break

		var target = alive_heroes.pick_random()
		enemy.step_forward()
		SoundManager.play(get_tree(), "hit")

		var dmg = enemy.base_attack + randi_range(-3, 5)
		var actual_dmg = target.take_damage(dmg)
		var text_pos = target.global_position - $BattleArea.global_position + Vector2(30, 20)
		spawn_damage_text(text_pos, "-%d" % actual_dmg, Color(1, 0.3, 0.3))
		log_message("[color=#f38ba8]%s atacou %s causando %d de dano![/color]" % [enemy.combatant_name, target.combatant_name, actual_dmg])

		await get_tree().create_timer(0.9).timeout

	if not check_battle_end():
		# Novo turno para os heróis
		start_round()

func check_battle_end() -> bool:
	var enemies_alive = false
	for e in enemies:
		if e.is_alive:
			enemies_alive = true
			break

	if not enemies_alive:
		state = BattleState.VICTORY
		action_panel.visible = false
		target_panel.visible = false
		SoundManager.play(get_tree(), "win")
		if result_panel:
			result_panel.visible = true
			result_title.text = "🎉 VITÓRIA HEROICA! 🎉"
			result_title.modulate = Color(0.65, 0.89, 0.63)
			result_desc.text = "Os heróis derrotaram todos os monstros da masmorra!"
		log_message("[b][color=#a6e3a1]Vitória! Todos os inimigos foram derrotados![/color][/b]")
		return true

	var heroes_alive = false
	for h in heroes:
		if h.is_alive:
			heroes_alive = true
			break

	if not heroes_alive:
		state = BattleState.DEFEAT
		action_panel.visible = false
		target_panel.visible = false
		SoundManager.play(get_tree(), "lose")
		if result_panel:
			result_panel.visible = true
			result_title.text = "💀 DERROTA... 💀"
			result_title.modulate = Color(0.95, 0.45, 0.45)
			result_desc.text = "Seu grupo sucumbiu aos monstros. Tente novamente!"
		log_message("[b][color=#f38ba8]Derrota... Todos os heróis caíram em batalha.[/color][/b]")
		return true

	return false

func log_message(text: String) -> void:
	if log_label:
		log_label.append_text(text + "\n")

func spawn_damage_text(pos: Vector2, text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.modulate = color
	label.add_theme_font_size_override("font_size", 20)
	$BattleArea.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y - 35, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _on_restart_pressed() -> void:
	SoundManager.play(get_tree(), "click")
	get_tree().reload_current_scene()
