extends Node2D
class_name CentralMaquina

signal integrity_changed(current_integrity: float)
signal machine_exploded

@export var max_integrity: float = 100.0
@export var drain_per_broken_station: float = 2.5 # % perdido por segundo por estação quebrada
@export var passive_stability_drain: float = 0.5 # Leve perda constante para manter a tensão

var current_integrity: float = 100.0
var broken_stations_count: int = 0
var is_destroyed: bool = false
var last_damage_cause: String = ""

@onready var visual_root: Node2D = $Visual
@onready var core_light: ColorRect = $Visual/Core
@onready var status_bar: ProgressBar = $Visual/Core/IntegrityBar
@onready var smoke_particles: CPUParticles2D = $Visual/SmokeParticles
@onready var spark_particles: CPUParticles2D = $Visual/SparkParticles
@onready var alarm_left: ColorRect = $Visual/AlarmLeft
@onready var alarm_right: ColorRect = $Visual/AlarmRight
@onready var tenna_sphere: TennaSphere = get_node_or_null("Visual/TennaContainer/SubViewport/TennaSphere3D/SphereRoot")

func _ready() -> void:
	add_to_group("maquina")
	current_integrity = max_integrity
	if status_bar:
		status_bar.max_value = max_integrity
		status_bar.value = current_integrity
	update_visuals()

func _process(delta: float) -> void:
	if is_destroyed:
		return

	# Drenagem de integridade proporcional aos defeitos ativos
	if broken_stations_count > 0:
		var loss = (broken_stations_count * drain_per_broken_station + passive_stability_drain) * delta
		if GameSettings.is_tutorial_mode and current_integrity - loss < 25.0:
			loss = max(0.0, current_integrity - 25.0)
		damage_integrity(loss)
	
	# Animação do alarme e núcleo
	var time = Time.get_ticks_msec() * 0.005
	if broken_stations_count > 0:
		var flash = 0.5 + 0.5 * sin(time * 3.0)
		var alarm_color = Color(1.0, 0.1, 0.1, flash)
		if alarm_left: alarm_left.color = alarm_color
		if alarm_right: alarm_right.color = alarm_color
	else:
		var ok_color = Color(0.2, 0.8, 0.3, 0.8)
		if alarm_left: alarm_left.color = ok_color
		if alarm_right: alarm_right.color = ok_color

func register_broken_station() -> void:
	broken_stations_count += 1
	# Efeito de fumaça temporariamente desativado a pedido do usuário
	if spark_particles and broken_stations_count >= 2:
		spark_particles.emitting = true

func register_fixed_station() -> void:
	broken_stations_count = max(0, broken_stations_count - 1)
	repair_bonus(6.0) # Bônus de integridade recuperada ao consertar!
	if broken_stations_count == 0:
		if spark_particles:
			spark_particles.emitting = false

func damage_integrity(amount: float, cause: String = "") -> void:
	if is_destroyed or amount <= 0.0: return
	if cause != "":
		last_damage_cause = cause
	if GameSettings.is_tutorial_mode and current_integrity - amount < 25.0:
		amount = max(0.0, current_integrity - 25.0)
	current_integrity = clamp(current_integrity - amount, 0.0, max_integrity)
	integrity_changed.emit(current_integrity)
	update_visuals()

	if current_integrity <= 0.0 and not is_destroyed and not GameSettings.is_tutorial_mode:
		explode()

func apply_minor_failure(cause: String, amount: float = 5.0) -> void:
	if is_destroyed: return
	if GameSettings.is_tutorial_mode and current_integrity - amount < 25.0:
		amount = max(0.0, current_integrity - 25.0)
	
	last_damage_cause = cause
	damage_integrity(amount, cause)
	SoundManager.play(get_tree(), "lose", 0.25, -14.0)

func repair_bonus(amount: float) -> void:
	current_integrity = clamp(current_integrity + amount, 0.0, max_integrity)
	integrity_changed.emit(current_integrity)
	update_visuals()

func update_visuals() -> void:
	if status_bar:
		status_bar.value = current_integrity
	
	var pct = current_integrity / max_integrity
	if tenna_sphere:
		tenna_sphere.set_integrity_pct(pct)

	# Cor do núcleo de acordo com a saúde da máquina
	if core_light:
		if pct > 0.6:
			core_light.color = Color(0.2, 0.7, 0.95, 1.0) # Azul/Ciano estável
		elif pct > 0.3:
			core_light.color = Color(0.95, 0.7, 0.15, 1.0) # Amarelo alerta
		else:
			core_light.color = Color(0.95, 0.2, 0.2, 1.0) # Vermelho crítico

func explode() -> void:
	is_destroyed = true
	SoundManager.play(get_tree(), "lose")
	if tenna_sphere:
		tenna_sphere.on_explode()
	if smoke_particles:
		smoke_particles.amount = 40
		smoke_particles.emitting = true
	if spark_particles:
		spark_particles.amount = 40
		spark_particles.emitting = true
	machine_exploded.emit()
