extends Area2D
class_name Goal2D

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if body is CoopPlayer2D or body.name.begins_with("Player"):
		triggered = true
		SoundManager.play(get_tree(), "win", 0.05)
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("win_game"):
			gm.win_game()
