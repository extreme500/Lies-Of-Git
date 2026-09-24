extends Control
class_name RPGCombatant

signal died(combatant: RPGCombatant)

@export var combatant_name: String = "Guerreiro"
@export var max_hp: int = 100
@export var max_mp: int = 40
@export var base_attack: int = 25
@export var is_enemy: bool = false

var current_hp: int = 100
var current_mp: int = 40
var is_defending: bool = false
var is_alive: bool = true

@onready var name_label: Label = $VBox/NameLabel
@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var hp_label: Label = $VBox/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $VBox/MPBar
@onready var mp_label: Label = $VBox/MPBar/MPLabel
@onready var visual_box: PanelContainer = $VBox/VisualContainer
@onready var highlight: ColorRect = $VBox/Highlight

var default_pos: Vector2

func _ready() -> void:
	default_pos = position
	current_hp = max_hp
	current_mp = max_mp
	if highlight:
		highlight.visible = false
	update_ui()

func update_ui() -> void:
	if name_label:
		name_label.text = combatant_name
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_label:
		hp_label.text = "%d/%d" % [current_hp, max_hp]
	if mp_bar:
		mp_bar.visible = (max_mp > 0)
		mp_bar.max_value = max_mp
		mp_bar.value = current_mp
	if mp_label and max_mp > 0:
		mp_label.text = "%d/%d" % [current_mp, max_mp]

func take_damage(amount: int) -> int:
	var final_damage = amount
	if is_defending:
		final_damage = int(final_damage * 0.5)
		is_defending = false

	current_hp = max(0, current_hp - final_damage)
	update_ui()
	shake_reaction()

	if current_hp <= 0:
		is_alive = false
		modulate = Color(0.4, 0.4, 0.4, 0.6)
		died.emit(self)

	return final_damage

func heal(amount: int) -> int:
	var prev_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	update_ui()
	
	var tween = create_tween()
	modulate = Color(0.5, 1.2, 0.5, 1.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	return current_hp - prev_hp

func spend_mp(cost: int) -> bool:
	if current_mp >= cost:
		current_mp -= cost
		update_ui()
		return true
	return false

func regain_mp(amount: int) -> void:
	current_mp = min(max_mp, current_mp + amount)
	update_ui()

func set_defending(active: bool) -> void:
	is_defending = active
	if highlight:
		highlight.color = Color(0.3, 0.8, 1.0, 0.4)
		highlight.visible = active

func set_active_turn(active: bool) -> void:
	if highlight:
		highlight.color = Color(1.0, 0.9, 0.3, 0.5)
		highlight.visible = active

func step_forward() -> void:
	var offset = Vector2(-25 if is_enemy else 25, 0)
	var tween = create_tween()
	tween.tween_property(self, "position", default_pos + offset, 0.15)
	tween.tween_property(self, "position", default_pos, 0.15)

func shake_reaction() -> void:
	var tween = create_tween()
	for i in range(3):
		var rand_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
		tween.tween_property(self, "position", default_pos + rand_offset, 0.04)
	tween.tween_property(self, "position", default_pos, 0.05)
