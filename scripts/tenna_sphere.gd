extends Node3D
class_name TennaSphere

@export var full_spin: bool = false
@export var base_sway_speed: float = 1.8
@export var float_speed: float = 2.6
@export var float_amplitude: float = 0.07

@onready var sphere_root: Node3D = self
@onready var drone_model: Node3D = get_node_or_null("DroneModel")

var time: float = 0.0
var integrity_pct: float = 1.0
var is_exploded: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	time += delta
	
	# Flutuação vertical orgânica (hovering / levitação)
	var current_float_speed = float_speed
	var current_float_amp = float_amplitude
	if integrity_pct < 0.3:
		current_float_speed *= 2.2
		current_float_amp *= 0.6
	
	var bob = sin(time * current_float_speed) * current_float_amp
	
	# Tremores / Glitch quando a máquina está danificada
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
	
	# Rotação e balanço do drone 3D
	if is_exploded:
		sphere_root.rotate_y(delta * 12.0)
		sphere_root.rotate_z(delta * 6.0)
	elif full_spin:
		var spin_speed = 1.2
		if integrity_pct < 0.3: spin_speed = 3.5
		sphere_root.rotate_y(delta * spin_speed)
	else:
		var sway_angle = sin(time * base_sway_speed) * 0.35 + sin(time * 0.7) * 0.12
		var tilt_angle = cos(time * base_sway_speed * 0.8) * 0.06
		if integrity_pct < 0.3:
			sway_angle += randf_range(-0.08, 0.08) # jitter
		sphere_root.rotation.y = sway_angle
		sphere_root.rotation.z = tilt_angle

func set_integrity_pct(pct: float) -> void:
	integrity_pct = clamp(pct, 0.0, 1.0)

func on_explode() -> void:
	is_exploded = true
	integrity_pct = 0.0
