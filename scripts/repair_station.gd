extends Node2D
class_name RepairStation

signal station_broken(station: RepairStation)
signal station_fixed(station: RepairStation)

@export var station_name: String = "Terminal"
@export var station_type: String = "terminal"
@export var chamber_id: int = 1

var status: String = "OK" # "OK" ou "BROKEN"
var minigame_type: String = ""
var role: String = "" # "A" ou "B"
var paired_station: RepairStation = null
var sfx_cooldown: float = 0.0

# Minigame variables
var mg_state: Dictionary = {}

@onready var visual_root: Node2D = $Visual
@onready var warning_icon: Node2D = $WarningIcon
@onready var status_light: ColorRect = $Visual/StatusLight
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var sparks_particles: CPUParticles2D = $SparksParticles
@onready var name_label: Label = $NameLabel
@onready var minigame_ui: Control = $MinigameUI
@onready var minigame_label: Label = $MinigameUI/Label

func _ready() -> void:
	if name_label: name_label.text = station_name
	if progress_bar: progress_bar.hide()
	if warning_icon: warning_icon.hide()
	if sparks_particles: sparks_particles.emitting = false
	if minigame_ui: minigame_ui.hide()
	update_status_visual()

func setup_minigame(type: String, assigned_role: String, pair: RepairStation) -> void:
	minigame_type = type
	role = assigned_role
	paired_station = pair
	
	# Inicializa estado do minigame
	mg_state.clear()
	if minigame_type == "password":
		if role == "A":
			mg_state["password"] = generate_password(4)
		else:
			mg_state["input_idx"] = 0
			mg_state["user_inputs"] = []
			mg_state["attempts"] = 0
	elif minigame_type == "item":
		if role == "A":
			mg_state["has_item"] = true
		else:
			mg_state["needs_item"] = true
	elif minigame_type == "skillcheck":
		if role == "A":
			mg_state["needle"] = 0.0
			mg_state["target_start"] = randf_range(0.2, 0.6)
			mg_state["target_end"] = mg_state["target_start"] + 0.2
		else:
			mg_state["button_active"] = false
			mg_state["toggle_timer"] = 0.0
	elif minigame_type == "simon":
		mg_state["sequence"] = []
		mg_state["turn"] = "A" # A começa
		mg_state["input_idx"] = 0
		mg_state["round"] = 1
		if role == "A": generate_simon_step()

	update_minigame_ui()

func generate_password(length: int) -> Array:
	var pwd = []
	for i in range(length):
		pwd.append(["UP", "DOWN", "LEFT", "RIGHT"].pick_random())
	return pwd

func generate_new_password() -> void:
	if minigame_type != "password": return
	
	var station_a = self if role == "A" else paired_station
	var station_b = self if role == "B" else paired_station
	
	if station_a:
		var old_pwd = station_a.mg_state.get("password", [])
		var new_pwd = station_a.generate_password(4)
		var attempts = 0
		while new_pwd == old_pwd and attempts < 10:
			new_pwd = station_a.generate_password(4)
			attempts += 1
		station_a.mg_state["password"] = new_pwd
		station_a.update_minigame_ui()
		
	if station_b:
		station_b.mg_state["user_inputs"] = []
		station_b.mg_state["input_idx"] = 0
		station_b.mg_state["attempts"] = 0
		station_b.update_minigame_ui()

func generate_simon_step() -> void:
	var colors = ["RED", "BLUE", "GREEN", "YELLOW"]
	mg_state["sequence"].append(colors.pick_random())

func _process(delta: float) -> void:
	if status == "BROKEN":
		if warning_icon:
			warning_icon.scale = Vector2.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.01))
		process_minigame(delta)
	sfx_cooldown -= delta

func is_broken() -> bool:
	return status == "BROKEN"

func get_minigame_type() -> String:
	return minigame_type

