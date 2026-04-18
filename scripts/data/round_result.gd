class_name RoundResult
extends RefCounted

var round_number: int = 1
var group_results: Array = []
var unused_tiles: Array = []
var total_score: int = 0
var penalty_score: int = 0
var net_score: int = 0
var target_reached: bool = false

func get_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Round %d" % round_number)
	for group_result in group_results:
		lines.append(group_result.get_summary_text())
	lines.append("Unused: %d" % unused_tiles.size())
	lines.append("Total: %d" % total_score)
	lines.append("Penalty: -%d" % penalty_score)
	lines.append("Net: %d" % net_score)
	lines.append("Result: %s" % ("Success" if target_reached else "Fail"))
	return "\n".join(lines)
