class_name GameManager
extends RefCounted

var current_round: int = 1
var round_manager := RoundManager.new()

func start_game() -> void:
	current_round = 1
	round_manager.start_round(current_round)

func finish_current_round() -> RoundResult:
	var result = round_manager.finish_round()
	if result.target_reached:
		current_round += 1
		round_manager.start_round(current_round)
	return result

func start_next_round() -> void:
	current_round += 1
	round_manager.start_round(current_round)