func break_down() -> void:
	if status == "BROKEN": return
	status = "BROKEN"
	if warning_icon: warning_icon.show()
	if sparks_particles: sparks_particles.emitting = true
	if minigame_ui: minigame_ui.show()
	
	# Reseta estado do minigame ao quebrar
	if minigame_type == "password" and role == "B":
		generate_new_password()
	elif minigame_type == "skillcheck" and role == "A":
		mg_state["needle"] = 0.0
	elif minigame_type == "simon":
		mg_state["sequence"] = []
		mg_state["turn"] = "A"
		mg_state["input_idx"] = 0
		mg_state["round"] = 1
		if role == "A": generate_simon_step()

	update_status_visual()
	update_minigame_ui()
	SoundManager.play(get_tree(), "hit", 0.2)
	station_broken.emit(self)
	
	# Quebra o par também, se for sincronizado
	if paired_station and not paired_station.is_broken():
		paired_station.break_down()

func process_minigame(delta: float) -> void:
	if minigame_type == "skillcheck":
		if role == "A":
			mg_state["needle"] = wrapf(mg_state["needle"] + delta * 0.8, 0.0, 1.0)
			update_minigame_ui()
		elif role == "B":
			mg_state["toggle_timer"] -= delta
			if mg_state["toggle_timer"] <= 0:
				mg_state["button_active"] = not mg_state["button_active"]
				mg_state["toggle_timer"] = randf_range(1.0, 3.0)
				update_minigame_ui()

func repair_tick(delta: float, player: Node = null) -> void:
	if status != "BROKEN": return
	
	# Lógica específica de cada minigame ao interagir
	var fixed_now = false
	
	if minigame_type == "password":
		if role == "A":
			# Apenas lê a senha
			pass 
		elif role == "B":
			# No caso B, a senha é inserida pelas setas/WASD pelo jogador B
			# Isso requer detecção de input específica no B, que o player script fará
			pass
			
	elif minigame_type == "item":
		if role == "A":
			# Pegar item
			if mg_state.get("has_item", false) and player:
				player.carried_item = true
				mg_state["has_item"] = false
				update_minigame_ui()
				SoundManager.play(get_tree(), "powerup", 0.3)
		elif role == "B":
			if player and player.carried_item:
				player.carried_item = false
				fixed_now = true

	elif minigame_type == "skillcheck":
		if role == "B":
			# Tenta clicar no botão
			if mg_state.get("button_active", false):
				# Verifica a agulha na máquina A
				var n = paired_station.mg_state.get("needle", 0.0)
				var s = paired_station.mg_state.get("target_start", 0.0)
				var e = paired_station.mg_state.get("target_end", 0.0)
				if n >= s and n <= e:
					fixed_now = true
				else:
					SoundManager.play(get_tree(), "lose", 0.5) # Errou
			else:
				SoundManager.play(get_tree(), "lose", 0.5) # Clicou desligado

	elif minigame_type == "simon":
		# Simon says: O input real será tratado pelo script do player chamando um método específico
		pass

	if fixed_now:
		fix_station()

