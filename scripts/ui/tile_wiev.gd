class_name TileView
extends Button

signal tile_selected(tile: GameTileData)

var tile_data: GameTileData
var source_kind: String = ""
var source_row: int = -1
var source_column: int = -1

func setup(data: GameTileData, new_source_kind: String, row: int = -1, column: int = -1) -> void:
	tile_data = data
	source_kind = new_source_kind
	source_row = row
	source_column = column
	text = data.get_display_text()
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(72, 104)
	_flatten_style(Color(0.95, 0.91, 0.76), Color(0.31, 0.24, 0.15), Color(0.18, 0.12, 0.08))
	pressed.connect(_on_pressed)

func set_selected(selected: bool) -> void:
	if selected:
		_flatten_style(Color(1.0, 0.96, 0.68), Color(0.75, 0.6, 0.1), Color(0.22, 0.14, 0.06))
	else:
		_flatten_style(Color(0.95, 0.91, 0.76), Color(0.31, 0.24, 0.15), Color(0.18, 0.12, 0.08))

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Button.new()
	preview.text = text
	preview.custom_minimum_size = custom_minimum_size
	preview.disabled = true
	set_drag_preview(preview)
	return {
		"tile_id": tile_data.id,
		"source_kind": source_kind,
		"source_row": source_row,
		"source_column": source_column
	}

func _on_pressed() -> void:
	tile_selected.emit(tile_data)

func _flatten_style(background: Color, border: Color, font_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = background
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", normal)
	add_theme_stylebox_override("pressed", normal)
	add_theme_stylebox_override("focus", normal)
	add_theme_color_override("font_color", font_color)
