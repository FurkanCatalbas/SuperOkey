class_name DeckManager
extends RefCounted

var draw_pile: Array = []
var _id_counter: int = 0

func build_deck() -> void:
	draw_pile.clear()
	_id_counter = 0

	for color in GameConstants.COLORS:
		for value in range(GameConstants.MIN_VALUE, GameConstants.MAX_VALUE + 1):
			for i in range(GameConstants.COPIES_PER_TILE):
				draw_pile.append(GameTileData.new(_next_id(), color, value, false))

	for i in range(GameConstants.JOKER_COUNT):
		draw_pile.append(GameTileData.new(_next_id(), "joker", 0, true))

func shuffle_deck() -> void:
	draw_pile.shuffle()

func draw_tile() -> GameTileData:
	if draw_pile.is_empty():
		return null
	return draw_pile.pop_back()

func draw_multiple(count: int) -> Array:
	var result: Array = []
	for i in range(count):
		var tile = draw_tile()
		if tile != null:
			result.append(tile)
	return result

func remaining_count() -> int:
	return draw_pile.size()

func _next_id() -> String:
	_id_counter += 1
	return "tile_%d" % _id_counter
