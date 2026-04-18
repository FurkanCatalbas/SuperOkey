class_name ScoreManager
extends RefCounted

var validator := CombinationValidator.new()

func evaluate_round(groups: Array, hand_tiles: Array, target_score: int) -> RoundResult:
	var result := RoundResult.new()
	var total_score := 0

	for group in groups:
		var validation: GroupValidationResult = validator.validate_group(group)
		result.group_results.append(validation)
		if validation.is_valid:
			total_score += validation.score

	result.unused_tiles = hand_tiles.duplicate()
	result.total_score = total_score
	result.penalty_score = result.unused_tiles.size() * GameConstants.UNUSED_TILE_PENALTY
	result.net_score = result.total_score - result.penalty_score
	result.target_reached = result.net_score >= target_score
	return result
