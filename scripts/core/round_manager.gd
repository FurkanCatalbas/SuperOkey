class_name RoundManager
extends RefCounted

var current_round: int = 1
var target_score: int = 50

var hand_model := HandModel.new()
var deck_manager := DeckManager.new()
var combination_finder := CombinationFinder.new()
var score_manager := ScoreManager.new()

func start_round(round_number: int) -> void:
	current_round = round_number
	target_score = _calculate_target_score(round_number)

	deck_manager.build_deck()
	deck_manager.shuffle_deck()
	hand_model.clear()

	var starting_tiles = deck_manager.draw_multiple(GameConstants.STARTING_HAND_SIZE)
	hand_model.set_tiles(starting_tiles)
	hand_model.sort_by_color_then_value()

func draw_one_tile() -> GameTileData:
	var tile = deck_manager.draw_tile()
	hand_model.add_tile(tile)
	return tile

func finish_round() -> RoundResult:
	var combos = combination_finder.find_best_combinations(hand_model.tiles)
	var result = score_manager.evaluate_hand(hand_model.tiles, combos, target_score)
	result.round_number = current_round
	return result

func _calculate_target_score(round_number: int) -> int:
	return 50 + ((round_number - 1) * 50)
