class_name HandView
extends PanelContainer

@export var tile_scene: PackedScene = preload("res://scenes/ui/TileWiev.tscn")
@export var rack_texture: Texture2D

signal tile_selected(tile: GameTileData)
signal table_tile_dropped_to_hand(source_row: int, source_column: int)

@onready var rack_art: TextureRect = $RackMargin/RackArt
@onready var top_row: HBoxContainer = $RackMargin/RackRows/TopRow
@onready var bottom_row: HBoxContainer = $RackMargin/RackRows/BottomRow

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(0)
	style.draw_center = false
	add_theme_stylebox_override("panel", style)
	add_theme_constant_override("panel_margin_left", 6)
	add_theme_constant_override("panel_margin_right", 6)
	if rack_texture != null:
		rack_art.texture = rack_texture
		rack_art.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		rack_art.visible = false
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 12)
	bottom_row.add_theme_constant_override("separation", 12)

func render_tiles(tiles: Array, selected_tile_id: String = "") -> void:
	for child in top_row.get_children():
		child.queue_free()
	for child in bottom_row.get_children():
		child.queue_free()

	var split_index := int(ceil(tiles.size() * 0.5))
	for index in range(tiles.size()):
		var tile: GameTileData = tiles[index]
		var tile_view = tile_scene.instantiate()
		tile_view.setup(tile, "hand")
		tile_view.custom_minimum_size = Vector2(72, 104)
		tile_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tile_view.set_selected(tile.id == selected_tile_id)
		tile_view.tile_selected.connect(_on_tile_selected)
		if index < split_index:
			top_row.add_child(tile_view)
		else:
			bottom_row.add_child(tile_view)
		tile_view.play_snap_animation()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("source_kind", "") == "table"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	table_tile_dropped_to_hand.emit(data.get("source_row", -1), data.get("source_column", -1))

func _on_tile_selected(tile: GameTileData) -> void:
	tile_selected.emit(tile)
