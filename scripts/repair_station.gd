extends Node2D
class_name RepairStation

signal station_broken(station: RepairStation)
signal station_fixed(station: RepairStation)

@export var station_name: String = "Terminal"
@export var station_type: String = "terminal"
@export var chamber_id: int = 1

var status: String = "OK" # "OK" ou "BROKEN"
@export var minigame_type: String = ""
var role: String = "" # "A" ou "B"
var paired_station: RepairStation = null
var sfx_cooldown: float = 0.0
var is_interacting: bool = false
var _interact_timer: float = 0.0
var _skillcheck_visual_active: bool = false

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
@onready var arrow_container: HBoxContainer = $MinigameUI/ArrowContainer if has_node("MinigameUI/ArrowContainer") else null

var _arrow_textures_cache: Dictionary = {}

func _ready() -> void:
	if name_label: name_label.text = station_name
	if progress_bar: progress_bar.hide()
	if warning_icon: warning_icon.hide()
	if sparks_particles: sparks_particles.emitting = false
	if minigame_ui: minigame_ui.hide()
	if not arrow_container and minigame_ui:
		arrow_container = minigame_ui.get_node_or_null("ArrowContainer")
		if not arrow_container:
			arrow_container = HBoxContainer.new()
			arrow_container.name = "ArrowContainer"
			arrow_container.alignment = BoxContainer.ALIGNMENT_CENTER
			arrow_container.add_theme_constant_override("separation", 12)
			arrow_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			arrow_container.offset_top = -38.0
			arrow_container.offset_bottom = -8.0
			minigame_ui.add_child(arrow_container)
	if arrow_container:
		arrow_container.hide()
	update_status_visual()
	call_deferred("snap_to_surface")

func snap_to_surface() -> void:
	if not is_inside_tree() or not get_world_2d():
		return
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return
	var from_pos = global_position - Vector2(0, 30)
	var to_pos = global_position + Vector2(0, 500)
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 1 # Chão e plataformas
	var result = space_state.intersect_ray(query)
	if result and not result.is_empty():
		global_position.y = result.position.y - 20.0

func set_interacting(val: bool) -> void:
	is_interacting = val
	if not val:
		_interact_timer = 0.0
	else:
		_interact_timer = 0.3
	update_ui_visibility()

func update_ui_visibility() -> void:
	if minigame_type == "skillcheck" and role == "A":
		_set_skillcheck_visual_visible(is_interacting)

	if not minigame_ui: return
	if status != "BROKEN":
		minigame_ui.visible = false
		return
	
	if minigame_type in ["password", "skillcheck", "simon"]:
		minigame_ui.visible = is_interacting
	else:
		minigame_ui.visible = true

func _exit_tree() -> void:
	if minigame_type == "skillcheck" and role == "A":
		_set_skillcheck_visual_visible(false)

func _position_skillcheck_visual_over_station() -> void:
	if not is_inside_tree(): return
	var nodes = get_tree().get_nodes_in_group("skillcheck_visual")
	if nodes.is_empty() and get_tree().current_scene:
		var angulo = get_tree().current_scene.find_child("AnguloSC", true, false)
		if angulo: nodes.append(angulo)
		var centro = get_tree().current_scene.find_child("CentroSC", true, false)
		if centro and not nodes.has(centro): nodes.append(centro)
	for n in nodes:
		if is_instance_valid(n):
			if n.name == "AnguloSC":
				n.global_position = global_position + Vector2(0, -60)
			elif n.name == "CentroSC":
				var p = n.get_parent()
				if p and p.name == "AnguloSC":
					p.global_position = global_position + Vector2(0, -60)
					n.position = Vector2.ZERO
				else:
					n.global_position = global_position + Vector2(0, -60)

func _set_skillcheck_visual_visible(val: bool) -> void:
	if _skillcheck_visual_active == val:
		return
	_skillcheck_visual_active = val
	if not is_inside_tree():
		return
	
	if val:
		_position_skillcheck_visual_over_station()
	
	var nodes = get_tree().get_nodes_in_group("skillcheck_visual")
	if nodes.is_empty() and get_tree().current_scene:
		var angulo = get_tree().current_scene.find_child("AnguloSC", true, false)
		if angulo:
			nodes.append(angulo)
		var centro = get_tree().current_scene.find_child("CentroSC", true, false)
		if centro and not nodes.has(centro):
			nodes.append(centro)
			
	for n in nodes:
		if is_instance_valid(n):
			if n.has_method("set_active"):
				n.set_active(val)
			else:
				n.visible = val

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
			call_deferred("_position_skillcheck_visual_over_station")
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
	
	if is_interacting:
		_interact_timer -= delta
		if _interact_timer <= 0.0:
			set_interacting(false)

func is_broken() -> bool:
	return status == "BROKEN"

func get_minigame_type() -> String:
	return minigame_type

