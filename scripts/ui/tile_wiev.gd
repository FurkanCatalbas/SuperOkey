class_name TileView
extends Button

var tile_data: GameTileData

func setup(data: GameTileData) -> void:
	tile_data = data
	text = data.get_display_text()
	focus_mode = Control.FOCUS_NONE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