func receive_minigame_input(input_val: String) -> void:
	if status != "BROKEN": return
	
	if minigame_type == "password" and role == "B":
		var pwd = paired_station.mg_state.get("password", []) if paired_station else []
		var n_setas = pwd.size()
		if n_setas == 0:
			n_setas = 4
		
		var user_inputs: Array = mg_state.get("user_inputs", [])
		user_inputs.append(input_val)
		mg_state["user_inputs"] = user_inputs
		var attempts = user_inputs.size()
		mg_state["attempts"] = attempts
		
		if attempts < n_setas:
			SoundManager.play(get_tree(), "click", 0.2)
			update_minigame_ui()
		else:
			# attempts >= n_setas (atingiu / ultrapassou n_setas)
			if user_inputs == pwd:
				# Acertou todas as setas!
				SoundManager.play(get_tree(), "click", 0.2)
				generate_new_password()
				fix_station()
			else:
				# Errou!
				SoundManager.play(get_tree(), "lose", 0.2)
				generate_new_password()
		return

	elif minigame_type == "simon":
		if mg_state.get("turn") == role:
			var seq = mg_state.get("sequence", [])
			var idx = mg_state.get("input_idx", 0)
			if idx < seq.size():
				if seq[idx] == input_val:
					mg_state["input_idx"] = idx + 1
					SoundManager.play(get_tree(), "click", 0.2)
					if mg_state["input_idx"] >= seq.size():
						# Terminou o turno!
						if mg_state["round"] >= 3 and role == "B":
							fix_station()
						else:
							# Passa pro outro
							var next_role = "B" if role == "A" else "A"
							paired_station.mg_state["sequence"] = seq.duplicate()
							paired_station.generate_simon_step()
							paired_station.mg_state["turn"] = next_role
							paired_station.mg_state["input_idx"] = 0
							paired_station.mg_state["round"] = mg_state["round"] + (1 if role == "B" else 0)
							paired_station.update_minigame_ui()
							
							mg_state["turn"] = next_role
							update_minigame_ui()
				else:
					# Errou o simon! Reseta para o A
					mg_state["sequence"] = []
					mg_state["turn"] = "A"
					mg_state["input_idx"] = 0
					mg_state["round"] = 1
					if role == "A": generate_simon_step()
					else:
						paired_station.mg_state["sequence"] = []
						paired_station.mg_state["turn"] = "A"
						paired_station.mg_state["input_idx"] = 0
						paired_station.mg_state["round"] = 1
						paired_station.generate_simon_step()
						paired_station.update_minigame_ui()
					SoundManager.play(get_tree(), "lose", 0.2)
		update_minigame_ui()


func fix_station() -> void:
	status = "OK"
	if warning_icon: warning_icon.hide()
	if sparks_particles: sparks_particles.emitting = false
	if minigame_ui: minigame_ui.hide()
	update_status_visual()
	SoundManager.play(get_tree(), "powerup", 0.1)
	station_fixed.emit(self)
	
	# Conserta o par junto
	if paired_station and paired_station.is_broken():
		paired_station.fix_station()

func update_status_visual() -> void:
	if status_light:
		status_light.color = Color(0.2, 0.9, 0.3) if status == "OK" else Color(1.0, 0.2, 0.2)

func update_minigame_ui() -> void:
	if not minigame_label: return
	
	var txt = ""
	if minigame_type == "password":
		if role == "A":
			var pwd_str = ""
			for dir in mg_state.get("password", []):
				match dir:
					"UP": pwd_str += "[↑] "
					"DOWN": pwd_str += "[↓] "
					"LEFT": pwd_str += "[←] "
					"RIGHT": pwd_str += "[→] "
			txt = "Senha:\n" + pwd_str.strip_edges()
		else:
			var attempts = mg_state.get("user_inputs", []).size()
			var total = 4
			if paired_station and paired_station.mg_state.has("password"):
				total = paired_station.mg_state["password"].size()
			txt = "Insira a Senha\nProgresso: %d/%d" % [attempts, total]
	elif minigame_type == "item":
		if role == "A":
			txt = "Peça pronta!" if mg_state.get("has_item", false) else "Aguardando..."
		else:
			txt = "Precisa de Peça!"
	elif minigame_type == "skillcheck":
		if role == "A":
			txt = "Alvo: %.1f a %.1f\nPonteiro: %.1f" % [mg_state.get("target_start",0), mg_state.get("target_end",0), mg_state.get("needle",0)]
		else:
			txt = "[BOTAO ATIVO]" if mg_state.get("button_active", false) else "[OFF]"
	elif minigame_type == "simon":
		if mg_state.get("turn") == role:
			txt = "SUA VEZ!\nSeq: " + str(mg_state.get("sequence", [])) + "\n" + str(mg_state.get("input_idx", 0)) + " ok"
		else:
			txt = "Aguarde o parceiro..."

	minigame_label.text = txt
