class_name TableManager
extends Control

@export var tile_scene: PackedScene = preload("res://scenes/ui/TileWiev.tscn")
@export var slot_size := Vector2(118, 164)
@export var slot_gap := Vector2(4, 28)
@export var content_padding := Vector2(44, 44)
@export var table_tile_inset := Vector2(26, 30)
@export var occupied_drop_uses_nearest_empty := true

signal tile_selected(tile: GameTileData, row: int, column: int)
signal tile_dropped(data: Dictionary, row: int, column: int)

var _slots: Array[TableSlot] = []
var _slot_visuals := {}
var _slot_layer: Control
var _tile_layer: Control
var _feedback_layer: Control
var _popup_layer: Control
var _last_table_data: Array = []
var _last_selected_tile_id: String = ""
var _last_highlight_map: Dictionary = {}
var _last_group_infos: Array = []
var _last_valid_group_scores: Dictionary = {}
var _feedback_ready: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	_ensure_layers()
	_rebuild_slots()
	resized.connect(_rebuild_slots)

func render_table(table_data: Array, selected_tile_id: String, highlight_map: Dictionary, group_infos: Array = [], skip_feedback_popups: bool = false) -> void:
	_last_table_data = table_data
	_last_selected_tile_id = selected_tile_id
	_last_highlight_map = highlight_map.duplicate()
	_last_group_infos = group_infos.duplicate(true)
	if _slots.is_empty():
		_rebuild_slots()

	for slot in _slots:
		slot.occupied_tile = table_data[slot.row][slot.column]
		slot.highlight_state = highlight_map.get(slot.key(), "normal")
		_update_slot_visual(slot)

	for child in _tile_layer.get_children():
		child.queue_free()

	for slot in _slots:
		if slot.occupied_tile == null:
			continue
		var tile_view: TileView = tile_scene.instantiate()
		tile_view.setup(slot.occupied_tile, "table", slot.row, slot.column)
		tile_view.current_slot_row = slot.row
		tile_view.current_slot_column = slot.column
		tile_view.set_selected(slot.occupied_tile.id == selected_tile_id)
		tile_view.tile_selected.connect(_on_tile_selected.bind(slot.row, slot.column))
		tile_view.mouse_filter = Control.MOUSE_FILTER_PASS
		tile_view.size = Vector2(
			max(56.0, slot.slot_size.x - table_tile_inset.x),
			max(82.0, slot.slot_size.y - table_tile_inset.y)
		)
		tile_view.custom_minimum_size = tile_view.size
		tile_view.position = slot.center - (tile_view.size * 0.5)
		_tile_layer.add_child(tile_view)
		tile_view.play_snap_animation()

	_render_group_feedback(group_infos)
	if not skip_feedback_popups:
		_maybe_show_group_popups(group_infos)
	else:
		_last_valid_group_scores = _build_valid_group_snapshot(group_infos)
		_feedback_ready = true

func get_slots() -> Array[TableSlot]:
	return _slots

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var source_kind = data.get("source_kind", "")
	if source_kind != "hand" and source_kind != "table":
		return false
	return _find_target_slot(at_position, data) != null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target_slot = _find_target_slot(at_position, data)
	if target_slot == null:
		return
	tile_dropped.emit(data, target_slot.row, target_slot.column)

func _ensure_layers() -> void:
	if _slot_layer == null:
		_slot_layer = Control.new()
		_slot_layer.name = "SlotLayer"
		_slot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_slot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_slot_layer)
	if _tile_layer == null:
		_tile_layer = Control.new()
		_tile_layer.name = "TileLayer"
		_tile_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_tile_layer)
	if _feedback_layer == null:
		_feedback_layer = Control.new()
		_feedback_layer.name = "FeedbackLayer"
		_feedback_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_feedback_layer)
	if _popup_layer == null:
		_popup_layer = Control.new()
		_popup_layer.name = "PopupLayer"
		_popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_popup_layer)

