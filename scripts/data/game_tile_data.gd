class_name GameTileData
extends RefCounted

var id: String
var color: String
var value: int
var is_joker: bool = false

func _init(_id: String, _color: String, _value: int, _is_joker: bool = false):
	id = _id
	color = _color
	value = _value
	is_joker = _is_joker

func get_display_text() -> String:
	if is_joker:
		return "JOKER"
	return "%s %d" % [color.capitalize(), value]
