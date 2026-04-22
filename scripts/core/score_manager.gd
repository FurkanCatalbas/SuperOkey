class_name ScoreManager
extends RefCounted

const JOKER_SLOT_COUNT := 5

var validator := CombinationValidator.new()
var owned_joker_cards: Array = []
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func roll_joker_cards(slot_count: int = JOKER_SLOT_COUNT) -> void:
	owned_joker_cards.clear()
	var pool := _build_joker_pool()
	pool.shuffle()
	for index in range(min(slot_count, pool.size())):
		owned_joker_cards.append(pool[index])

func get_owned_joker_cards() -> Array:
	return owned_joker_cards.duplicate()

func score_group(group: GroupData) -> GroupValidationResult:
	var validation: GroupValidationResult = validator.validate_group(group)
	if not validation.is_valid:
		return validation
	for card in owned_joker_cards:
		var joker_card: JokerCardData = card
		if joker_card.matches(validation):
			validation.apply_joker_card(joker_card)
	return validation

func evaluate_round(groups: Array, hand_tiles: Array, target_score: int) -> RoundResult:
	var result := RoundResult.new()
	var total_chips := 0
	var multiplier := 1.0
	var valid_pair_count := 0

	for group in groups:
		var validation: GroupValidationResult = score_group(group)
		result.group_results.append(validation)
		if validation.is_valid:
			total_chips += validation.chips
			multiplier += validation.multiplier_bonus
			if validation.detected_type == CombinationValidator.TYPE_CIFTE:
				valid_pair_count += 1

	if valid_pair_count >= 3:
		multiplier += 0.4
	elif valid_pair_count >= 2:
		multiplier += 0.2

	result.unused_tiles = hand_tiles.duplicate()
	result.total_score = total_chips
	result.penalty_score = result.unused_tiles.size() * 3
	result.multiplier = multiplier
	result.net_score = float(result.total_score - result.penalty_score) * result.multiplier
	result.target_reached = result.net_score >= target_score
	return result

func _build_joker_pool() -> Array:
	return [
		JokerCardData.new({
			"id": "pair_master",
			"title": "Cifte Ustasi",
			"description": "Gecerli cifteler x3 puan verir.",
			"target_type": CombinationValidator.TYPE_CIFTE,
			"multiplier": 3.0
		}),
		JokerCardData.new({
			"id": "joker_pair",
			"title": "Sahte Es",
			"description": "Jokerli cifteler x2 puan verir.",
			"target_type": CombinationValidator.TYPE_CIFTE,
			"requires_joker": true,
			"multiplier": 2.0
		}),
		JokerCardData.new({
			"id": "long_run",
			"title": "Uzun Seri",
			"description": "5+ tasli seriler x2 puan verir.",
			"target_type": CombinationValidator.TYPE_SERI,
			"min_size": 5,
			"multiplier": 2.0
		}),
		JokerCardData.new({
			"id": "ultra_run",
			"title": "Turbo Seri",
			"description": "6+ tasli seriler x2.5 puan verir.",
			"target_type": CombinationValidator.TYPE_SERI,
			"min_size": 6,
			"multiplier": 2.5
		}),
		JokerCardData.new({
			"id": "four_set",
			"title": "Dortlu Per",
			"description": "4'lu perler x2 puan verir.",
			"target_type": CombinationValidator.TYPE_PER,
			"exact_size": 4,
			"multiplier": 2.0
		}),
		JokerCardData.new({
			"id": "high_set",
			"title": "Yuksek Per",
			"description": "12-13 degerli perler x2 puan verir.",
			"target_type": CombinationValidator.TYPE_PER,
			"min_value": 12,
			"multiplier": 2.0
		}),
		JokerCardData.new({
			"id": "mid_set",
			"title": "Usta Per",
			"description": "9-11 degerli perler x1.8 puan verir.",
			"target_type": CombinationValidator.TYPE_PER,
			"min_value": 9,
			"max_value": 11,
			"multiplier": 1.8
		})
	]
