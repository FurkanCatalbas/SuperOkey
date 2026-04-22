class_name GameScreen
extends Control

const JOKER_TEXTURE: Texture2D = preload("res://assets/jokers/jokercard.png")

@onready var round_label: Label = $TopBar/TopBarMargin/TopBarContent/RoundInfo/RoundLabel
@onready var target_score_label: Label = $TopBar/TopBarMargin/TopBarContent/RoundInfo/TargetScoreLabel
@onready var turn_state_label: Label = $TopBar/TopBarMargin/TopBarContent/TurnStateLabel
@onready var deck_count_label: Label = $TopBar/TopBarMargin/TopBarContent/DeckCountLabel
@onready var table_grid: TableManager = $TableShell/TableArea/TableGrid
@onready var discard_zone: DiscardZone = $TableShell/TableArea/DiscardZone
@onready var discard_label: Label = $TableShell/TableArea/DiscardZone/DiscardContent/DiscardLabel
@onready var discard_hint_label: Label = $TableShell/TableArea/DiscardZone/DiscardContent/DiscardHintLabel
@onready var finish_round_button: Button = $TableShell/TableArea/FinishRoundButton
@onready var hand_view: HandView = $Rack
@onready var current_score_label: Label = $LeftPanel/LeftPanelMargin/LeftPanelContent/CurrentScoreLabel
@onready var multiplier_label: Label = $LeftPanel/LeftPanelMargin/LeftPanelContent/MultiplierCard/MultiplierMargin/MultiplierContent/MultiplierLabel
@onready var round_value_label: Label = $LeftPanel/LeftPanelMargin/LeftPanelContent/LeftMeta/RoundValueLabel
@onready var target_value_label: Label = $LeftPanel/LeftPanelMargin/LeftPanelContent/LeftMeta/TargetValueLabel
@onready var valid_groups_label: Label = $LeftPanel/LeftPanelMargin/LeftPanelContent/LeftMeta/ValidGroupsLabel
@onready var joker_cards_row: HBoxContainer = $JokerBar/JokerBarMargin/JokerCardsRow
@onready var popup_layer: Control = $PopupLayer

var game_manager := GameManager.new()
var selected_hand_tile_id: String = ""
var selected_table_tile_id: String = ""
var _last_live_score: int = 0
var _status_message: String = ""
var _finish_button_tween: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_surface_styles()

	hand_view.tile_selected.connect(_on_hand_tile_selected)
	hand_view.table_tile_dropped_to_hand.connect(_on_table_tile_dropped_to_hand)
	table_grid.tile_selected.connect(_on_table_tile_selected)
	table_grid.tile_dropped.connect(_on_table_tile_dropped)
	discard_zone.tile_discarded.connect(_on_discard_zone_tile_discarded)

	finish_round_button.pressed.connect(_on_finish_round_button_pressed)

	game_manager.start_game()
	_refresh_ui(true)

func _on_hand_tile_selected(tile: GameTileData) -> void:
	selected_hand_tile_id = "" if selected_hand_tile_id == tile.id else tile.id
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
		_status_message = ""
		_refresh_ui()

func _on_table_tile_dropped_to_hand(source_row: int, source_column: int) -> void:
	if game_manager.round_manager.move_table_tile_to_hand(source_row, source_column):
		selected_table_tile_id = ""
		_status_message = ""
		_refresh_ui()

func _on_discard_zone_tile_discarded(data: Dictionary) -> void:
	if data.get("source_kind", "") != "hand":
		return
	var result = game_manager.round_manager.discard_tile_and_draw(data.get("tile_id", ""))
	if result.is_empty():
		return
	selected_hand_tile_id = ""
	selected_table_tile_id = ""
	var discarded_tile: GameTileData = result.get("discarded")
	var drawn_tile: GameTileData = result.get("drawn")
	_status_message = _format_turn_feedback(discarded_tile, drawn_tile)
	_refresh_ui()

func _on_finish_round_button_pressed() -> void:
	if not game_manager.round_manager.can_finish_round():
		return
	var result = game_manager.finish_current_round()
	selected_hand_tile_id = ""
	selected_table_tile_id = ""
	_status_message = result.get_summary_text()
	_last_live_score = 0
	_refresh_ui(true)

