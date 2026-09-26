@tool
extends Node2D

@export var raio: float = 65.0 # Comprimento da linha e raio do dial
@export var velocidade_angular: float = 2.0 # Velocidade de rotação em radianos/segundo
@export var espessura_linha: float = 6.0 # Espessura da linha horizontal giratória

@export var cor_circunferencia: Color = Color(0.12, 0.15, 0.22, 0.85) # Cor base da circunferência
@export var cor_borda: Color = Color(0.35, 0.45, 0.6, 0.9) # Bordas interna e externa
@export var cor_area_alvo: Color = Color(0.2, 0.85, 0.4, 0.95) # Área alvo
@export var cor_linha: Color = Color(1.0, 1.0, 1.0, 1.0) # Cor da linha giratória

var angulo_linha: float = 0.0 # Ângulo da linha (começa horizontal em 0 rad)
var angulo_alvo: float = randf_range(0.0, TAU) # Posição angular aleatória da área alvo
var tamanho_area_alvo: float = deg_to_rad(40.0) # Área alvo (ajustada pela dificuldade)

# ==============================================================================
# 📊 MECÂNICA DA BARRA VERTICAL (CONTROLE COM PULO DO JOGADOR A)
# ==============================================================================
var bar_pos: float = 0.25 # 0.0 = base, 1.0 = topo
var bar_velocity: float = 0.0
var bar_gravity: float = 1.9 # Gravidade contínua puxando para baixo
var jump_impulse: float = 0.88 # Impulso para cima a cada pulo/toque do Jogador A
var green_zone_min: float = 0.35 # Início da zona verde alvo
var green_zone_max: float = 0.68 # Fim da zona verde alvo
var bar_pulse_timer: float = 0.0

func _ready() -> void:
	z_index = 25
	z_as_relative = false
	if has_node("RetaSC"):
		$RetaSC.visible = false
	if Engine.is_editor_hint():
		visible = true
		queue_redraw()
		return
	visible = false
	var parent_node = get_parent()
	if parent_node and parent_node.name == "AnguloSC":
		parent_node.visible = false
		parent_node.z_index = 25
	sortear_novo_alvo()
	queue_redraw()

func set_active(active: bool) -> void:
	var was_active = visible
	visible = active
	var parent_node = get_parent()
	if parent_node and parent_node.name == "AnguloSC":
		parent_node.visible = active
	if active and not was_active:
		sortear_novo_alvo()

func sortear_novo_alvo() -> void:
	tamanho_area_alvo = deg_to_rad(GameSettings.get_skillcheck_target_angle_deg())
	angulo_alvo = randf_range(0.0, TAU)
	
	# Sorteia uma nova posição para a zona verde da barra vertical
	green_zone_min = randf_range(0.22, 0.52)
	green_zone_max = green_zone_min + 0.30
	bar_pos = 0.25
	bar_velocity = 0.0
	queue_redraw()

func impulse_blue_bar() -> void:
	# Impulsiona a barra azul para cima (chamado pelo botão de pulo do Jogador A)
	bar_velocity = max(bar_velocity + jump_impulse, jump_impulse * 0.95)
	bar_pulse_timer = 0.12
	queue_redraw()

func is_barra_na_zona_verde() -> bool:
	return bar_pos >= green_zone_min and bar_pos <= green_zone_max

func is_dial_alvo_atingido() -> bool:
	var diff = fposmod(angulo_linha - angulo_alvo, TAU)
	return diff >= 0.0 and diff <= tamanho_area_alvo

