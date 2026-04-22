class_name JokerCardData
extends RefCounted

var id: String = ""
var title: String = ""
var description: String = ""
var target_type: String = ""
var exact_size: int = 0
var min_size: int = 0
var max_size: int = 0
var min_value: int = 0
var max_value: int = 0
var requires_joker: bool = false
var multiplier: float = 1.0

func _init(config: Dictionary = {}) -> void:
	id = config.get("id", "")
	title = config.get("title", "")
	description = config.get("description", "")
	target_type = config.get("target_type", "")
	exact_size = config.get("exact_size", 0)
	min_size = config.get("min_size", 0)
	max_size = config.get("max_size", 0)
	min_value = config.get("min_value", 0)
	max_value = config.get("max_value", 0)
	requires_joker = config.get("requires_joker", false)
	multiplier = config.get("multiplier", 1.0)

func matches(validation: GroupValidationResult) -> bool:
	if not validation.is_valid:
		return false
	if target_type != "" and validation.detected_type != target_type:
		return false
	if exact_size > 0 and validation.resolved_tiles.size() != exact_size:
		return false
	if min_size > 0 and validation.resolved_tiles.size() < min_size:
		return false
	if max_size > 0 and validation.resolved_tiles.size() > max_size:
		return false
	if requires_joker and validation.joker_notes.is_empty():
		return false

	var resolved_value := 0
	if not validation.resolved_tiles.is_empty():
		resolved_value = int(validation.resolved_tiles[0].get("resolved_value", 0))
	if min_value > 0 and resolved_value < min_value:
		return false
	if max_value > 0 and resolved_value > max_value:
		return false
	return true
