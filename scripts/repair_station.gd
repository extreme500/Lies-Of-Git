extends Node2D
class_name RepairStation

signal station_broken(station: RepairStation)
signal station_fixed(station: RepairStation)

@export var station_name: String = "Terminal"
@export var station_type: String = "terminal" # "terminal", "cabo", "bobina", "valvula"
@export var chamber_id: int = 1 # 1 = Sala Esquerda (P1), 2 = Sala Direita (P2)
@export var repair_time_needed: float = 1.5

var status: String = "OK" # "OK" ou "BROKEN"
var repair_progress: float = 0.0
var sfx_repair_cooldown: float = 0.0

@onready var visual_root: Node2D = $Visual
@onready var warning_icon: Node2D = $WarningIcon
@onready var status_light: ColorRect = $Visual/StatusLight
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var sparks_particles: CPUParticles2D = $SparksParticles
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	if name_label:
		name_label.text = station_name
	if progress_bar:
		progress_bar.visible = false
		progress_bar.max_value = repair_time_needed
		progress_bar.value = 0.0
	if warning_icon:
		warning_icon.visible = false
	if sparks_particles:
		sparks_particles.emitting = false
	update_status_visual()

func _process(delta: float) -> void:
	if status == "BROKEN":
		# Efeito de piscar no ícone de alerta
		if warning_icon:
			warning_icon.scale = Vector2.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.01))
	sfx_repair_cooldown -= delta

func is_broken() -> bool:
	return status == "BROKEN"

func break_down() -> void:
	if status == "BROKEN":
		return
	status = "BROKEN"
	repair_progress = 0.0
	if warning_icon:
		warning_icon.visible = true
	if sparks_particles:
		sparks_particles.emitting = true
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0.0
	update_status_visual()
	SoundManager.play(get_tree(), "hit", 0.2)
	station_broken.emit(self)

func repair_tick(delta: float) -> void:
	if status != "BROKEN":
		return
	
	repair_progress += delta
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = repair_progress

	if sfx_repair_cooldown <= 0.0:
		SoundManager.play(get_tree(), "step", 0.4)
		sfx_repair_cooldown = 0.25

	if repair_progress >= repair_time_needed:
		fix_station()

func fix_station() -> void:
	status = "OK"
	repair_progress = 0.0
	if warning_icon:
		warning_icon.visible = false
	if sparks_particles:
		sparks_particles.emitting = false
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0.0
	update_status_visual()
	SoundManager.play(get_tree(), "powerup", 0.1)
	station_fixed.emit(self)

func update_status_visual() -> void:
	if status_light:
		if status == "OK":
			status_light.color = Color(0.2, 0.9, 0.3, 1.0) # Verde normal
		else:
			status_light.color = Color(1.0, 0.2, 0.2, 1.0) # Vermelho alerta
