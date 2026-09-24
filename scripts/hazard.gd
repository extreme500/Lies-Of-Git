extends Area2D
class_name Hazard2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player2D or body.name == "Player":
		body.die()
