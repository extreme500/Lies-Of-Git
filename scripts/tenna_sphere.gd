extends Node3D
class_name TennaSphere

enum ObservationState {
	WATCH_P1,       # Encarando o Jogador 1 (à esquerda na câmara 1)
	WATCH_P2,       # Encarando o Jogador 2 (à direita na câmara 2)
	WATCH_CENTER,   # Olhando para a esteira central
	LOOK_RANDOM,    # Olhando curiosamente para uma direção aleatória (teto, paredes, cantos)
	SCAN_SWEEP      # Varredura suave da instalação
}

@export var full_spin: bool = false
@export var base_turn_speed: float = 1.2

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

var random_yaw_target: float = 0.0
var random_pitch_target: float = 0.0
var current_turn_speed: float = 1.2

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
						
						# Identifica se é a cúpula de vidro frontal transparente (Sphere_005 / Material.010)
						var is_glass = (sm.transparency > 0 or "010" in mat.resource_name or mi.name.begins_with("Sphere_005"))
						
						# Identifica elementos luminosos azuis (o anel/olho frontal)
						var is_blue = false
						if "014" in mat.resource_name or mi.name.begins_with("Circle_001") or "006" in mat.resource_name:
							is_blue = true
						elif sm.emission_enabled and (sm.emission.b > 0.4 and sm.emission.b > sm.emission.r + 0.1):
							is_blue = true
						elif sm.albedo_color.b > 0.5 and (sm.albedo_color.b > sm.albedo_color.r + 0.15):
							is_blue = true
						
						if is_glass and not is_blue:
							# Preserva a transparência do vidro frontal para o olho azul brilhar através dele!
							sm.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
							sm.albedo_color = Color(0.8, 0.92, 1.0, 0.12)
							sm.metallic = 0.2
							sm.roughness = 0.1
							sm.emission_enabled = false
						elif is_blue:
							# Olho e anel azul neon brilhante e intenso
							sm.emission_enabled = true
							sm.emission = Color(0.1, 0.88, 1.0, 1.0)
							sm.emission_energy_multiplier = 3.5
							sm.albedo_color = Color(0.1, 0.85, 1.0, 0.95)
						else:
							# Carcaça acinzentada / grafite metálico
							sm.emission_enabled = false
							sm.albedo_color = Color(0.48, 0.50, 0.54, 1.0)
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
	
	# Busca referências aos jogadores na árvore
	if p1_ref == null and is_inside_tree():
		p1_ref = get_tree().root.find_child("Player1", true, false) as Node2D
	if p2_ref == null and is_inside_tree():
		p2_ref = get_tree().root.find_child("Player2", true, false) as Node2D
	
	# Troca de estado em intervalos irregulares
	if state_timer <= 0.0:
		_pick_next_observation_state()
	
	match current_state:
		ObservationState.WATCH_P1:
			# Encarando o Jogador 1 (à esquerda na câmara 1)
			if p1_ref and is_instance_valid(p1_ref):
				var dx = p1_ref.global_position.x - 640.0
				var dy = p1_ref.global_position.y - 150.0
				target_yaw = clamp(dx / 1250.0, -0.60, -0.32)
				target_pitch = clamp(dy / 3200.0, 0.06, 0.16)
			else:
				target_yaw = -0.46
				target_pitch = 0.10
			# Micro-movimento sutil de foco ocular
			target_yaw += sin(time * 1.4) * 0.012
			target_pitch += cos(time * 1.8) * 0.008
			
		ObservationState.WATCH_P2:
			# Encarando o Jogador 2 (à direita na câmara 2)
			if p2_ref and is_instance_valid(p2_ref):
				var dx = p2_ref.global_position.x - 640.0
				var dy = p2_ref.global_position.y - 150.0
				target_yaw = clamp(dx / 1250.0, 0.32, 0.60)
				target_pitch = clamp(dy / 3200.0, 0.06, 0.16)
			else:
				target_yaw = 0.46
				target_pitch = 0.10
			target_yaw += sin(time * 1.4) * 0.012
			target_pitch += cos(time * 1.8) * 0.008
			
		ObservationState.WATCH_CENTER:
			# Olhando para o centro / esteira
			target_yaw = sin(time * 0.5) * 0.05
			target_pitch = 0.08 + cos(time * 0.7) * 0.02
			
		ObservationState.LOOK_RANDOM:
			# Olhando para uma direção curiosa aleatória (teto, paredes, cantos)
			target_yaw = random_yaw_target + sin(time * 1.0) * 0.01
			target_pitch = random_pitch_target + cos(time * 1.2) * 0.01
			
		ObservationState.SCAN_SWEEP:
			# Varredura suave contínua
			target_yaw = sin(time * 0.6) * 0.50
			target_pitch = 0.10 + cos(time * 0.4) * 0.03
	
	# Interpolação suave e lenta com velocidade orgânica
	current_yaw = lerp_angle(current_yaw, target_yaw, current_turn_speed * delta)
	current_pitch = lerpf(current_pitch, target_pitch, current_turn_speed * delta)
	
	sphere_root.rotation.y = current_yaw
	sphere_root.rotation.x = current_pitch
	sphere_root.rotation.z = -current_yaw * 0.07

func _pick_next_observation_state() -> void:
	# Seleciona de forma variada e irregular
	var pool = [
		ObservationState.WATCH_P1,
		ObservationState.WATCH_P2,
		ObservationState.LOOK_RANDOM,
		ObservationState.LOOK_RANDOM,
		ObservationState.WATCH_CENTER,
		ObservationState.SCAN_SWEEP
	]
	# Evita repetir o mesmo estado imediatamente
	pool.erase(current_state)
	current_state = pool.pick_random()
	
	# Velocidade do movimento para o próximo ponto varia suavemente
	current_turn_speed = randf_range(0.9, 1.4)
	
	# Duração irregular em cada ponto
	match current_state:
		ObservationState.WATCH_P1, ObservationState.WATCH_P2:
			# Encaradas deliberadas de 3.0 a 5.2 segundos
			state_timer = randf_range(3.0, 5.2)
		ObservationState.LOOK_RANDOM:
			# Direção aleatória: teto (-0.18), canto esquerdo, canto direito, ou para baixo
			random_yaw_target = randf_range(-0.65, 0.65)
			random_pitch_target = randf_range(-0.16, 0.22)
			# Olha por 1.6 a 3.4 segundos
			state_timer = randf_range(1.6, 3.4)
		ObservationState.WATCH_CENTER:
			state_timer = randf_range(1.8, 3.2)
		ObservationState.SCAN_SWEEP:
			state_timer = randf_range(3.0, 4.5)

func set_integrity_pct(pct: float) -> void:
	integrity_pct = clamp(pct, 0.0, 1.0)

func on_explode() -> void:
	is_exploded = true
	integrity_pct = 0.0
