extends Node2D

@export var belt_speed: float = 65.0
@export var top_y: float = -245.0
@export var bottom_y: float = 245.0
@export var hazard_y: float = 225.0

var has_piece: bool = false
var current_piece_y: float = -245.0
var _belt_offset: float = 0.0
var _alert_timer: float = 0.0

@onready var p1_area: Area2D = $P1_Area
@onready var p2_area: Area2D = $P2_Area
@onready var piece_visual: Node2D = $PieceVisual
@onready var warning_light: ColorRect = $Visual/BottomMachine/WarningLight
@onready var sparks_particles: CPUParticles2D = $Visual/BottomMachine/SparksParticles
@onready var alert_label: Label = $AlertLabel

func _ready() -> void:
	if piece_visual: piece_visual.visible = false
	if alert_label: alert_label.visible = false

func _process(delta: float) -> void:
	# Animação contínua das ripas da esteira descendo
	_belt_offset = fmod(_belt_offset + belt_speed * delta, 24.0)
	queue_redraw()
	
	# Luz de perigo pulsante na máquina de baixo (triturador)
	if warning_light:
		var pulse = 0.35 + 0.65 * abs(sin(Time.get_ticks_msec() * 0.007))
		warning_light.color = Color(1.0, 0.2, 0.2, pulse)
	
	# Controle do aviso temporário de peça destruída
	if _alert_timer > 0.0:
		_alert_timer -= delta
		if _alert_timer <= 0.0 and alert_label:
			alert_label.visible = false
	
	# Movimento físico da peça para baixo ao longo da esteira
	if has_piece:
		current_piece_y += belt_speed * delta
		if piece_visual:
			piece_visual.position = Vector2(0, current_piece_y)
		
		# Se a peça tocar na máquina de baixo (hazard_y), ela é destruída!
		if current_piece_y >= hazard_y:
			destroy_piece()

func _draw() -> void:
	# Desenha as ripas e chevrons da esteira se movendo para baixo
	var slat_spacing = 24.0
	var y = top_y + _belt_offset
	while y <= bottom_y:
		if y >= top_y and y <= hazard_y:
			draw_rect(Rect2(-16, y - 2, 32, 4), Color(0.18, 0.22, 0.28, 0.95))
			draw_rect(Rect2(-16, y - 1, 32, 1), Color(0.35, 0.42, 0.52, 0.8))
			# Chevrons sutis apontando a direção da descida
			var pts = PackedVector2Array([Vector2(-4, y - 1), Vector2(0, y + 2), Vector2(4, y - 1)])
			draw_polyline(pts, Color(0.3, 0.65, 0.9, 0.4), 1.5)
		y += slat_spacing

func has_piece_on_belt() -> bool:
	return has_piece

func try_insert_item(player_id: int, player_global_y: float = -9999.0) -> bool:
	# Player A (player_id 1) pode colocar a peça em qualquer lugar da esteira
	if player_id == 1 and not has_piece:
		has_piece = true
		
		if player_global_y != -9999.0:
			var local_y = to_local(Vector2(0, player_global_y)).y
			current_piece_y = clamp(local_y, top_y + 10.0, hazard_y - 30.0)
		else:
			current_piece_y = top_y + 15.0
			
		if piece_visual:
			piece_visual.position = Vector2(0, current_piece_y)
			piece_visual.visible = true
			# Efeito de colocação
			piece_visual.scale = Vector2(1.3, 1.3)
			var tw = create_tween()
			tw.tween_property(piece_visual, "scale", Vector2.ONE, 0.15)
			
		SoundManager.play(get_tree(), "click", 0.4)
		return true
	return false

func try_take_item(player_id: int, _player_global_y: float = -9999.0) -> bool:
	# Player B (player_id 2) pode pegar a peça em qualquer lugar da esteira
	if player_id == 2 and has_piece:
		has_piece = false
		if piece_visual:
			piece_visual.visible = false
		SoundManager.play(get_tree(), "powerup", 0.3)
		return true
	return false

func destroy_piece() -> void:
	has_piece = false
	if piece_visual:
		piece_visual.visible = false
	
	if sparks_particles:
		sparks_particles.restart()
		sparks_particles.emitting = true
	
	if alert_label:
		alert_label.visible = true
		_alert_timer = 2.0
		
	SoundManager.play(get_tree(), "lose", 0.4)
	
	# Respawn da peça na Estação A com animação de transição caso o minigame "item" esteja pendente
	for station in get_tree().get_nodes_in_group("repair_stations"):
		if is_instance_valid(station) and station.has_method("redispensa_peca"):
			station.redispensa_peca()
