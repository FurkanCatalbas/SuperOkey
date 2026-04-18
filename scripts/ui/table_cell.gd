class_name TableCell
extends PanelContainer

@export var tile_scene: PackedScene = preload("res://scenes/ui/TileWiev.tscn")

signal tile_selected(tile: GameTileData, row: int, column: int)
signal tile_dropped(data: Dictionary, row: int, column: int)

var row: int = -1
var column: int = -1
var tile_data: GameTileData = null
var tiles_container: CenterContainer

func _ready() -> void:
	tiles_container = get_node_or_null("TileAnchor")
	_apply_state_style("normal")

func setup(new_row: int, new_column: int) -> void:
	row = new_row
	column = new_column
	custom_minimum_size = Vector2(78, 110)

func render_tile(tile: GameTileData, selected_tile_id: String, state: String) -> void:
	tile_data = tile
	if tiles_container == null:
		tiles_container = get_node_or_null("TileAnchor")
	if tiles_container == null:
		return

	for child in tiles_container.get_children():
		child.queue_free()

	if tile != null:
		var tile_view = tile_scene.instantiate()
		tile_view.setup(tile, "table", row, column)
		tile_view.set_selected(tile.id == selected_tile_id)
		tile_view.tile_selected.connect(_on_tile_selected)
		tiles_container.add_child(tile_view)

	_apply_state_style(state)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if tile_data != null:
		return false
	var source_kind = data.get("source_kind", "")
	if source_kind == "hand":
		return true
	if source_kind == "table":
		return data.get("source_row", -1) != row or data.get("source_column", -1) != column
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	tile_dropped.emit(data, row, column)

func _on_tile_selected(tile: GameTileData) -> void:
	tile_selected.emit(tile, row, column)

func _apply_state_style(state: String) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_border_width_all(2)
	if state == "valid":
		style.bg_color = Color(0.17, 0.28, 0.19)
		style.border_color = Color(0.32, 0.82, 0.45)
	elif state == "invalid":
		style.bg_color = Color(0.31, 0.16, 0.16)
		style.border_color = Color(0.9, 0.32, 0.32)
	else:
		style.bg_color = Color(0.16, 0.18, 0.21)
		style.border_color = Color(0.36, 0.4, 0.45)
	add_theme_stylebox_override("panel", style)
