extends AnimatableBody2D
class_name MovingPlatform2D

@export var move_offset: Vector2 = Vector2(180, 0)
@export var duration: float = 3.0

var start_pos: Vector2

func _ready() -> void:
	start_pos = position
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position", start_pos + move_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
