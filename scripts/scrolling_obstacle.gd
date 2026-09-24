extends Area2D
class_name ScrollingObstacle

@export var is_coin: bool = false
var speed: float = 450.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	if position.x < -150.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is RunnerPlayer or body.name == "Player":
		if is_coin:
			SoundManager.play(get_tree(), "coin", 0.2)
			var gm = get_tree().get_first_node_in_group("runner_game_manager")
			if gm and gm.has_method("add_coin"):
				gm.add_coin()
			queue_free()
		else:
			if body.has_method("hit_obstacle"):
				body.hit_obstacle()