func _refresh_ui(skip_popup: bool = false) -> void:
	var round_manager := game_manager.round_manager
	var group_infos = round_manager.get_horizontal_group_infos()
	var valid_group_count := 0
	for info in group_infos:
		var validation: GroupValidationResult = info["validation"]
		if validation.is_valid:
			valid_group_count += 1

	var live_score = round_manager.get_live_table_score()
	var live_multiplier = round_manager.get_live_table_multiplier()
	var can_finish_round = round_manager.can_finish_round()
	var owned_jokers = round_manager.get_owned_joker_cards()

	round_label.text = "Round %d" % game_manager.current_round
	target_score_label.text = "Target %d" % round_manager.target_score
	turn_state_label.text = round_manager.get_turn_state_text()
	deck_count_label.text = "Deck %d" % round_manager.deck_manager.remaining_count()

	current_score_label.text = str(live_score)
	multiplier_label.text = "x%s" % _format_multiplier_value(live_multiplier)
	round_value_label.text = "Round %d" % game_manager.current_round
	target_value_label.text = "Target %d" % round_manager.target_score
	valid_groups_label.text = "Valid Groups %d" % valid_group_count
	_update_finish_round_button(can_finish_round)
	discard_label.text = "Tas Degistir"
	discard_hint_label.text = round_manager.get_tile_change_count_text()

	var highlight_map = round_manager.get_group_highlight_map()
	table_grid.render_table(round_manager.table_grid, selected_table_tile_id, highlight_map, group_infos, skip_popup)
	hand_view.render_tiles(round_manager.hand_model.tiles, selected_hand_tile_id)
	discard_zone.set_active(round_manager.can_change_tile())
	_render_joker_bar(owned_jokers, group_infos)

	if not skip_popup and live_score > _last_live_score:
		_show_score_popup(live_score - _last_live_score)
	_last_live_score = live_score

func _render_joker_bar(owned_jokers: Array, group_infos: Array) -> void:
	for child in joker_cards_row.get_children():
		child.queue_free()

	for index in range(ScoreManager.JOKER_SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(188.0, 58.0)
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.07, 0.09, 0.11, 0.58)
		slot_style.border_color = Color(1.0, 1.0, 1.0, 0.08)
		slot_style.set_border_width_all(1)
		slot_style.corner_radius_top_left = 12
		slot_style.corner_radius_top_right = 12
		slot_style.corner_radius_bottom_left = 12
		slot_style.corner_radius_bottom_right = 12
		slot.add_theme_stylebox_override("panel", slot_style)
		joker_cards_row.add_child(slot)

		if index >= owned_jokers.size():
			var empty_label := Label.new()
			empty_label.text = "BOS SLOT"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			empty_label.modulate = Color(0.72, 0.76, 0.82, 0.5)
			slot.add_child(empty_label)
			continue

		var card: JokerCardData = owned_jokers[index]
		var card_active := _is_joker_card_active(card, group_infos)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.11, 0.25, 0.94) if card_active else Color(0.12, 0.09, 0.19, 0.84)
		style.border_color = Color(1.0, 0.84, 0.48, 0.92) if card_active else Color(0.83, 0.64, 0.98, 0.72)
		style.set_border_width_all(2)
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		slot.add_theme_stylebox_override("panel", style)

		var content := HBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 8)
		slot.add_child(content)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28.0, 28.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = JOKER_TEXTURE
		content.add_child(icon)

		var text_column := VBoxContainer.new()
		text_column.add_theme_constant_override("separation", 2)
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(text_column)

		var title := Label.new()
		title.text = card.title
		title.add_theme_font_size_override("font_size", 14)
		text_column.add_child(title)

		var effect := Label.new()
		effect.text = card.description
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect.modulate = Color(0.92, 0.91, 1.0, 0.88)
		text_column.add_child(effect)

		if card_active:
			var active_badge := Label.new()
			active_badge.text = "AKTIF"
			active_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			active_badge.modulate = Color(1.0, 0.91, 0.58, 0.96)
			text_column.add_child(active_badge)

func _is_joker_card_active(card: JokerCardData, group_infos: Array) -> bool:
	for info in group_infos:
		var validation: GroupValidationResult = info["validation"]
		if validation.applied_jokers.has(card.title):
			return true
	return false

func _format_multiplier_value(value: float) -> String:
	var formatted := "%.2f" % value
	while formatted.ends_with("0"):
		formatted = formatted.left(formatted.length() - 1)
	if formatted.ends_with("."):
		formatted = formatted.left(formatted.length() - 1)
	return formatted

func _show_score_popup(score_delta: int) -> void:
	if score_delta <= 0:
		return
	var popup := Label.new()
	popup.text = "+%d" % score_delta
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.position = Vector2(size.x * 0.49 - 54.0, size.y * 0.26)
	popup.size = Vector2(108.0, 40.0)
	popup.modulate = Color(1.0, 0.95, 0.52)
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_outline_color", Color(0.16, 0.11, 0.04, 0.95))
	popup.add_theme_constant_override("outline_size", 4)
	popup_layer.add_child(popup)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 44.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(popup.queue_free)

