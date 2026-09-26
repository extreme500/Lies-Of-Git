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
	queue_redraw()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if not is_visible_in_tree():
		return
	# Linha gira 360 graus continuamente em torno do centro
	angulo_linha += velocidade_angular * delta
	angulo_linha = fposmod(angulo_linha, TAU)
	queue_redraw()

func _draw() -> void:
	# A circunferência vai desde a ponta (raio) até a metade da linha (raio / 2.0)
	var r_externo: float = raio
	var r_interno: float = raio / 2.0
	var r_meio: float = (r_externo + r_interno) / 2.0
	var largura_anel: float = r_externo - r_interno
	
	# 1. Circunferência base (da metade até a ponta da linha)
	draw_arc(Vector2.ZERO, r_meio, 0.0, TAU, 96, cor_circunferencia, largura_anel, true)
	
	# 2. Área alvo da circunferência
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
	
	# 3. Linha giratória em torno do centro (comprimento = raio)
	var ponta_linha = Vector2.from_angle(angulo_linha) * raio
	draw_line(Vector2.ZERO, ponta_linha, cor_linha, espessura_linha, true)
	
	# Ponto central / pivô de rotação
	draw_circle(Vector2.ZERO, espessura_linha * 1.0, cor_linha)
	draw_circle(Vector2.ZERO, espessura_linha * 0.5, Color(0.1, 0.12, 0.18))

# Função auxiliar para verificar se a linha está dentro da área alvo
func is_alvo_atingido() -> bool:
	var diff = fposmod(angulo_linha - angulo_alvo, TAU)
	return diff >= 0.0 and diff <= tamanho_area_alvo
