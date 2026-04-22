class_name CombinationValidator
extends RefCounted

const TYPE_SERI := "SERI"
const TYPE_PER := "PER"
const TYPE_CIFTE := "CIFTE"
const TYPE_INVALID := "INVALID"

func validate_group(group: GroupData) -> GroupValidationResult:
	var tiles = group.tiles
	var result := GroupValidationResult.new()
	result.group_name = group.group_name

	if tiles.size() == 2:
		return _validate_pair(group.group_name, tiles)

	var run_result = _validate_run(group.group_name, tiles)
	var set_result = _validate_set(group.group_name, tiles)

	if run_result.is_valid and set_result.is_valid:
		return run_result if run_result.score >= set_result.score else set_result
	if run_result.is_valid:
		return run_result
	if set_result.is_valid:
		return set_result

	result.reason = run_result.reason if run_result.reason != "" else set_result.reason
	return result

func _validate_run(group_name: String, tiles: Array) -> GroupValidationResult:
	var result := GroupValidationResult.new()
	result.group_name = group_name
	result.detected_type = TYPE_SERI

	if tiles.size() < 3:
		result.reason = "Run needs at least 3 tiles"
		return result
	if tiles.size() > GameConstants.MAX_VALUE:
		result.reason = "Run is too long"
		return result

	var joker_tiles: Array[GameTileData] = []
	var non_jokers: Array[GameTileData] = []
	var color := ""
	var values: Array[int] = []
	var seen_values := {}

	for tile in tiles:
		if tile.is_joker:
			joker_tiles.append(tile)
			continue
		if color == "":
			color = tile.color
		elif tile.color != color:
			result.reason = "Run colors must match"
			return result
		if seen_values.has(tile.value):
			result.reason = "Run cannot contain duplicate values"
			return result
		seen_values[tile.value] = true
		values.append(tile.value)
		non_jokers.append(tile)

	if non_jokers.is_empty():
		return _build_all_joker_run(group_name, tiles)

	values.sort()
	var min_value: int = values[0]
	var max_value: int = values[values.size() - 1]
	if max_value - min_value + 1 > tiles.size():
		result.reason = "Run gaps are too large"
		return result

	var start_value: int = max(1, max_value - tiles.size() + 1)
	var end_value := start_value + tiles.size() - 1
	if end_value > GameConstants.MAX_VALUE or min_value < start_value or max_value > end_value:
		result.reason = "Run cannot fit within tile range"
		return result

	var non_joker_by_value := {}
	for tile in non_jokers:
		non_joker_by_value[tile.value] = tile

	var resolved: Array = []
	for value in range(start_value, end_value + 1):
		if non_joker_by_value.has(value):
			var tile: GameTileData = non_joker_by_value[value]
			resolved.append(_make_resolved_tile(tile, tile.color, value, false))
		else:
			var joker_tile: GameTileData = joker_tiles[0]
			joker_tiles.remove_at(0)
			resolved.append(_make_resolved_tile(joker_tile, color, value, true))
			result.joker_notes.append("Joker -> %s %d" % [color, value])

	result.is_valid = true
	result.set_scoring(_run_score(tiles.size()), 0.2 if tiles.size() >= 5 else 0.0)
	result.resolved_tiles = resolved
	return result

func _build_all_joker_run(group_name: String, tiles: Array) -> GroupValidationResult:
	var result := GroupValidationResult.new()
	result.group_name = group_name
	result.detected_type = TYPE_SERI
	if tiles.size() < 3:
		result.reason = "Run needs at least 3 tiles"
		return result

	var resolved: Array = []
	for i in range(tiles.size()):
		var value = GameConstants.MIN_VALUE + i
		var color = GameConstants.COLORS[0]
		resolved.append(_make_resolved_tile(tiles[i], color, value, true))
		result.joker_notes.append("Joker -> %s %d" % [color, value])

	result.is_valid = true
	result.set_scoring(_run_score(tiles.size()), 0.2 if tiles.size() >= 5 else 0.0)
	result.resolved_tiles = resolved
	return result

