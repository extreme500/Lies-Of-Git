extends Control

@onready var branch_tip_label: Label = $VBox/TipPanel/Margin/TipLabel

func _ready() -> void:
	if branch_tip_label:
		branch_tip_label.text = "💡 DICA: Para jogar cada protótipo, feche o Godot ou abra o terminal e digite: git checkout <nome-da-branch>. O Godot recarregará o projeto automaticamente com o jogo completo!"
