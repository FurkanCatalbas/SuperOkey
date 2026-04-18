class_name CombinationFinder
extends RefCounted

func find_best_combinations(hand_tiles: Array) -> Array:
	var set_first = _find_set_then_run(hand_tiles)
	var run_first = _find_run_then_set(hand_tiles)

	var set_first_score = _estimate_net_score(hand_tiles, set_first)
	var run_first_score = _estimate_net_score(hand_tiles, run_first)

	return set_first if set_first_score >= run_first_score else run_first

func _find_set_then_run(hand_tiles: Array) -> Array:
	var set_result = _extract_sets(hand_tiles)
	var run_result = _extract_runs(set_result.remaining)
	return set_result.combos + run_result.combos

func _find_run_then_set(hand_tiles: Array) -> Array:
	var run_result = _extract_runs(hand_tiles)
	var set_result = _extract_sets(run_result.remaining)
	return run_result.combos + set_result.combos

func _estimate_combo_score(combos: Array) -> int:
	var score := 0
	for combo in combos:
		if combo.combo_type == "run":
			score += GameConstants.BASE_RUN_SCORE + max(0, combo.tiles.size() - 3) * GameConstants.LONG_COMBO_BONUS
		elif combo.combo_type == "set":
			score += 20 if combo.tiles.size() == 4 else GameConstants.BASE_SET_SCORE
	return score

func _estimate_net_score(hand_tiles: Array, combos: Array) -> int:
	var combo_score = _estimate_combo_score(combos)
	var used_ids := {}
	for combo in combos:
		for tile in combo.tiles:
			used_ids[tile.id] = true

	var unused_count := 0
	for tile in hand_tiles:
		if not used_ids.has(tile.id):
			unused_count += 1

	return combo_score - (unused_count * GameConstants.UNUSED_TILE_PENALTY)

func _extract_sets(tiles: Array) -> Dictionary:
	var groups := {}
	var used_ids := {}
	var combos := []

	for tile in tiles:
		if tile.is_joker:
			continue
		if not groups.has(tile.value):
			groups[tile.value] = []
		groups[tile.value].append(tile)

	for value in groups.keys():
		var same_value_tiles = groups[value]
		var unique_by_color := {}
		for tile in same_value_tiles:
			if not unique_by_color.has(tile.color):
				unique_by_color[tile.color] = tile

		var candidate = unique_by_color.values()
		if candidate.size() >= 3:
			combos.append(ComboResult.new("set", candidate))
			for tile in candidate:
				used_ids[tile.id] = true

	var remaining := []
	for tile in tiles:
		if not used_ids.has(tile.id):
			remaining.append(tile)

	return {"combos": combos, "remaining": remaining}

func _extract_runs(tiles: Array) -> Dictionary:
	var color_groups := {}
	var used_ids := {}
	var combos := []

	for tile in tiles:
		if tile.is_joker:
			continue
		if not color_groups.has(tile.color):
			color_groups[tile.color] = []
		color_groups[tile.color].append(tile)

	for color in color_groups.keys():
		var arr = color_groups[color]
		if arr.is_empty():
			continue
		arr.sort_custom(func(a, b): return a.value < b.value)

		var current_run := [arr[0]]
		for i in range(1, arr.size()):
			if arr[i].value == arr[i - 1].value + 1:
				current_run.append(arr[i])
			elif arr[i].value == arr[i - 1].value:
				continue
			else:
				if current_run.size() >= 3:
					combos.append(ComboResult.new("run", current_run.duplicate()))
					for tile in current_run:
						used_ids[tile.id] = true
				current_run = [arr[i]]

		if current_run.size() >= 3:
			combos.append(ComboResult.new("run", current_run.duplicate()))
			for tile in current_run:
				used_ids[tile.id] = true

	var remaining := []
	for tile in tiles:
		if not used_ids.has(tile.id):
			remaining.append(tile)

	return {"combos": combos, "remaining": remaining}