func _validate_set(group_name: String, tiles: Array) -> GroupValidationResult:
	var result := GroupValidationResult.new()
	result.group_name = group_name
	result.detected_type = TYPE_PER

	if tiles.size() < 3 or tiles.size() > 4:
		result.reason = "Set needs 3 or 4 tiles"
		return result

	var joker_tiles: Array[GameTileData] = []
	var value: int = -1
	var used_colors := {}
	var resolved: Array = []

	for tile in tiles:
		if tile.is_joker:
			joker_tiles.append(tile)
			continue
		if value == -1:
			value = tile.value
		elif tile.value != value:
			result.reason = "Set values must match"
			return result
		if used_colors.has(tile.color):
			result.reason = "Set colors must be unique"
			return result
		used_colors[tile.color] = true
		resolved.append(_make_resolved_tile(tile, tile.color, tile.value, false))

	if value == -1:
		value = GameConstants.MIN_VALUE

	var missing_colors: Array[String] = []
	for color in GameConstants.COLORS:
		if not used_colors.has(color):
			missing_colors.append(color)

	if joker_tiles.size() > missing_colors.size():
		result.reason = "Not enough unique colors for jokers"
		return result

	for i in range(joker_tiles.size()):
		var joker_tile: GameTileData = joker_tiles[i]
		var resolved_color = missing_colors[i]
		resolved.append(_make_resolved_tile(joker_tile, resolved_color, value, true))
		result.joker_notes.append("Joker -> %s %d" % [resolved_color, value])

	result.is_valid = true
	result.set_scoring(_set_score(value, tiles.size()), 0.5 if tiles.size() == 4 else 0.0)
	result.resolved_tiles = resolved
	return result

func _validate_pair(group_name: String, tiles: Array) -> GroupValidationResult:
	var result := GroupValidationResult.new()
	result.group_name = group_name
	result.detected_type = TYPE_CIFTE

	if tiles.size() != 2:
		result.reason = "Pair must have exactly 2 tiles"
		return result

	var a: GameTileData = tiles[0]
	var b: GameTileData = tiles[1]
	var value := -1
	var resolved: Array = []

	if not a.is_joker and not b.is_joker:
		if a.value != b.value:
			result.reason = "Pair values must match"
			return result
		if a.color != b.color:
			result.reason = "Pair colors must match"
			return result
		value = a.value
		resolved.append(_make_resolved_tile(a, a.color, a.value, false))
		resolved.append(_make_resolved_tile(b, b.color, b.value, false))
	else:
		if a.is_joker and b.is_joker:
			result.reason = "Pair can use only one joker"
			return result
		else:
			var non_joker: GameTileData = a if not a.is_joker else b
			value = non_joker.value
			var joker_color := non_joker.color
			if a.is_joker:
				resolved.append(_make_resolved_tile(a, joker_color, value, true))
				resolved.append(_make_resolved_tile(b, b.color, value, false))
			else:
				resolved.append(_make_resolved_tile(a, a.color, value, false))
				resolved.append(_make_resolved_tile(b, joker_color, value, true))
			result.joker_notes.append("Joker -> %s %d" % [joker_color, value])

	result.is_valid = true
	result.set_scoring(_pair_score(value, a.is_joker or b.is_joker))
	result.resolved_tiles = resolved
	return result

func _first_color_not_used(used_colors: Array) -> String:
	for color in GameConstants.COLORS:
		if not used_colors.has(color):
			return color
	return ""

func _run_score(tile_count: int) -> int:
	match tile_count:
		3:
			return 20
		4:
			return 30
		5:
			return 45
	return 45 + max(0, tile_count - 5) * 12

func _set_score(value: int, tile_count: int) -> int:
	var chips := 18
	if value >= 5 and value <= 8:
		chips = 28
	elif value >= 9 and value <= 11:
		chips = 40
	elif value >= 12:
		chips = 55
	if tile_count == 4:
		chips += 10
	return chips

func _pair_score(value: int, uses_joker: bool) -> int:
	var chips := 8
	if value >= 6 and value <= 9:
		chips = 10
	elif value >= 10:
		chips = 14
	if uses_joker:
		chips -= 2
	return chips

func _make_resolved_tile(tile: GameTileData, resolved_color: String, resolved_value: int, joker: bool) -> Dictionary:
	return {
		"original_tile": tile,
		"is_joker": joker,
		"resolved_color": resolved_color,
		"resolved_value": resolved_value,
		"display_text": "%s %d" % [resolved_color.capitalize(), resolved_value]
	}
