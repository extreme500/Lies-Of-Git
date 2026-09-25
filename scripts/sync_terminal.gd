extends Node2D

signal sync_exploded

@export var cooldown_min: float = 20.0
@export var cooldown_max: float = 35.0
@export var time_to_press: float = 12.0

var status: String = "OK"
var timer: float = 0.0
var explosion_timer: float = 0.0

var p1_pressing: bool = false
var p2_pressing: bool = false

@onready var light: ColorRect = $Visual/StatusLight
@onready var alert_label: Label = $AlertLabel

func _ready() -> void:
	timer = randf_range(cooldown_min, cooldown_max)
	if alert_label: alert_label.hide()
	update_visual()

func _process(delta: float) -> void:
	if status == "OK":
		timer -= delta
		if timer <= 0.0:
			trigger_sync_event()
	elif status == "ALERT":
		explosion_timer -= delta
		if alert_label:
			alert_label.text = "SYNC NECESSÁRIO!\nTempo: %.1f" % explosion_timer
		
		# Flash light
		var flash = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
		light.color = Color(1.0, 0.2, 0.2, flash)

		if explosion_timer <= 0.0:
			explode()
		elif p1_pressing and p2_pressing:
			resolve_sync()

func trigger_sync_event() -> void:
	status = "ALERT"
	explosion_timer = time_to_press
	if alert_label: alert_label.show()
	SoundManager.play(get_tree(), "hit", 0.1)

func resolve_sync() -> void:
	status = "OK"
	timer = randf_range(cooldown_min, cooldown_max)
	if alert_label: alert_label.hide()
	SoundManager.play(get_tree(), "powerup", 0.5)
	update_visual()
	p1_pressing = false
	p2_pressing = false

func explode() -> void:
	status = "EXPLODED"
	sync_exploded.emit()

func update_visual() -> void:
	if light:
		light.color = Color(0.2, 0.8, 0.2) if status == "OK" else Color(1.0, 0.0, 0.0)

# Chamado pelas áreas de interação separadas de P1 e P2
func set_p1_pressing(val: bool) -> void:
	p1_pressing = val

func set_p2_pressing(val: bool) -> void:
	p2_pressing = val