func _rebuild_slots() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_ensure_layers()
	for child in _slot_layer.get_children():
		child.queue_free()
	for child in _tile_layer.get_children():
		child.queue_free()
	for child in _feedback_layer.get_children():
		child.queue_free()
	_slot_visuals.clear()
	_slots.clear()

	var available_width = max(1.0, size.x - (content_padding.x * 2.0))
	var available_height = max(1.0, size.y - (content_padding.y * 2.0))
	var board_width = (GameConstants.TABLE_COLUMNS * slot_size.x) + ((GameConstants.TABLE_COLUMNS - 1) * slot_gap.x)
	var board_height = (GameConstants.TABLE_ROWS * slot_size.y) + ((GameConstants.TABLE_ROWS - 1) * slot_gap.y)
	var width_scale = available_width / max(1.0, board_width)
	var height_scale = available_height / max(1.0, board_height)
	var scale_factor = min(1.0, min(width_scale, height_scale))
	var scaled_slot_size = slot_size * scale_factor
	var scaled_gap = slot_gap * scale_factor
	var scaled_board_width = (GameConstants.TABLE_COLUMNS * scaled_slot_size.x) + ((GameConstants.TABLE_COLUMNS - 1) * scaled_gap.x)
	var scaled_board_height = (GameConstants.TABLE_ROWS * scaled_slot_size.y) + ((GameConstants.TABLE_ROWS - 1) * scaled_gap.y)
	var start_x = (size.x - scaled_board_width) * 0.5
	var start_y = (size.y - scaled_board_height) * 0.5

	for row in range(GameConstants.TABLE_ROWS):
		for column in range(GameConstants.TABLE_COLUMNS):
			var slot := TableSlot.new(row, column)
			slot.slot_size = scaled_slot_size
			slot.center = Vector2(
				start_x + (column * (scaled_slot_size.x + scaled_gap.x)) + (scaled_slot_size.x * 0.5),
				start_y + (row * (scaled_slot_size.y + scaled_gap.y)) + (scaled_slot_size.y * 0.5)
			)
			_slots.append(slot)

			var panel := Panel.new()
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.position = slot.center - (scaled_slot_size * 0.5)
			panel.size = scaled_slot_size
			panel.visible = false
			_slot_layer.add_child(panel)
			_slot_visuals[slot.key()] = panel
			_update_slot_visual(slot)

	if not _last_table_data.is_empty():
		render_table(_last_table_data, _last_selected_tile_id, _last_highlight_map, _last_group_infos, true)

func _find_target_slot(drop_position: Vector2, drag_data: Dictionary) -> TableSlot:
	if _slots.is_empty():
		return null
	var source_row: int = drag_data.get("source_row", -1)
	var source_column: int = drag_data.get("source_column", -1)
	var nearest_slot := _get_nearest_slot(drop_position)
	if nearest_slot == null:
		return null
	if nearest_slot.is_empty():
		return nearest_slot
	if nearest_slot.row == source_row and nearest_slot.column == source_column:
		return null
	if occupied_drop_uses_nearest_empty:
		return _get_nearest_empty_slot(drop_position, source_row, source_column)
	return null

