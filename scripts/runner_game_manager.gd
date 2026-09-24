extends Node2D
class_name RunnerGameManager

var current_speed: float = 420.0
var distance: float = 0.0
var coins: int = 0
var is_game_over: bool = false
var spawn_timer: float = 0.0

@onready var player: RunnerPlayer = $Player
@onready var obstacles_container: Node2D = $Obstacles
@onready var distance_label: Label = $HUD/MarginContainer/VBox/DistanceLabel
@onready var coins_label: Label = $HUD/MarginContainer/VBox/CoinsLabel
@onready var speed_label: Label = $HUD/MarginContainer/VBox/SpeedLabel
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var game_over_summary: Label = $HUD/GameOverPanel/VBox/SummaryLabel

func _ready() -> void:
	add_to_group("runner_game_manager")
	if game_over_panel:
		game_over_panel.visible = false
	if player:
		player.crashed.connect(_on_player_crashed)

func _process(delta: float) -> void:
	if is_game_over:
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_R):
			restart()
		return

	# Aceleração gradual
	current_speed += delta * 6.0
	distance += (current_speed * delta) * 0.05

	if distance_label:
		distance_label.text = "Distância: %dm" % int(distance)
	if coins_label:
		coins_label.text = "Moedas: %d" % coins
	if speed_label:
		speed_label.text = "Velocidade: %.0f km/h" % (current_speed * 0.1)

	# Atualizar velocidade dos obstáculos ativos
	for child in obstacles_container.get_children():
		if child is ScrollingObstacle:
			child.speed = current_speed

	# Spawn de obstáculos
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(1.2, 2.2) * (420.0 / current_speed)
		spawn_random_hazard()

func spawn_random_hazard() -> void:
	var type = randi() % 3
	match type:
		0:
			# Obstáculo terrestre (pular por cima)
			spawn_ground_obstacle()
		1:
			# Obstáculo aéreo (deslizar por baixo)
			spawn_aerial_obstacle()
		2:
			# Linha de moedas
			spawn_coin_trail()

func spawn_ground_obstacle() -> void:
	var obs = Area2D.new()
	var script = load("res://scripts/scrolling_obstacle.gd")
	obs.set_script(script)
	obs.position = Vector2(1250, 480)
	obs.speed = current_speed

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 36)
	col.shape = shape
	obs.add_child(col)

	var vis = ColorRect.new()
	vis.size = Vector2(30, 36)
	vis.position = Vector2(-15, -18)
	vis.color = Color(0.95, 0.35, 0.45, 1)
	obs.add_child(vis)

	var label = Label.new()
	label.text = "▲"
	label.position = Vector2(-10, -16)
	label.add_theme_color_override("font_color", Color.WHITE)
	obs.add_child(label)

	obstacles_container.add_child(obs)

func spawn_aerial_obstacle() -> void:
	var obs = Area2D.new()
	var script = load("res://scripts/scrolling_obstacle.gd")
	obs.set_script(script)
	obs.position = Vector2(1250, 420)
	obs.speed = current_speed

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 24)
	col.shape = shape
	obs.add_child(col)

	var vis = ColorRect.new()
	vis.size = Vector2(60, 24)
	vis.position = Vector2(-30, -12)
	vis.color = Color(0.98, 0.5, 0.2, 1)
	obs.add_child(vis)

	var label = Label.new()
	label.text = "⚡ LASER ⚡"
	label.position = Vector2(-30, -12)
	label.size = Vector2(60, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	obs.add_child(label)

	obstacles_container.add_child(obs)

func spawn_coin_trail() -> void:
	var start_x = 1250.0
	for i in range(4):
		var coin = Area2D.new()
		var script = load("res://scripts/scrolling_obstacle.gd")
		coin.set_script(script)
		coin.is_coin = true
		coin.position = Vector2(start_x + (i * 45), 440 - sin(i * 0.8) * 40)
		coin.speed = current_speed

		var col = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		col.shape = circle
		coin.add_child(col)

		var vis = ColorRect.new()
		vis.size = Vector2(16, 16)
		vis.position = Vector2(-8, -8)
		vis.rotation = deg_to_rad(45)
		vis.color = Color(0.98, 0.85, 0.3, 1)
		coin.add_child(vis)

		obstacles_container.add_child(coin)

func add_coin() -> void:
	coins += 1

func _on_player_crashed() -> void:
	is_game_over = true
	SoundManager.play(get_tree(), "lose")
	if game_over_panel:
		game_over_panel.visible = true
		if game_over_summary:
			game_over_summary.text = "Você correu por %d metros e coletou %d moedas!" % [int(distance), coins]

func restart() -> void:
	SoundManager.play(get_tree(), "click")
	get_tree().reload_current_scene()