# Função de validação: SÓ pode dar OK se a barra azul estiver na zona verde!
func is_alvo_atingido() -> bool:
	return is_barra_na_zona_verde() and is_dial_alvo_atingido()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if not is_visible_in_tree():
		return
		
	# 1. Linha do dial gira continuamente
	angulo_linha += velocidade_angular * delta
	angulo_linha = fposmod(angulo_linha, TAU)
	
	# 2. Física da barra azul com gravidade
	bar_velocity -= bar_gravity * delta
	bar_velocity = clampf(bar_velocity, -2.6, 2.2)
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
	# ==========================================================================
	# 1. DIAL CIRCULAR GIRATÓRIO (ESQUERDA)
	# ==========================================================================
	var r_externo: float = raio
	var r_interno: float = raio / 2.0
	var r_meio: float = (r_externo + r_interno) / 2.0
	var largura_anel: float = r_externo - r_interno
	
	# Circunferência base
	draw_arc(Vector2.ZERO, r_meio, 0.0, TAU, 96, cor_circunferencia, largura_anel, true)
	
	# Área alvo da circunferência
	draw_arc(Vector2.ZERO, r_meio, angulo_alvo, angulo_alvo + tamanho_area_alvo, 32, cor_area_alvo, largura_anel, true)
	
	# Linhas delimitadoras radiais da área
	var p_inicio_in = Vector2.from_angle(angulo_alvo) * r_interno
	var p_inicio_out = Vector2.from_angle(angulo_alvo) * r_externo
	var p_fim_in = Vector2.from_angle(angulo_alvo + tamanho_area_alvo) * r_interno
	var p_fim_out = Vector2.from_angle(angulo_alvo + tamanho_area_alvo) * r_externo
	draw_line(p_inicio_in, p_inicio_out, Color(1, 1, 1, 0.95), 2.5, true)
	draw_line(p_fim_in, p_fim_out, Color(1, 1, 1, 0.95), 2.5, true)
	
	# Bordas interna e externa para acabamento visual perfeito
	draw_arc(Vector2.ZERO, r_interno, 0.0, TAU, 96, cor_borda, 2.0, true)
	draw_arc(Vector2.ZERO, r_externo, 0.0, TAU, 96, cor_borda, 2.0, true)
	
	# Linha giratória em torno do centro (comprimento = raio)
	var ponta_linha = Vector2.from_angle(angulo_linha) * raio
	draw_line(Vector2.ZERO, ponta_linha, cor_linha, espessura_linha, true)
	
	# Ponto central / pivô de rotação
	draw_circle(Vector2.ZERO, espessura_linha * 1.0, cor_linha)
	draw_circle(Vector2.ZERO, espessura_linha * 0.5, Color(0.1, 0.12, 0.18))
	
	# ==========================================================================
	# 2. BARRA VERTICAL COM ZONA VERDE E BARRINHA AZUL (DIREITA)
	# ==========================================================================
	var bar_x = 80.0
	var bar_w = 26.0
	var bar_h = 130.0
	var bar_y_offset = -65.0
	
	# Fundo da barra vertical
	draw_rect(Rect2(bar_x, bar_y_offset, bar_w, bar_h), Color(0.08, 0.11, 0.16, 0.92))
	draw_rect(Rect2(bar_x, bar_y_offset, bar_w, bar_h), cor_borda, false, 2.0)
	
	# Zona verde desejada / alvo
	var gz_y_bottom = 65.0 - green_zone_min * bar_h
	var gz_y_top = 65.0 - green_zone_max * bar_h
	var gz_height = gz_y_bottom - gz_y_top
	var in_green_zone = is_barra_na_zona_verde()
	
	var gz_color = Color(0.2, 0.9, 0.45, 0.85 if in_green_zone else 0.45)
	draw_rect(Rect2(bar_x + 2, gz_y_top, bar_w - 4, gz_height), gz_color)
	draw_rect(Rect2(bar_x + 2, gz_y_top, bar_w - 4, gz_height), Color(0.5, 1.0, 0.7, 0.9), false, 1.5)
	
	# Barrinha azul flutuante (sobe com pulo, desce com gravidade)
	var blue_y = 65.0 - bar_pos * bar_h
	var blue_color = Color(0.25, 0.75, 1.0, 1.0) if bar_pulse_timer <= 0.0 else Color(0.75, 0.95, 1.0, 1.0)
	draw_rect(Rect2(bar_x + 1, blue_y - 6, bar_w - 2, 12), blue_color)
	draw_rect(Rect2(bar_x + 1, blue_y - 6, bar_w - 2, 12), Color(1.0, 1.0, 1.0, 0.95), false, 1.5)
	draw_line(Vector2(bar_x + 3, blue_y), Vector2(bar_x + bar_w - 3, blue_y), Color(1, 1, 1, 0.8), 2.0)
	
	# Indicador de status no topo da barra (símbolo de sucesso se dentro da zona)
	if in_green_zone:
		draw_circle(Vector2(bar_x + bar_w * 0.5, bar_y_offset - 8), 4.0, Color(0.2, 1.0, 0.4, 0.95))
	else:
		draw_circle(Vector2(bar_x + bar_w * 0.5, bar_y_offset - 8), 3.0, Color(0.6, 0.7, 0.8, 0.5))