func _get_nearest_slot(drop_position: Vector2) -> TableSlot:
	var nearest_slot: TableSlot = null
	var nearest_distance := INF
	for slot in _slots:
		var distance = slot.center.distance_squared_to(drop_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_slot = slot
	return nearest_slot

func _get_nearest_empty_slot(drop_position: Vector2, source_row: int, source_column: int) -> TableSlot:
	var nearest_slot: TableSlot = null
	var nearest_distance := INF
	for slot in _slots:
		if not slot.is_empty():
			continue
		if slot.row == source_row and slot.column == source_column:
			continue
		var distance = slot.center.distance_squared_to(drop_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_slot = slot
	return nearest_slot

func _on_tile_selected(tile: GameTileData, row: int, column: int) -> void:
	tile_selected.emit(tile, row, column)

func _update_slot_visual(slot: TableSlot) -> void:
	var panel: Panel = _slot_visuals.get(slot.key())
	if panel == null:
		return
	panel.position = slot.center - (slot.slot_size * 0.5)
	panel.size = slot.slot_size
	panel.visible = slot.highlight_state == "valid" or slot.highlight_state == "invalid"
	if not panel.visible:
		return
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.set_border_width_all(3)
	style.shadow_size = 16
	if slot.highlight_state == "valid":
		style.bg_color = Color(0.16, 0.56, 0.3, 0.12)
		style.border_color = Color(0.36, 0.96, 0.58, 0.96)
		style.shadow_color = Color(0.2, 0.9, 0.48, 0.34)
	else:
		style.bg_color = Color(0.54, 0.16, 0.16, 0.16)
		style.border_color = Color(0.98, 0.34, 0.34, 0.94)
		style.shadow_color = Color(0.96, 0.2, 0.2, 0.3)
	panel.add_theme_stylebox_override("panel", style)

func _render_group_feedback(group_infos: Array) -> void:
	for child in _feedback_layer.get_children():
		child.queue_free()

	for info in group_infos:
		var cells: Array = info.get("cells", [])
		if cells.is_empty():
			continue
		var validation: GroupValidationResult = info["validation"]
		var bounds := _group_bounds(cells)
		var title_text := "GEÇERSİZ"
		var title_bg := Color(0.45, 0.1, 0.12, 0.94)
		var title_border := Color(1.0, 0.45, 0.45, 0.92)
		if validation.is_valid:
			title_text = "%s +%d" % [_type_label(validation.detected_type), validation.score]
			title_bg = Color(0.08, 0.26, 0.14, 0.94)
			title_border = Color(0.47, 0.95, 0.62, 0.92)

		var title := _make_group_label(title_text, title_bg, title_border)
		title.position = Vector2(bounds["center_x"] - (title.size.x * 0.5), max(4.0, bounds["top"] - 34.0))
		_feedback_layer.add_child(title)

		if validation.is_valid and validation.joker_notes.size() > 0:
			var joker_badge := _make_group_label("+JOKER", Color(0.32, 0.16, 0.46, 0.96), Color(0.92, 0.72, 1.0, 0.9), Vector2(72.0, 24.0), 13)
			joker_badge.position = Vector2(bounds["right"] - joker_badge.size.x, max(4.0, bounds["top"] - 62.0))
			_feedback_layer.add_child(joker_badge)

func _maybe_show_group_popups(group_infos: Array) -> void:
	var next_snapshot := _build_valid_group_snapshot(group_infos)
	if not _feedback_ready:
		_last_valid_group_scores = next_snapshot
		_feedback_ready = true
		return

	for info in group_infos:
		var validation: GroupValidationResult = info["validation"]
		if not validation.is_valid:
			continue
		var cells: Array = info.get("cells", [])
		var signature = _group_signature(cells)
		var previous_score = int(_last_valid_group_scores.get(signature, 0))
		if previous_score >= validation.score:
			continue
		var bounds := _group_bounds(cells)
		var center := Vector2(bounds["center_x"], bounds["center_y"] - 8.0)
		var popup_text := "+%d" % (validation.score if previous_score == 0 else validation.score - previous_score)
		_spawn_popup(popup_text, center, Color(1.0, 0.95, 0.58))
		if validation.joker_notes.size() > 0 and previous_score == 0:
			_spawn_popup("+JOKER", center + Vector2(0.0, -24.0), Color(0.94, 0.78, 1.0))

	_last_valid_group_scores = next_snapshot

func _build_valid_group_snapshot(group_infos: Array) -> Dictionary:
	var snapshot := {}
	for info in group_infos:
		var validation: GroupValidationResult = info["validation"]
		if not validation.is_valid:
			continue
		snapshot[_group_signature(info.get("cells", []))] = validation.score
	return snapshot

func _make_group_label(text: String, bg_color: Color, border_color: Color, minimum_size: Vector2 = Vector2(120.0, 28.0), font_size: int = 15) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = minimum_size
	panel.size = minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	panel.add_child(label)
	return panel

func _spawn_popup(text: String, start_position: Vector2, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.position = start_position - Vector2(48.0, 16.0)
	popup.size = Vector2(96.0, 28.0)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.modulate = color
	popup.add_theme_font_size_override("font_size", 18)
	popup.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.06, 0.96))
	popup.add_theme_constant_override("outline_size", 3)
	_popup_layer.add_child(popup)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 30.0, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(popup.queue_free)

func _group_bounds(cells: Array) -> Dictionary:
	var left := INF
	var right := -INF
	var top := INF
	var bottom := -INF
	for cell in cells:
		var slot := _slot_for_cell(cell.x, cell.y)
		if slot == null:
			continue
		left = min(left, slot.center.x - (slot.slot_size.x * 0.5))
		right = max(right, slot.center.x + (slot.slot_size.x * 0.5))
		top = min(top, slot.center.y - (slot.slot_size.y * 0.5))
		bottom = max(bottom, slot.center.y + (slot.slot_size.y * 0.5))
	if left == INF:
		left = 0.0
		right = 0.0
		top = 0.0
		bottom = 0.0
	return {
		"left": left,
		"right": right,
		"top": top,
		"bottom": bottom,
		"center_x": (left + right) * 0.5,
		"center_y": (top + bottom) * 0.5
	}

func _slot_for_cell(row: int, column: int) -> TableSlot:
	for slot in _slots:
		if slot.row == row and slot.column == column:
			return slot
	return null

func _group_signature(cells: Array) -> String:
	var parts: Array[String] = []
	for cell in cells:
		parts.append("%d:%d" % [cell.x, cell.y])
	return "|".join(parts)

func _type_label(type_name: String) -> String:
	match type_name:
		"SERI":
			return "SERİ"
		"PER":
			return "PER"
		"CIFTE":
			return "ÇİFTE"
	return type_name.to_upper()
