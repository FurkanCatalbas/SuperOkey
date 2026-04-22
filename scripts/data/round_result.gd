class_name RoundResult
extends RefCounted

var round_number: int = 1
var group_results: Array = []
var unused_tiles: Array = []
var total_score: int = 0
var penalty_score: int = 0
var multiplier: float = 1.0
var net_score: float = 0.0
var target_reached: bool = false

func get_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Round %d" % round_number)
	for group_result in group_results:
		lines.append(group_result.get_summary_text())
	lines.append("Unused: %d" % unused_tiles.size())
	lines.append("Total Chips: %d" % total_score)
	lines.append("Penalty: -%d" % penalty_score)
	lines.append("Multiplier: x%s" % _format_multiplier(multiplier))
	lines.append("Final Score: %s" % _format_multiplier(net_score))
	lines.append("Result: %s" % ("Success" if target_reached else "Fail"))
	return "\n".join(lines)

func _format_multiplier(value: float) -> String:
	var formatted = "%.2f" % value
	while formatted.ends_with("0"):
		formatted = formatted.left(formatted.length() - 1)
	if formatted.ends_with("."):
		formatted = formatted.left(formatted.length() - 1)
	return formatted