func _format_turn_feedback(discarded_tile: GameTileData, drawn_tile: GameTileData) -> String:
	var lines: Array[String] = []
	lines.append("Discarded: %s" % discarded_tile.get_display_text())
	if drawn_tile != null:
		lines.append("Drawn: %s" % drawn_tile.get_display_text())
	else:
		lines.append("Drawn: Deck empty")
	return "\n".join(lines)

func _type_label(type_name: String) -> String:
	match type_name:
		"SERI":
			return "SERİ"
		"PER":
			return "PER"
		"CIFTE":
			return "ÇİFTE"
	return type_name.to_upper()

func _apply_surface_styles() -> void:
	var shell_style := _panel_style(Color(0.04, 0.05, 0.06, 0.56), Color(1.0, 1.0, 1.0, 0.08), 16, 2)
	$TopBar.add_theme_stylebox_override("panel", shell_style)
	$JokerBar.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.06, 0.5), Color(1.0, 1.0, 1.0, 0.06), 16, 1))
	$LeftPanel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.06, 0.08, 0.7), Color(1.0, 1.0, 1.0, 0.08), 20, 2))
	$TableShell.add_theme_stylebox_override("panel", _panel_style(Color(0.0, 0.0, 0.0, 0.06), Color(1.0, 1.0, 1.0, 0.04), 24, 1))
	$LeftPanel/LeftPanelMargin/LeftPanelContent/MultiplierCard.add_theme_stylebox_override("panel", _panel_style(Color(0.25, 0.18, 0.06, 0.9), Color(1.0, 0.86, 0.46, 0.85), 18, 2))

	current_score_label.add_theme_font_size_override("font_size", 42)
	current_score_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92))
	multiplier_label.add_theme_font_size_override("font_size", 34)
	multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.56))
	round_label.add_theme_font_size_override("font_size", 22)
	target_score_label.modulate = Color(0.88, 0.91, 0.95, 0.9)
	turn_state_label.modulate = Color(0.93, 0.95, 0.98, 0.95)
	deck_count_label.modulate = Color(0.84, 0.9, 0.95, 0.88)
	valid_groups_label.modulate = Color(0.86, 0.95, 0.9, 0.92)
	discard_label.modulate = Color(1.0, 0.96, 0.9, 0.96)
	discard_hint_label.modulate = Color(1.0, 0.9, 0.72, 0.96)
	discard_hint_label.add_theme_font_size_override("font_size", 20)

	finish_round_button.custom_minimum_size = Vector2(138.0, 76.0)
	finish_round_button.add_theme_font_size_override("font_size", 20)
	finish_round_button.add_theme_stylebox_override("normal", _panel_style(Color(0.16, 0.18, 0.22, 0.96), Color(1.0, 1.0, 1.0, 0.08), 18, 2))
	finish_round_button.add_theme_stylebox_override("hover", _panel_style(Color(0.22, 0.26, 0.32, 0.98), Color(1.0, 1.0, 1.0, 0.14), 18, 2))
	finish_round_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.15, 0.2, 0.98), Color(1.0, 0.9, 0.62, 0.34), 18, 2))
	finish_round_button.add_theme_stylebox_override("disabled", _panel_style(Color(0.08, 0.09, 0.11, 0.72), Color(1.0, 1.0, 1.0, 0.04), 18, 2))
	finish_round_button.text = "Etabi Bitir"

func _update_finish_round_button(can_finish_round: bool) -> void:
	finish_round_button.disabled = not can_finish_round
	if can_finish_round:
		finish_round_button.add_theme_stylebox_override("normal", _panel_style(Color(0.84, 0.62, 0.14, 0.98), Color(1.0, 0.92, 0.62, 0.95), 18, 2))
		finish_round_button.add_theme_stylebox_override("hover", _panel_style(Color(0.94, 0.72, 0.18, 1.0), Color(1.0, 0.97, 0.78, 1.0), 18, 2))
		_start_finish_button_pulse()
	else:
		finish_round_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_stop_finish_button_pulse()

func _start_finish_button_pulse() -> void:
	if _finish_button_tween != null and _finish_button_tween.is_valid():
		return
	_finish_button_tween = create_tween()
	_finish_button_tween.set_loops()
	_finish_button_tween.tween_property(finish_round_button, "modulate", Color(1.0, 0.95, 0.72, 1.0), 0.55)
	_finish_button_tween.tween_property(finish_round_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55)

func _stop_finish_button_pulse() -> void:
	if _finish_button_tween != null and _finish_button_tween.is_valid():
		_finish_button_tween.kill()
	_finish_button_tween = null

func _panel_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
