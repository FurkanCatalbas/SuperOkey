class_name HandView
extends HBoxContainer

@export var tile_scene: PackedScene = preload("res://scenes/ui/TileWiev.tscn")

signal tile_selected(tile: GameTileData)
signal table_tile_dropped_to_hand(source_row: int, source_column: int)

func render_tiles(tiles: Array, selected_tile_id: String = "") -> void:
	for child in get_children():
		child.queue_free()

	for tile in tiles:
		var tile_view = tile_scene.instantiate()
		tile_view.setup(tile, "hand")
		tile_view.set_selected(tile.id == selected_tile_id)
		tile_view.tile_selected.connect(_on_tile_selected)
		add_child(tile_view)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("source_kind", "") == "table"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	table_tile_dropped_to_hand.emit(data.get("source_row", -1), data.get("source_column", -1))

func _on_tile_selected(tile: GameTileData) -> void:
	tile_selected.emit(tile)
