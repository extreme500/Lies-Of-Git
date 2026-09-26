extends Node
class_name SoundManager

# Gerenciador global de efeitos sonoros e trilha sonora (OST)
# Reproduz arquivos da pasta res://sfx/ e res://assets/Ost/

static var _music_player: AudioStreamPlayer = null
static var _current_music_path: String = ""
static var sfx_default_volume_db: float = -8.0

static func play(tree: SceneTree, sound_name: String, pitch_range: float = 0.1, custom_volume_db: float = -999.0) -> void:
	if tree == null or tree.root == null:
		return
	var sfx_vol = GameSettings.sfx_volume if "sfx_volume" in GameSettings else 0.9
	if sfx_vol <= 0.01:
		return
	var path = "res://sfx/" + sound_name + ".wav"
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	var base_db = custom_volume_db if custom_volume_db != -999.0 else sfx_default_volume_db
	player.volume_db = base_db + linear_to_db(sfx_vol)
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	player.finished.connect(player.queue_free)
	tree.root.add_child.call_deferred(player)
	player.call_deferred("play")

static func play_music(tree: SceneTree, path: String) -> void:
	play_bgm(tree, path)

static func play_bgm(tree: SceneTree, music_path: String = "res://assets/Ost/MELHOR loop fundo principal.mp3", _volume_db: float = -12.0) -> void:
	if tree == null or tree.root == null:
		return
	_current_music_path = music_path
	if not ResourceLoader.exists(music_path):
		return
	var stream = load(music_path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	
	if _music_player == null or not is_instance_valid(_music_player):
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "GlobalMusicPlayer"
		_music_player.bus = "Master"
		_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		_music_player.finished.connect(func():
			if is_instance_valid(_music_player) and _current_music_path != "":
				_music_player.play()
		)
		tree.root.add_child.call_deferred(_music_player)
	
	_deferred_play_music.call_deferred(music_path, stream)

static func _deferred_play_music(path: String, stream: AudioStream) -> void:
	if not is_instance_valid(_music_player) or not _music_player.is_inside_tree():
		if is_instance_valid(_music_player) and not _music_player.ready.is_connected(_on_music_player_ready):
			_music_player.ready.connect(_on_music_player_ready, CONNECT_ONE_SHOT)
		return
	
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
	if _current_music_path != "" and ResourceLoader.exists(_current_music_path):
		var s = load(_current_music_path)
		if s:
			_deferred_play_music(_current_music_path, s)

static func stop_music() -> void:
	_current_music_path = ""
	if _music_player and is_instance_valid(_music_player):
		_music_player.stop()

static func stop_bgm() -> void:
	stop_music()

static func update_music_volume() -> void:
	if _music_player and is_instance_valid(_music_player):
		var music_vol = GameSettings.music_volume if "music_volume" in GameSettings else 0.8
		if music_vol <= 0.01:
			_music_player.volume_db = -80.0
		else:
			_music_player.volume_db = -12.0 + linear_to_db(music_vol)

static func set_music_volume(volume: float) -> void:
	if "music_volume" in GameSettings:
		GameSettings.music_volume = clamp(volume, 0.0, 1.0)
	update_music_volume()

static func set_sfx_volume(volume: float) -> void:
	if "sfx_volume" in GameSettings:
		GameSettings.sfx_volume = clamp(volume, 0.0, 1.0)

static func get_music_volume() -> float:
	return GameSettings.music_volume if "music_volume" in GameSettings else 0.8

static func get_sfx_volume() -> float:
	return GameSettings.sfx_volume if "sfx_volume" in GameSettings else 0.9

static func set_bgm_volume(volume_db: float) -> void:
	if _music_player and is_instance_valid(_music_player):
		_music_player.volume_db = volume_db
