class_name GroupData
extends RefCounted

var group_name: String = ""
var tiles: Array = []

func _init(_group_name: String = ""):
	group_name = _group_name

func add_tile(tile: GameTileData) -> void:
	if tile != null:
		tiles.append(tile)

func remove_tile_by_id(tile_id: String) -> GameTileData:
	for i in range(tiles.size()):
		if tiles[i].id == tile_id:
			return tiles.pop_at(i)
	return null

func contains_tile_id(tile_id: String) -> bool:
	for tile in tiles:
		if tile.id == tile_id:
			return true
	return false

func clear() -> void:
	tiles.clear()

func size() -> int:
	return tiles.size()