func break_down() -> void:
	if status == "BROKEN": return
	status = "BROKEN"
	if warning_icon: warning_icon.show()
	if sparks_particles: sparks_particles.emitting = true
	update_ui_visibility()
	
	# Reseta estado do minigame ao quebrar
	if minigame_type == "password" and role == "B":
		generate_new_password()
	elif minigame_type == "skillcheck" and role == "A":
		mg_state["needle"] = 0.0
		var centro_nodes = get_tree().get_nodes_in_group("centro_sc")
		for c in centro_nodes:
			if is_instance_valid(c) and c.has_method("sortear_novo_alvo"):
				c.sortear_novo_alvo()
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
	
	set_interacting(true)
	_interact_timer = 0.2
	
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
				var hit = false
				var centro_nodes = get_tree().get_nodes_in_group("centro_sc")
				if not centro_nodes.is_empty() and centro_nodes[0].has_method("is_alvo_atingido"):
					hit = centro_nodes[0].is_alvo_atingido()
				elif paired_station:
					var n = paired_station.mg_state.get("needle", 0.0)
					var s = paired_station.mg_state.get("target_start", 0.0)
					var e = paired_station.mg_state.get("target_end", 0.0)
					hit = (n >= s and n <= e)
				if hit:
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
	is_interacting = false
	_interact_timer = 0.0
	if warning_icon: warning_icon.hide()
	if sparks_particles: sparks_particles.emitting = false
	if minigame_type == "skillcheck" and role == "A":
		_set_skillcheck_visual_visible(false)
	update_ui_visibility()
	update_status_visual()
	SoundManager.play(get_tree(), "powerup", 0.1)
	station_fixed.emit(self)
	
	# Conserta o par junto
	if paired_station and paired_station.is_broken():
		paired_station.fix_station()

func update_status_visual() -> void:
	if status_light:
		status_light.color = Color(0.2, 0.9, 0.3) if status == "OK" else Color(1.0, 0.2, 0.2)

func get_arrow_texture(dir: String) -> Texture2D:
	if _arrow_textures_cache.has(dir):
		return _arrow_textures_cache[dir]
	
	var tex: Texture2D = null
	match dir:
		"UP":
			if ResourceLoader.exists("res://assets/cima.png"):
				tex = load("res://assets/cima.png")
			elif ResourceLoader.exists("res://assets/cimaa.png"):
				tex = load("res://assets/cimaa.png")
		"DOWN":
			if ResourceLoader.exists("res://assets/baixo.png"):
				tex = load("res://assets/baixo.png")
			elif ResourceLoader.exists("res://assets/baixo ).png"):
				tex = load("res://assets/baixo ).png")
		"LEFT":
			if ResourceLoader.exists("res://assets/esquerda.png"):
				tex = load("res://assets/esquerda.png")
		"RIGHT":
			if ResourceLoader.exists("res://assets/direita.png"):
				tex = load("res://assets/direita.png")
			elif ResourceLoader.exists("res://assets/direit ).png"):
				tex = load("res://assets/direit ).png")
	
	if tex:
		_arrow_textures_cache[dir] = tex
	return tex

func _create_arrow_slot(dir: String, is_placeholder: bool = false) -> Control:
	var slot = PanelContainer.new()
	var slot_style = StyleBoxFlat.new()
	slot_style.set_corner_radius_all(5)
	slot_style.set_border_width_all(1)
	
	if is_placeholder:
		slot_style.bg_color = Color(0.18, 0.22, 0.30, 0.7)
		slot_style.border_color = Color(0.35, 0.45, 0.60, 0.8)
		slot.add_theme_stylebox_override("panel", slot_style)
		slot.custom_minimum_size = Vector2(30, 30)
		
		var placeholder_label = Label.new()
		placeholder_label.text = "•"
		placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.8))
		placeholder_label.add_theme_font_size_override("font_size", 16)
		slot.add_child(placeholder_label)
	else:
		slot_style.bg_color = Color(0.92, 0.94, 0.97, 0.98)
		slot_style.border_color = Color(0.65, 0.72, 0.85, 0.95)
		slot.add_theme_stylebox_override("panel", slot_style)
		slot.custom_minimum_size = Vector2(30, 30)
		
		var tex = get_arrow_texture(dir)
		if tex:
			var tr = TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(22, 22)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			slot.add_child(tr)
	
	return slot

func update_minigame_ui() -> void:
	if not minigame_label: return
	
	if arrow_container:
		for child in arrow_container.get_children():
			arrow_container.remove_child(child)
			child.queue_free()
	
	var txt = ""
	if minigame_type == "password":
		if arrow_container:
			arrow_container.show()
			minigame_label.anchor_bottom = 0.0
			minigame_label.offset_top = 4.0
			minigame_label.offset_bottom = 26.0
		
		if role == "A":
			txt = "Senha:"
			var pwd = mg_state.get("password", [])
			if arrow_container:
				for dir in pwd:
					arrow_container.add_child(_create_arrow_slot(dir, false))
		else:
			var attempts = mg_state.get("user_inputs", []).size()
			var total = 4
			if paired_station and paired_station.mg_state.has("password"):
				total = paired_station.mg_state["password"].size()
			txt = "Insira a Senha (%d/%d):" % [attempts, total]
			if arrow_container:
				var inputs = mg_state.get("user_inputs", [])
				for dir in inputs:
					arrow_container.add_child(_create_arrow_slot(dir, false))
				for i in range(inputs.size(), total):
					arrow_container.add_child(_create_arrow_slot("", true))
	else:
		if arrow_container:
			arrow_container.hide()
			minigame_label.anchor_bottom = 1.0
			minigame_label.offset_top = 0.0
			minigame_label.offset_bottom = 0.0
		
		if minigame_type == "item":
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
	update_ui_visibility()
