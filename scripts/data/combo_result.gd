class_name ComboResult
extends RefCounted

var combo_type: String
var tiles: Array
var base_score: int = 0
var multiplier: float = 1.0
var total_score: int = 0

func _init(_combo_type: String, _tiles: Array):
	combo_type = _combo_type
	tiles = _tiles

func get_label() -> String:
	return "%s (%d tiles)" % [combo_type.to_upper(), tiles.size()]
