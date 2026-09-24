extends Node
class_name SoundManager

# Gerenciador global de efeitos sonoros
# Reproduz arquivos da pasta res://sfx/

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
