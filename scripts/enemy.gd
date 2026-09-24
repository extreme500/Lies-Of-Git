extends CharacterBody2D
class_name Enemy2D

@export var speed: float = 80.0
@export var patrol_distance: float = 120.0

var direction: float = 1.0
var start_x: float = 0.0
var gravity: float = 1000.0
var is_dead: bool = false

@onready var visual: Node2D = $Visual

func _ready() -> void:
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Movimento de patrulha
	velocity.x = direction * speed
	if abs(global_position.x - start_x) >= patrol_distance:
		direction *= -1.0
		start_x = global_position.x

	# Inverter se bater na parede
	if is_on_wall():
		direction *= -1.0

	if visual:
		visual.scale.x = direction

	move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body is Player2D or body.name == "Player":
		# Se o jogador estiver caindo e acima da cabeça do inimigo -> STOMP
		if body.velocity.y > 0.0 and body.global_position.y < global_position.y - 10.0:
			stomp(body)
		else:
			# Jogador tomou dano
			body.die()

func stomp(player: Player2D) -> void:
	is_dead = true
	SoundManager.play(get_tree(), "hit", 0.2)
	player.bounce(-480.0)
	
	# Animação de esmagamento
	var tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.4 * direction, 0.2), 0.1)
	tween.tween_callback(queue_free)
