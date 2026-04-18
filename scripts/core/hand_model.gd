class_name HandModel
extends RefCounted

var tiles: Array = []

func set_tiles(new_tiles: Array) -> void:
	tiles = new_tiles.duplicate()

func add_tile(tile: GameTileData) -> void:
	if tile != null:
		tiles.append(tile)

func remove_tile_by_id(tile_id: String) -> GameTileData:
	for i in range(tiles.size()):
		if tiles[i].id == tile_id:
			return tiles.pop_at(i)
	return null

func remove_tile(tile: GameTileData) -> GameTileData:
	if tile == null:
		return null
	return remove_tile_by_id(tile.id)

func has_tile_id(tile_id: String) -> bool:
	for tile in tiles:
		if tile.id == tile_id:
			return true
	return false

func sort_by_color_then_value() -> void:
	tiles.sort_custom(func(a, b):
		if a.is_joker and not b.is_joker:
			return false
		if not a.is_joker and b.is_joker:
			return true
		if a.color == b.color:
			return a.value < b.value
		return a.color < b.color
	)

func sort_by_value_then_color() -> void:
	tiles.sort_custom(func(a, b):
		if a.is_joker and not b.is_joker:
			return false
		if not a.is_joker and b.is_joker:
			return true
		if a.value == b.value:
			return a.color < b.color
		return a.value < b.value
	)

func clear() -> void:
	tiles.clear()
