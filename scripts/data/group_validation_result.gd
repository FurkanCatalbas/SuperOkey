class_name GroupValidationResult
extends RefCounted

var group_name: String = ""
var detected_type: String = "INVALID"
var is_valid: bool = false
var score: int = 0
var chips: int = 0
var base_chips: int = 0
var multiplier_bonus: float = 0.0
var resolved_tiles: Array = []
var joker_notes: Array[String] = []
var applied_jokers: Array[String] = []
var reason: String = ""

func get_summary_text() -> String:
	var parts: Array[String] = []
	parts.append("%s: %s" % [group_name, detected_type])
	parts.append("Valid" if is_valid else "Invalid")
	parts.append("Chips %d" % chips)
	if base_chips != chips:
		parts.append("Base %d" % base_chips)
	if multiplier_bonus > 0.0:
		parts.append("Multiplier +%s" % _format_multiplier(multiplier_bonus))
	if applied_jokers.size() > 0:
		parts.append("Joker Cards: %s" % ", ".join(applied_jokers))
	
	if resolved_tiles.size() > 0:
		parts.append(_resolved_text())
	
	if joker_notes.size() > 0:
		parts.append("Jokers: %s" % "; ".join(joker_notes))
		
	if reason != "":
		parts.append(reason)
	
	return " | ".join(parts)

func set_scoring(new_chips: int, new_multiplier_bonus: float = 0.0) -> void:
	base_chips = new_chips
	chips = new_chips
	multiplier_bonus = new_multiplier_bonus
	score = new_chips

func apply_joker_card(card: JokerCardData) -> void:
	if applied_jokers.has(card.title):
		return
	chips = int(round(float(chips) * card.multiplier))
	score = chips
	applied_jokers.append(card.title)

func _resolved_text() -> String:
	var texts: Array[String] = []
	for item in resolved_tiles:
		texts.append(item["display_text"])
	
	return ", ".join(texts)

func _format_multiplier(value: float) -> String:
	var formatted = "%.1f" % value
	while formatted.ends_with("0"):
		formatted = formatted.left(formatted.length() - 1)
	if formatted.ends_with("."):
		formatted = formatted.left(formatted.length() - 1)
	return formatted
