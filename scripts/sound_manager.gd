extends Node
class_name SoundManager

# Gerenciador global de efeitos sonoros e trilha sonora (OST)
# Reproduz arquivos da pasta res://sfx/ e res://assets/Ost/

static var _music_player: AudioStreamPlayer = null
static var _current_music_path: String = ""

static func play(tree: SceneTree, sound_name: String, pitch_range: float = 0.1) -> void:
	if tree == null or tree.root == null:
		return
	if GameSettings.sfx_volume <= 0.01:
		return # Mudo
		
	var path = "res://sfx/" + sound_name + ".wav"
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(GameSettings.sfx_volume)
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	player.finished.connect(player.queue_free)
	tree.root.add_child.call_deferred(player)
	player.ready.connect(player.play)

static func play_music(tree: SceneTree, path: String) -> void:
	if tree == null or tree.root == null:
		return
	
	_current_music_path = path
	
	# Cria player se não existir
	if _music_player == null or not is_instance_valid(_music_player):
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "GlobalMusicPlayer"
		_music_player.bus = "Master"
		_music_player.process_mode = Node.PROCESS_MODE_ALWAYS # Toca mesmo pausado
		_music_player.finished.connect(func():
			if is_instance_valid(_music_player) and _current_music_path != "":
				_music_player.play() # Loop contínuo
		)
		tree.root.add_child.call_deferred(_music_player)
	
	_deferred_play_music.call_deferred(path)

static func _deferred_play_music(path: String) -> void:
	if not is_instance_valid(_music_player) or not _music_player.is_inside_tree():
		if is_instance_valid(_music_player) and not _music_player.ready.is_connected(_on_music_player_ready):
			_music_player.ready.connect(_on_music_player_ready, CONNECT_ONE_SHOT)
		return
	
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			if _music_player.stream != stream:
				_music_player.stream = stream
				update_music_volume()
				_music_player.play()
			elif not _music_player.playing:
				update_music_volume()
				_music_player.play()
			else:
				update_music_volume()

static func _on_music_player_ready() -> void:
	if _current_music_path != "":
		_deferred_play_music(_current_music_path)

static func stop_music() -> void:
	_current_music_path = ""
	if _music_player and is_instance_valid(_music_player):
		_music_player.stop()

static func update_music_volume() -> void:
	if _music_player and is_instance_valid(_music_player):
		if GameSettings.music_volume <= 0.01:
			_music_player.volume_db = -80.0
		else:
			_music_player.volume_db = linear_to_db(GameSettings.music_volume)

static func set_music_volume(volume: float) -> void:
	GameSettings.music_volume = clamp(volume, 0.0, 1.0)
	update_music_volume()

static func set_sfx_volume(volume: float) -> void:
	GameSettings.sfx_volume = clamp(volume, 0.0, 1.0)

static func get_music_volume() -> float:
	return GameSettings.music_volume

static func get_sfx_volume() -> float:
	return GameSettings.sfx_volume
