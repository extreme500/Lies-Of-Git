extends Node
class_name GameSettings

enum Difficulty {
	EASY = 0,
	NORMAL = 1,
	HARD = 2
}

static var difficulty: Difficulty = Difficulty.NORMAL
static var music_volume: float = 0.8
static var sfx_volume: float = 0.9

static func set_difficulty(d: Difficulty) -> void:
	difficulty = d

static func cycle_difficulty() -> Difficulty:
	match difficulty:
		Difficulty.EASY:
			difficulty = Difficulty.NORMAL
		Difficulty.NORMAL:
			difficulty = Difficulty.HARD
		Difficulty.HARD:
			difficulty = Difficulty.EASY
	return difficulty

static func get_difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY: return "Fácil"
		Difficulty.NORMAL: return "Normal"
		Difficulty.HARD: return "Difícil"
	return "Normal"
	
static func get_difficulty_colour() -> Color:
	match difficulty:
		Difficulty.EASY: return Color(0.25, 0.95, 0.45) # Verde limão vibrante
		Difficulty.NORMAL: return Color(1.0, 0.72, 0.2) # Âmbar/Laranja
		Difficulty.HARD: return Color(1.0, 0.28, 0.28) # Vermelho vivo e legível
	return Color(1.0, 0.72, 0.2)

static func get_difficulty_color() -> Color:
	return get_difficulty_colour()

static func get_difficulty_description() -> String:
	match difficulty:
		Difficulty.EASY:
			return "Genius: 2 rodadas\n Senha: 3 setas\n Skillcheck: 60° (amplo)\n Esteira: lenta   "
		Difficulty.NORMAL:
			return "Genius: 3 rodadas\n Senha: 4 setas\n Skillcheck: 40° (normal)\n Esteira: média   "
		Difficulty.HARD:
			return "Genius: 5 rodadas\n Senha: 6 setas\n Skillcheck: 22° (estreito)\n Esteira: rápida   "
	return ""

static func get_simon_iterations() -> int:
	match difficulty:
		Difficulty.EASY: return 2
		Difficulty.NORMAL: return 3
		Difficulty.HARD: return 5
	return 3

static func get_password_length() -> int:
	match difficulty:
		Difficulty.EASY: return 3
		Difficulty.NORMAL: return 4
		Difficulty.HARD: return 6
	return 4

static func get_skillcheck_target_angle_deg() -> float:
	match difficulty:
		Difficulty.EASY: return 60.0
		Difficulty.NORMAL: return 40.0
		Difficulty.HARD: return 22.0
	return 40.0

static func get_conveyor_speed() -> float:
	match difficulty:
		Difficulty.EASY: return 60.0
		Difficulty.NORMAL: return 75.0
		Difficulty.HARD: return 110.0
	return 75.0
