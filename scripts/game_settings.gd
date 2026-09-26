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
static var is_tutorial_mode: bool = false


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

static func get_difficulty_description() -> String:
	match difficulty:
		Difficulty.EASY:
			return "• Simon: 2 rodadas\n• Senha: 3 setas\n• Skillcheck: 60° (amplo)\n• Esteira: lenta (50 px/s)"
		Difficulty.NORMAL:
			return "• Simon: 3 rodadas\n• Senha: 4 setas\n• Skillcheck: 40° (normal)\n• Esteira: média (75 px/s)"
		Difficulty.HARD:
			return "• Simon: 5 rodadas\n• Senha: 6 setas\n• Skillcheck: 22° (estreito)\n• Esteira: rápida (125 px/s)"
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
		Difficulty.EASY: return 50.0
		Difficulty.NORMAL: return 75.0
		Difficulty.HARD: return 125.0
	return 75.0
