extends Node3D
class_name TennaSphere

enum ObservationState {
	WATCH_P1,     # Encarando o Jogador 1 (à esquerda na câmara 1)
	WATCH_P2,     # Encarando o Jogador 2 (à direita na câmara 2)
	WATCH_CENTER, # Olhando para a esteira central/frente
	SCAN_SWEEP    # Varrendo suavemente de um lado para o outro
}

@export var full_spin: bool = false
@export var turn_speed: float = 1.3

@onready var sphere_root: Node3D = self
var drone_model: Node3D = null

var time: float = 0.0
var integrity_pct: float = 1.0
var is_exploded: bool = false

var current_state: ObservationState = ObservationState.WATCH_CENTER
var state_timer: float = 2.0
var target_yaw: float = 0.0
var target_pitch: float = 0.08
var current_yaw: float = 0.0
var current_pitch: float = 0.08

var p1_ref: Node2D = null
var p2_ref: Node2D = null

func _ready() -> void:
	drone_model = find_child("DroneModel", true, false) as Node3D
	adjust_drone_materials()

func adjust_drone_materials() -> void:
	if drone_model == null:
		return
	for mi in drone_model.find_children("*", "MeshInstance3D"):
		if mi is MeshInstance3D:
			# Oculta planos auxiliares soltos do arquivo 3D que ficavam fora do centro
			if mi.name.begins_with("Plane_001") or mi.name.begins_with("Plane_007") or mi.name.begins_with("Plane_008") or mi.name.begins_with("Plane_009"):
				mi.visible = false
				continue
			
			if mi.mesh:
				for s in range(mi.mesh.get_surface_count()):
					var mat = mi.mesh.surface_get_material(s)
					if mat is StandardMaterial3D:
						var sm = mat.duplicate() as StandardMaterial3D
						
						# Identifica elementos luminosos azuis (o anel/olho frontal)
						var is_blue = false
						if sm.emission_enabled and (sm.emission.b > 0.5 and sm.emission.b > sm.emission.r + 0.15):
							is_blue = true
						elif sm.albedo_color.b > 0.6 and (sm.albedo_color.b > sm.albedo_color.r + 0.2):
							is_blue = true
						elif "014" in mat.resource_name or mi.name.begins_with("Circle_001"):
							is_blue = true
						
						if is_blue:
							# Preserva e realça a luz azul cibernética original
							sm.emission_enabled = true
							sm.emission = Color(0.1, 0.85, 1.0, 1.0)
							sm.emission_energy_multiplier = 2.2
						else:
							# Desativa emissões brancas que estouravam a luz e deixavam a máquina esbranquiçada
							sm.emission_enabled = false
							# Aplica acabamento grafite/acinzentado metálico fosco na carcaça
							sm.albedo_color = Color(0.42, 0.45, 0.50, 1.0)
							sm.metallic = clamp(sm.metallic, 0.45, 0.85)
							sm.roughness = clamp(sm.roughness, 0.35, 0.65)
						
						mi.set_surface_override_material(s, sm)

func _process(delta: float) -> void:
	# Mantém a posição sempre perfeitamente travada no centro topo
	sphere_root.position = Vector3.ZERO
	
	if is_exploded:
		sphere_root.rotate_y(delta * 12.0)
		sphere_root.rotate_z(delta * 6.0)
		return
	
	time += delta
	_update_observation(delta)

func _update_observation(delta: float) -> void:
	state_timer -= delta
	
	# Busca referências aos jogadores na árvore caso ainda não tenha
	if p1_ref == null and is_inside_tree():
		p1_ref = get_tree().root.find_child("Player1", true, false) as Node2D
	if p2_ref == null and is_inside_tree():
		p2_ref = get_tree().root.find_child("Player2", true, false) as Node2D
	
	# Quando o timer expira, seleciona o próximo alvo para observar
	if state_timer <= 0.0:
		_pick_next_observation_state()
	
	# Calcula ângulos-alvo com base no estado atual
	match current_state:
		ObservationState.WATCH_P1:
			# Encarando o Player 1 (à esquerda na Câmara 1)
			if p1_ref and is_instance_valid(p1_ref):
				var dx = p1_ref.global_position.x - 640.0
				var dy = p1_ref.global_position.y - 150.0
				target_yaw = clamp(dx / 1250.0, -0.58, -0.32)
				target_pitch = clamp(dy / 3200.0, 0.06, 0.16)
			else:
				target_yaw = -0.45
				target_pitch = 0.10
			# Micro-ajuste orgânico de respiração/foco
			target_yaw += sin(time * 1.5) * 0.015
			target_pitch += cos(time * 2.0) * 0.01
			
		ObservationState.WATCH_P2:
			# Encarando o Player 2 (à direita na Câmara 2)
			if p2_ref and is_instance_valid(p2_ref):
				var dx = p2_ref.global_position.x - 640.0
				var dy = p2_ref.global_position.y - 150.0
				target_yaw = clamp(dx / 1250.0, 0.32, 0.58)
				target_pitch = clamp(dy / 3200.0, 0.06, 0.16)
			else:
				target_yaw = 0.45
				target_pitch = 0.10
			target_yaw += sin(time * 1.5) * 0.015
			target_pitch += cos(time * 2.0) * 0.01
			
		ObservationState.WATCH_CENTER:
			# Olhando para o centro / esteira
			target_yaw = sin(time * 0.6) * 0.06
			target_pitch = 0.08 + cos(time * 0.8) * 0.02
			
		ObservationState.SCAN_SWEEP:
			# Varredura suave contínua de um lado ao outro
			target_yaw = sin(time * 0.7) * 0.45
			target_pitch = 0.10
	
	# Rotação suave e lenta ("lentamente" como solicitado)
	current_yaw = lerp_angle(current_yaw, target_yaw, turn_speed * delta)
	current_pitch = lerpf(current_pitch, target_pitch, turn_speed * delta)
	
	sphere_root.rotation.y = current_yaw
	sphere_root.rotation.x = current_pitch
	# Inclinação sutil na rolagem ao virar (efeito natural de cabeça robótica)
	sphere_root.rotation.z = -current_yaw * 0.07

func _pick_next_observation_state() -> void:
	var next_candidates: Array = []
	match current_state:
		ObservationState.WATCH_P1:
			next_candidates = [ObservationState.WATCH_P2, ObservationState.WATCH_CENTER]
		ObservationState.WATCH_P2:
			next_candidates = [ObservationState.WATCH_P1, ObservationState.WATCH_CENTER]
		ObservationState.WATCH_CENTER:
			next_candidates = [ObservationState.WATCH_P1, ObservationState.WATCH_P2, ObservationState.SCAN_SWEEP]
		ObservationState.SCAN_SWEEP:
			next_candidates = [ObservationState.WATCH_P1, ObservationState.WATCH_P2]
	
	current_state = next_candidates.pick_random()
	
	# Tempo encarando: de 2.5 a 4.2 segundos para encaradas, 1.6 a 2.8 para centro
	if current_state == ObservationState.WATCH_P1 or current_state == ObservationState.WATCH_P2:
		state_timer = randf_range(2.5, 4.2)
	elif current_state == ObservationState.WATCH_CENTER:
		state_timer = randf_range(1.6, 2.8)
	else:
		state_timer = randf_range(3.0, 4.5)

func set_integrity_pct(pct: float) -> void:
	integrity_pct = clamp(pct, 0.0, 1.0)

func on_explode() -> void:
	is_exploded = true
	integrity_pct = 0.0
