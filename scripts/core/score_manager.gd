class_name ScoreManager
extends RefCounted

func evaluate_hand(hand_tiles: Array, combos: Array, target_score: int) -> RoundResult:
	var result = RoundResult.new()
	result.combos = combos.duplicate()

	var used_ids := {}
	var total_score := 0

	for combo in combos:
		var combo_score = _calculate_combo_score(combo)
		combo.base_score = combo_score
		combo.total_score = combo_score
		total_score += combo_score

		for tile in combo.tiles:
			used_ids[tile.id] = true

	var unused_tiles := []
	for tile in hand_tiles:
		if not used_ids.has(tile.id):
			unused_tiles.append(tile)

	var penalty = unused_tiles.size() * GameConstants.UNUSED_TILE_PENALTY

	result.unused_tiles = unused_tiles
	result.total_score = total_score
	result.penalty_score = penalty
	result.net_score = total_score - penalty
	result.target_reached = result.net_score >= target_score

	return result

func _calculate_combo_score(combo: ComboResult) -> int:
	if combo.combo_type == "run":
		return GameConstants.BASE_RUN_SCORE + max(0, combo.tiles.size() - 3) * GameConstants.LONG_COMBO_BONUS

	if combo.combo_type == "set":
		if combo.tiles.size() == 4:
			return 20
		return GameConstants.BASE_SET_SCORE

	return 0
