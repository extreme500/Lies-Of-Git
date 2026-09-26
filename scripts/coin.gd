extends Area2D
class_name Coin2D

var initial_y: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
	initial_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_passed += delta * 4.0
	position.y = initial_y + sin(time_passed) * 6.0
	rotation += delta * 2.0

func _on_body_entered(body: Node2D) -> void:
	if body is CoopPlayer2D or body.name.begins_with("Player"):
		SoundManager.play(get_tree(), "coin", 0.15)
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("add_coin"):
			gm.add_coin()
		queue_free()
