@tool
extends Node2D
class_name BarraVerticalSC

@export var bar_w: float = 28.0
@export var bar_h: float = 130.0

var bar_pos: float = 0.25 # 0.0 = base, 1.0 = topo
var bar_velocity: float = 0.0
var bar_gravity: float = 1.7 # Gravidade puxando para baixo
var jump_impulse: float = 0.46 # Impulso por pulo (diminuído levemente para melhor controle)
var green_zone_min: float = 0.35
var green_zone_max: float = 0.68
var bar_pulse_timer: float = 0.0

func _ready() -> void:
	z_index = 25
	z_as_relative = false
	if Engine.is_editor_hint():
		visible = true
		queue_redraw()
		return
	visible = false
	sortear_novo_alvo()
	queue_redraw()

func set_active(active: bool) -> void:
	visible = active
	if active:
		sortear_novo_alvo()

func sortear_novo_alvo() -> void:
	green_zone_min = randf_range(0.22, 0.52)
	green_zone_max = green_zone_min + 0.30
	bar_pos = 0.25
	bar_velocity = 0.0
	queue_redraw()

func impulse_blue_bar() -> void:
	bar_velocity = max(bar_velocity + jump_impulse, jump_impulse * 0.95)
	bar_pulse_timer = 0.12
	queue_redraw()

func is_barra_na_zona_verde() -> bool:
	return bar_pos >= green_zone_min and bar_pos <= green_zone_max

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if not is_visible_in_tree():
		return
		
	# Física da barra azul com gravidade
	bar_velocity -= bar_gravity * delta
	bar_velocity = clampf(bar_velocity, -2.6, 2.0)
	bar_pos += bar_velocity * delta
	
	if bar_pos <= 0.0:
		bar_pos = 0.0
		bar_velocity = 0.0
	elif bar_pos >= 1.0:
		bar_pos = 1.0
		bar_velocity = min(0.0, bar_velocity)
		
	if bar_pulse_timer > 0.0:
		bar_pulse_timer -= delta
		
	queue_redraw()

func _draw() -> void:
	var half_w = bar_w * 0.5
	var half_h = bar_h * 0.5
	
	# Fundo da barra
	draw_rect(Rect2(-half_w, -half_h, bar_w, bar_h), Color(0.08, 0.11, 0.16, 0.92))
	draw_rect(Rect2(-half_w, -half_h, bar_w, bar_h), Color(0.35, 0.45, 0.6, 0.9), false, 2.0)
	
	# Zona verde alvo
	var gz_y_bottom = half_h - green_zone_min * bar_h
	var gz_y_top = half_h - green_zone_max * bar_h
	var gz_height = gz_y_bottom - gz_y_top
	var in_green_zone = is_barra_na_zona_verde()
	
	var gz_color = Color(0.2, 0.9, 0.45, 0.85 if in_green_zone else 0.45)
	draw_rect(Rect2(-half_w + 2, gz_y_top, bar_w - 4, gz_height), gz_color)
	draw_rect(Rect2(-half_w + 2, gz_y_top, bar_w - 4, gz_height), Color(0.5, 1.0, 0.7, 0.9), false, 1.5)
	
	# Barrinha azul flutuante
	var blue_y = half_h - bar_pos * bar_h
	var blue_color = Color(0.25, 0.75, 1.0, 1.0) if bar_pulse_timer <= 0.0 else Color(0.75, 0.95, 1.0, 1.0)
	draw_rect(Rect2(-half_w + 1, blue_y - 6, bar_w - 2, 12), blue_color)
	draw_rect(Rect2(-half_w + 1, blue_y - 6, bar_w - 2, 12), Color(1.0, 1.0, 1.0, 0.95), false, 1.5)
	draw_line(Vector2(-half_w + 3, blue_y), Vector2(half_w - 3, blue_y), Color(1, 1, 1, 0.8), 2.0)
	
	# Indicador de status no topo
	if in_green_zone:
		draw_circle(Vector2(0, -half_h - 8), 4.0, Color(0.2, 1.0, 0.4, 0.95))
	else:
		draw_circle(Vector2(0, -half_h - 8), 3.0, Color(0.6, 0.7, 0.8, 0.5))
