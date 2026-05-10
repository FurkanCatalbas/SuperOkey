class_name PokerGameManager
extends RefCounted

const HAND_SIZE := 8
const MAX_SELECTED := 3
const STARTING_HANDS := 4
const STARTING_DISCARDS := 3

var score: int = 0
var round: int = 1
var target_score: int = 300
var hands_left: int = STARTING_HANDS
var discards_left: int = STARTING_DISCARDS
var hand: Array = []
var deck: Array = []
var last_result: Dictionary = {}

func start_run() -> void:
	score = 0
	round = 1
	target_score = _target_for_round(round)
	hands_left = STARTING_HANDS
	discards_left = STARTING_DISCARDS
	last_result = {}
	_start_round()

func play_selected(selected_ids: Array) -> Dictionary:
	if selected_ids.is_empty() or selected_ids.size() > MAX_SELECTED or hands_left <= 0:
		return {}

	var selected_cards := _cards_by_ids(selected_ids)
	if selected_cards.is_empty():
		return {}

	var evaluation := evaluate_cards(selected_cards)
	score += evaluation["score"]
	hands_left -= 1
	last_result = evaluation
	_remove_cards(selected_ids)
	_refill_hand()

	if score >= target_score:
		round += 1
		target_score = _target_for_round(round)
		hands_left = STARTING_HANDS
		discards_left = STARTING_DISCARDS
		_start_round()
		last_result["round_advanced"] = true
	elif hands_left <= 0:
		last_result["run_over"] = true

	return last_result

func discard_selected(selected_ids: Array) -> bool:
	if selected_ids.is_empty() or selected_ids.size() > MAX_SELECTED or discards_left <= 0:
		return false
	discards_left -= 1
	_remove_cards(selected_ids)
	_refill_hand()
	last_result = {"name": "Kart Degistirildi", "score": 0, "multiplier": 0, "chips": 0}
	return true

func evaluate_cards(cards: Array) -> Dictionary:
	var ranks: Array[int] = []
	var suit_counts := {}
	var rank_counts := {}
	for card in cards:
		var rank: int = card["rank"]
		ranks.append(rank)
		suit_counts[card["suit"]] = suit_counts.get(card["suit"], 0) + 1
		rank_counts[rank] = rank_counts.get(rank, 0) + 1

	ranks.sort()
	var counts: Array[int] = []
	for rank in rank_counts.keys():
		counts.append(rank_counts[rank])
	counts.sort()
	counts.reverse()

	var flush := suit_counts.size() == 1 and cards.size() == MAX_SELECTED
	var straight := _is_straight(ranks) and cards.size() == MAX_SELECTED
	var base_chips := 0
	for rank in ranks:
		base_chips += min(rank, 10)

	var hand_name := "Yuksek Kart"
	var chips := base_chips + 5
	var multiplier := 1

	if straight and flush:
		hand_name = "Straight Flush"
		chips = base_chips + 45
		multiplier = 5
	elif flush:
		hand_name = "Flush"
		chips = base_chips + 28
		multiplier = 3
	elif straight:
		hand_name = "Straight"
		chips = base_chips + 24
		multiplier = 3
	elif counts[0] == 3:
		hand_name = "Uc Ayni"
		chips = base_chips + 35
		multiplier = 4
	elif counts[0] == 2:
		hand_name = "Cift"
		chips = base_chips + 12
		multiplier = 2

	return {
		"name": hand_name,
		"chips": chips,
		"multiplier": multiplier,
		"score": chips * multiplier,
	}

func _start_round() -> void:
	deck = _build_deck()
	deck.shuffle()
	hand = []
	_refill_hand()

func _build_deck() -> Array:
	var cards := []
	var suits := ["red", "white", "black", "blue"]
	var id_counter := 0
	for suit in suits:
		for rank in range(1, 9):
			id_counter += 1
			cards.append({
				"id": "poker_%d" % id_counter,
				"rank": rank,
				"suit": suit,
			})
	return cards

func _refill_hand() -> void:
	while hand.size() < HAND_SIZE and not deck.is_empty():
		hand.append(deck.pop_back())

func _remove_cards(card_ids: Array) -> void:
	var next_hand := []
	for card in hand:
		if not card_ids.has(card["id"]):
			next_hand.append(card)
	hand = next_hand

func _cards_by_ids(card_ids: Array) -> Array:
	var cards := []
	for card in hand:
		if card_ids.has(card["id"]):
			cards.append(card)
	return cards

func _is_straight(sorted_ranks: Array[int]) -> bool:
	if sorted_ranks.size() != MAX_SELECTED:
		return false
	var unique := []
	for rank in sorted_ranks:
		if unique.has(rank):
			return false
		unique.append(rank)
	for index in range(1, unique.size()):
		if unique[index] != unique[index - 1] + 1:
			return false
	return true

func _target_for_round(round_number: int) -> int:
	return 300 + ((round_number - 1) * 180)
