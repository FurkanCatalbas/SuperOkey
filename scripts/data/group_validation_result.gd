class_name GroupValidationResult
extends RefCounted

var group_name: String = ""
var detected_type: String = "INVALID"
var is_valid: bool = false
var score: int = 0
var resolved_tiles: Array = []
var joker_notes: Array[String] = []
var reason: String = ""

func get_summary_text() -> String:
	var parts: Array[String] = []
	parts.append("%s: %s" % [group_name, detected_type])
	parts.append("Valid" if is_valid else "Invalid")
	parts.append("Score %d" % score)
	
	if resolved_tiles.size() > 0:
		parts.append(_resolved_text())
	
	if joker_notes.size() > 0:
		parts.append("Jokers: %s" % "; ".join(joker_notes))
		
	if reason != "":
		parts.append(reason)
	
	return " | ".join(parts)

func _resolved_text() -> String:
	var texts: Array[String] = []
	for item in resolved_tiles:
		texts.append(item["display_text"])
	
	return ", ".join(texts)
