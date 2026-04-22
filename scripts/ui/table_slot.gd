class_name TableSlot
extends RefCounted

var row: int = -1
var column: int = -1
var center: Vector2 = Vector2.ZERO
var slot_size: Vector2 = Vector2.ZERO
var occupied_tile: GameTileData = null
var highlight_state: String = "normal"

func _init(new_row: int = -1, new_column: int = -1) -> void:
	row = new_row
	column = new_column

func is_empty() -> bool:
	return occupied_tile == null

func rect() -> Rect2:
	return Rect2(center - (slot_size * 0.5), slot_size)

func key() -> String:
	return "%d:%d" % [row, column]
