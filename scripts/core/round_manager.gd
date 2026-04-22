class_name RoundManager
extends RefCounted

enum TurnState { WAITING_FOR_DISCARD, WAITING_FOR_DRAW }

const MAX_TILE_CHANGES := 5

var current_round: int = 1
var target_score: int = 50
var turn_state: TurnState = TurnState.WAITING_FOR_DISCARD
var turn_message: String = "Build groups, then discard one tile"

var hand_model := HandModel.new()
var deck_manager := DeckManager.new()
var score_manager := ScoreManager.new()
var validator := CombinationValidator.new()

var discard_pile: Array = []
var table_grid: Array = []
var tile_changes_used: int = 0

func start_round(round_number: int) -> void:
	current_round = round_number
	target_score = _calculate_target_score(round_number)

	deck_manager.build_deck()
	deck_manager.shuffle_deck()
	hand_model.clear()
	discard_pile.clear()
	_initialize_table_grid()

	var starting_tiles = deck_manager.draw_multiple(GameConstants.STARTING_HAND_SIZE)
	hand_model.set_tiles(starting_tiles)
	hand_model.sort_by_color_then_value()
	score_manager.roll_joker_cards()
	tile_changes_used = 0

	turn_state = TurnState.WAITING_FOR_DISCARD
	turn_message = "Build groups, then discard one tile"

func get_turn_state_text() -> String:
	return turn_message

func can_discard(tile_id: String) -> bool:
	return can_change_tile() and hand_model.has_tile_id(tile_id)

func can_change_tile() -> bool:
	return turn_state == TurnState.WAITING_FOR_DISCARD and tile_changes_used < MAX_TILE_CHANGES

func get_tile_change_count_text() -> String:
	return "%d/%d" % [tile_changes_used, MAX_TILE_CHANGES]

func can_edit_table() -> bool:
	return turn_state == TurnState.WAITING_FOR_DISCARD

func discard_tile(tile_id: String) -> GameTileData:
	if not can_change_tile():
		return null
	var tile = hand_model.remove_tile_by_id(tile_id)
	if tile == null:
		return null
	discard_pile.append(tile)
	turn_state = TurnState.WAITING_FOR_DRAW
	turn_message = "Drawing a replacement tile"
	return tile

func can_draw() -> bool:
	return turn_state == TurnState.WAITING_FOR_DRAW and deck_manager.remaining_count() > 0

func draw_after_discard() -> GameTileData:
	if turn_state != TurnState.WAITING_FOR_DRAW:
		return null
	var tile = deck_manager.draw_tile()
	if tile != null:
		hand_model.add_tile(tile)
	tile_changes_used += 1
	turn_state = TurnState.WAITING_FOR_DISCARD
	turn_message = "Tile change limit reached" if tile_changes_used >= MAX_TILE_CHANGES else "Tile changed. You can change more or finish the stage"
	return tile

func discard_tile_and_draw(tile_id: String) -> Dictionary:
	var discarded_tile = discard_tile(tile_id)
	if discarded_tile == null:
		return {}
	var drawn_tile = draw_after_discard()
	return {
		"discarded": discarded_tile,
		"drawn": drawn_tile
	}

func move_hand_tile_to_table(tile_id: String, row: int, column: int) -> bool:
	if not can_edit_table() or not _is_valid_cell(row, column) or table_grid[row][column] != null:
		return false
	var tile = hand_model.remove_tile_by_id(tile_id)
	if tile == null:
		return false
	table_grid[row][column] = tile
	return true

func move_table_tile_to_hand(row: int, column: int) -> bool:
	if not can_edit_table() or not _is_valid_cell(row, column):
		return false
	var tile: GameTileData = table_grid[row][column]
	if tile == null:
		return false
	table_grid[row][column] = null
	hand_model.add_tile(tile)
	return true

func move_table_tile(from_row: int, from_column: int, to_row: int, to_column: int) -> bool:
	if not can_edit_table() or not _is_valid_cell(from_row, from_column) or not _is_valid_cell(to_row, to_column):
		return false
	if from_row == to_row and from_column == to_column:
		return false
	if table_grid[to_row][to_column] != null:
		return false
	var tile: GameTileData = table_grid[from_row][from_column]
	if tile == null:
		return false
	table_grid[from_row][from_column] = null
	table_grid[to_row][to_column] = tile
	return true

func get_horizontal_group_infos() -> Array:
	var groups: Array = []
	for row in range(GameConstants.TABLE_ROWS):
		var segment_tiles: Array = []
		var segment_cells: Array = []
		var segment_index := 1
		for column in range(GameConstants.TABLE_COLUMNS + 1):
			var tile = table_grid[row][column] if column < GameConstants.TABLE_COLUMNS else null
			if tile != null:
				segment_tiles.append(tile)
				segment_cells.append(Vector2i(row, column))
			elif not segment_tiles.is_empty():
				var group = GroupData.new("Row %d Group %d" % [row + 1, segment_index])
				group.tiles = segment_tiles.duplicate()
				var validation = score_manager.score_group(group)
				groups.append({
					"group": group,
					"cells": segment_cells.duplicate(),
					"validation": validation
				})
				segment_tiles.clear()
				segment_cells.clear()
				segment_index += 1
	return groups

func get_group_highlight_map() -> Dictionary:
	var highlight_map := {}
	for info in get_horizontal_group_infos():
		for cell in info["cells"]:
			highlight_map[_cell_key(cell.x, cell.y)] = "valid" if info["validation"].is_valid else "invalid"
	return highlight_map

func get_live_table_score() -> int:
	return int(round(get_live_round_result().net_score))

func get_live_table_multiplier() -> float:
	return get_live_round_result().multiplier

func get_live_round_result() -> RoundResult:
	var detected_groups: Array = []
	for info in get_horizontal_group_infos():
		detected_groups.append(info["group"])
	return score_manager.evaluate_round(detected_groups, hand_model.tiles, target_score)

func can_finish_round() -> bool:
	return get_live_round_result().target_reached

func get_owned_joker_cards() -> Array:
	return score_manager.get_owned_joker_cards()

func finish_round() -> RoundResult:
	var result = get_live_round_result()
	result.round_number = current_round
	return result

func _initialize_table_grid() -> void:
	table_grid.clear()
	for row in range(GameConstants.TABLE_ROWS):
		var row_data: Array = []
		for column in range(GameConstants.TABLE_COLUMNS):
			row_data.append(null)
		table_grid.append(row_data)

func _is_valid_cell(row: int, column: int) -> bool:
	return row >= 0 and row < GameConstants.TABLE_ROWS and column >= 0 and column < GameConstants.TABLE_COLUMNS

func _cell_key(row: int, column: int) -> String:
	return "%d:%d" % [row, column]

func _calculate_target_score(round_number: int) -> int:
	return 30 + ((round_number - 1) * 20)
