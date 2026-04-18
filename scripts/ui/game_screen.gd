class_name GameScreen
extends Control

@onready var top_bar: HBoxContainer = $TopBar
@onready var round_label: Label = $TopBar/RoundLabel
@onready var target_score_label: Label = $TopBar/TargetScoreLabel
@onready var deck_count_label: Label = $TopBar/DeckCountLabel
@onready var turn_state_label: Label = $TopBar/TurnStateLabel
@onready var table_grid: TableGridView = $TableGrid
@onready var hand_view: HandView = $HandContainer
@onready var sort_color_button: Button = $BottomBar/SortColorButton
@onready var sort_value_button: Button = $BottomBar/SortValueButton
@onready var discard_button: Button = $BottomBar/DiscardButton
@onready var draw_button: Button = $BottomBar/DrawButton
@onready var finish_round_button: Button = $BottomBar/FinishRoundButton
@onready var result_label: RichTextLabel = $ResultPanel/ResultLabel

var game_manager := GameManager.new()
var selected_hand_tile_id: String = ""
var selected_table_tile_id: String = ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	hand_view.tile_selected.connect(_on_hand_tile_selected)
	hand_view.table_tile_dropped_to_hand.connect(_on_table_tile_dropped_to_hand)
	table_grid.tile_selected.connect(_on_table_tile_selected)
	table_grid.tile_dropped.connect(_on_table_tile_dropped)

	sort_color_button.pressed.connect(_on_sort_color_button_pressed)
	sort_value_button.pressed.connect(_on_sort_value_button_pressed)
	discard_button.pressed.connect(_on_discard_button_pressed)
	draw_button.pressed.connect(_on_draw_button_pressed)
	finish_round_button.pressed.connect(_on_finish_round_button_pressed)

	game_manager.start_game()
	result_label.text = ""
	_refresh_ui()

func _on_hand_tile_selected(tile: GameTileData) -> void:
	if selected_hand_tile_id == tile.id:
		selected_hand_tile_id = ""
	else:
		selected_hand_tile_id = tile.id
	selected_table_tile_id = ""
	_refresh_ui()

func _on_table_tile_selected(tile: GameTileData, _row: int, _column: int) -> void:
	selected_table_tile_id = "" if selected_table_tile_id == tile.id else tile.id
	selected_hand_tile_id = ""
	_refresh_ui()

func _on_table_tile_dropped(data: Dictionary, row: int, column: int) -> void:
	var moved := false
	var source_kind = data.get("source_kind", "")
	if source_kind == "hand":
		moved = game_manager.round_manager.move_hand_tile_to_table(data.get("tile_id", ""), row, column)
	elif source_kind == "table":
		moved = game_manager.round_manager.move_table_tile(data.get("source_row", -1), data.get("source_column", -1), row, column)
	if moved:
		selected_hand_tile_id = ""
		selected_table_tile_id = ""
		_refresh_ui()

func _on_table_tile_dropped_to_hand(source_row: int, source_column: int) -> void:
	if game_manager.round_manager.move_table_tile_to_hand(source_row, source_column):
		selected_table_tile_id = ""
		_refresh_ui()

func _on_sort_color_button_pressed() -> void:
	game_manager.round_manager.hand_model.sort_by_color_then_value()
	_refresh_ui()

func _on_sort_value_button_pressed() -> void:
	game_manager.round_manager.hand_model.sort_by_value_then_color()
	_refresh_ui()

func _on_discard_button_pressed() -> void:
	if selected_hand_tile_id == "":
		return
	if game_manager.round_manager.discard_tile(selected_hand_tile_id) != null:
		selected_hand_tile_id = ""
		_refresh_ui()

func _on_draw_button_pressed() -> void:
	if game_manager.round_manager.draw_after_discard() != null:
		_refresh_ui()

func _on_finish_round_button_pressed() -> void:
	var result = game_manager.finish_current_round()
	selected_hand_tile_id = ""
	selected_table_tile_id = ""
	result_label.text = result.get_summary_text()
	_refresh_ui()

func _refresh_ui() -> void:
	round_label.text = "Round: %d" % game_manager.current_round
	target_score_label.text = "Target: %d" % game_manager.round_manager.target_score
	deck_count_label.text = "Deck: %d" % game_manager.round_manager.deck_manager.remaining_count()
	turn_state_label.text = game_manager.round_manager.get_turn_state_text()

	var highlight_map = game_manager.round_manager.get_group_highlight_map()
	table_grid.render_table(game_manager.round_manager.table_grid, selected_table_tile_id, highlight_map)
	hand_view.render_tiles(game_manager.round_manager.hand_model.tiles, selected_hand_tile_id)

	discard_button.disabled = selected_hand_tile_id == "" or not game_manager.round_manager.can_discard(selected_hand_tile_id)
	draw_button.disabled = not game_manager.round_manager.can_draw()
