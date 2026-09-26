extends Node3D
class_name TennaSphere

@export var full_spin: bool = false
@export var base_sway_speed: float = 1.8
@export var float_speed: float = 2.6
@export var float_amplitude: float = 0.07

@onready var sphere_root: Node3D = self
var drone_model: Node3D = null

var time: float = 0.0
var integrity_pct: float = 1.0
var is_exploded: bool = false

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
						# Desativa emissão pura branca (1, 1, 1) que estourava a luz e apagava as texturas originais
						if sm.emission.r > 0.6 and sm.emission.g > 0.6 and sm.emission.b > 0.6:
							sm.emission_enabled = false
						# Preserva o acabamento metálico acinzentado original com tons ricos de cinza
						sm.metallic = clamp(sm.metallic, 0.35, 0.8)
						sm.roughness = clamp(sm.roughness, 0.35, 0.65)
						mi.set_surface_override_material(s, sm)

func _process(_delta: float) -> void:
	# Máquina estática no centro topo, sem movimento por enquanto a pedido do usuário
	sphere_root.position = Vector3.ZERO
	sphere_root.rotation = Vector3.ZERO

func set_integrity_pct(pct: float) -> void:
	integrity_pct = clamp(pct, 0.0, 1.0)

func on_explode() -> void:
	is_exploded = true
	integrity_pct = 0.0
