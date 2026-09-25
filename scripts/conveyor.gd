extends Node2D

var item_inside: bool = false
var transfer_timer: float = 0.0
var transferring: bool = false

@onready var p1_area: Area2D = $P1_Area
@onready var p2_area: Area2D = $P2_Area
@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

func _ready() -> void:
	update_visual()

func _process(delta: float) -> void:
	if transferring:
		transfer_timer -= delta
		visual.color = Color(0.8, 0.8, 0.2) # Amarelo piscando durante transf
		label.text = "Transferindo..."
		if transfer_timer <= 0.0:
			transferring = false
			item_inside = true
			SoundManager.play(get_tree(), "powerup", 0.3)
			update_visual()

func update_visual() -> void:
	if item_inside:
		visual.color = Color(0.2, 0.8, 0.2)
		label.text = "Item Pronto!"
	else:
		visual.color = Color(0.3, 0.3, 0.4)
		label.text = "Vazio"

func try_insert_item(player_id: int) -> bool:
	if not transferring and not item_inside and player_id == 1:
		transferring = true
		transfer_timer = 2.0
		SoundManager.play(get_tree(), "click", 0.5)
		return true
	return false

func try_take_item(player_id: int) -> bool:
	if item_inside and player_id == 2:
		item_inside = false
		update_visual()
		SoundManager.play(get_tree(), "click", 0.5)
		return true
	return false
