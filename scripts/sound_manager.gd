extends Node
class_name SoundManager

# Gerenciador global de efeitos sonoros
# Reproduz arquivos da pasta res://sfx/

static var bgm_player: AudioStreamPlayer = null

static func play(tree: SceneTree, sound_name: String, pitch_range: float = 0.1) -> void:
	if tree == null or tree.root == null:
		return
	var path = "res://sfx/" + sound_name + ".wav"
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	tree.root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

static func play_bgm(tree: SceneTree, music_path: String = "res://assets/Ost/MELHOR loop fundo principal.mp3", volume_db: float = -15.0) -> void:
	if tree == null or tree.root == null:
		return
	if bgm_player and is_instance_valid(bgm_player):
		if bgm_player.playing:
			return # Já está tocando suavemente
	if not ResourceLoader.exists(music_path):
		return
	var stream = load(music_path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	
	if bgm_player == null or not is_instance_valid(bgm_player):
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
		bgm_player.stream = stream
		bgm_player.volume_db = volume_db
		bgm_player.finished.connect(func():
			if is_instance_valid(bgm_player):
				bgm_player.play()
		)
		tree.root.add_child.call_deferred(bgm_player)
		bgm_player.call_deferred("play")
	else:
		bgm_player.stream = stream
		bgm_player.volume_db = volume_db
		if not bgm_player.is_inside_tree():
			tree.root.add_child.call_deferred(bgm_player)
			bgm_player.call_deferred("play")
		else:
			bgm_player.play()

static func stop_bgm() -> void:
	if bgm_player and is_instance_valid(bgm_player):
		bgm_player.stop()

static func set_bgm_volume(volume_db: float) -> void:
	if bgm_player and is_instance_valid(bgm_player):
		bgm_player.volume_db = volume_db
