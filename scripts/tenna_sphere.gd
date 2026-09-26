extends Node3D
class_name TennaSphere

@export var full_spin: bool = false
@export var show_tenna_face: bool = true
@export var base_sway_speed: float = 1.8
@export var float_speed: float = 2.6
@export var float_amplitude: float = 0.07

@onready var sphere_root: Node3D = self
@onready var drone_model: Node3D = get_node_or_null("DroneModel")
@onready var face_mesh: MeshInstance3D = get_node_or_null("FaceMesh")
@onready var antenna_tip: MeshInstance3D = get_node_or_null("AntennaTip")
@onready var omni_light: OmniLight3D = get_node_or_null("FaceLight")

var tex_normal: Texture2D = preload("res://assets/maquina/tenna_face_normal.png")
var tex_warning: Texture2D = preload("res://assets/maquina/tenna_face_warning.png")
var tex_critical: Texture2D = preload("res://assets/maquina/tenna_face_critical.png")

var time: float = 0.0
var integrity_pct: float = 1.0
var is_exploded: bool = false
var face_material: StandardMaterial3D
var antenna_material: StandardMaterial3D

func _ready() -> void:
	if face_mesh:
		face_mesh.visible = show_tenna_face
		var mat = face_mesh.material_override
		if not mat:
			mat = face_mesh.get_surface_override_material(0)
		if mat:
			face_material = mat.duplicate()
			face_mesh.material_override = face_material
	
	if antenna_tip:
		var a_mat = antenna_tip.material_override
		if not a_mat:
			a_mat = antenna_tip.get_surface_override_material(0)
		if a_mat:
			antenna_material = a_mat.duplicate()
			antenna_tip.material_override = antenna_material
	
	update_expression()

func _process(delta: float) -> void:
	time += delta
	
	# Flutuação vertical orgânica
	var current_float_speed = float_speed
	var current_float_amp = float_amplitude
	if integrity_pct < 0.3:
		current_float_speed *= 2.2
		current_float_amp *= 0.6
	
	var bob = sin(time * current_float_speed) * current_float_amp
	
	# Tremores / Glitch de integridade
	var shake_x = 0.0
	var shake_y = 0.0
	if integrity_pct < 0.5 and not is_exploded:
		var intensity = (1.0 - integrity_pct * 2.0) * 0.04
		shake_x = randf_range(-intensity, intensity)
		shake_y = randf_range(-intensity, intensity)
	elif is_exploded:
		shake_x = randf_range(-0.08, 0.08)
		shake_y = randf_range(-0.08, 0.08)
	
	sphere_root.position = Vector3(shake_x, bob + shake_y, 0.0)
	
	# Rotação / Sway estilo showman de Deltarune
	if is_exploded:
		sphere_root.rotate_y(delta * 12.0)
		sphere_root.rotate_z(delta * 6.0)
	elif full_spin:
		var spin_speed = 1.2
		if integrity_pct < 0.3: spin_speed = 3.5
		sphere_root.rotate_y(delta * spin_speed)
	else:
		var sway_angle = sin(time * base_sway_speed) * 0.45 + sin(time * 0.7) * 0.15
		var tilt_angle = cos(time * base_sway_speed * 0.8) * 0.08
		if integrity_pct < 0.3:
			sway_angle += randf_range(-0.1, 0.1) # jitter
		sphere_root.rotation.y = sway_angle
		sphere_root.rotation.z = tilt_angle

func set_integrity_pct(pct: float) -> void:
	var old_state = get_state_from_pct(integrity_pct)
	integrity_pct = clamp(pct, 0.0, 1.0)
	var new_state = get_state_from_pct(integrity_pct)
	
	if old_state != new_state:
		update_expression()

func get_state_from_pct(pct: float) -> String:
	if pct > 0.6:
		return "normal"
	elif pct > 0.3:
		return "warning"
	else:
		return "critical"

func update_expression() -> void:
	var state = get_state_from_pct(integrity_pct)
	var target_tex: Texture2D = tex_normal
	var glow_color: Color = Color(0.1, 1.0, 0.75, 1.0) # Ciano/Verde neon
	
	if state == "normal":
		target_tex = tex_normal
		glow_color = Color(0.1, 1.0, 0.75, 1.0)
	elif state == "warning":
		target_tex = tex_warning
		glow_color = Color(1.0, 0.85, 0.1, 1.0) # Amarelo alerta
	else:
		target_tex = tex_critical
		glow_color = Color(1.0, 0.15, 0.15, 1.0) # Vermelho crítico
	
	if face_material:
		face_material.albedo_texture = target_tex
		face_material.emission_texture = target_tex
		face_material.emission = glow_color
	
	if antenna_material:
		antenna_material.albedo_color = glow_color
		antenna_material.emission = glow_color
	
	if omni_light:
		omni_light.light_color = glow_color
		if state == "critical":
			omni_light.light_energy = 2.5
		else:
			omni_light.light_energy = 1.5

func on_explode() -> void:
	is_exploded = true
	integrity_pct = 0.0
	update_expression()
