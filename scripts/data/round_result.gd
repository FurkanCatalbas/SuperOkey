class_name RoundResult
extends RefCounted

var round_number: int = 1
var combos: Array = []
var unused_tiles: Array = []
var total_score: int = 0
var penalty_score: int = 0
var net_score: int = 0
var target_reached: bool = false

func get_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Round %d" % round_number)
	for combo in combos:
		lines.append("- %s: %s" % [combo.combo_type.to_upper(), _tiles_to_text(combo.tiles)])
	lines.append("Unused: %d" % unused_tiles.size())
	lines.append("Total: %d" % total_score)
	lines.append("Penalty: -%d" % penalty_score)
	lines.append("Net: %d" % net_score)
	lines.append("Success" if target_reached else "Fail")
	return "\n".join(lines)

func _tiles_to_text(tiles: Array) -> String:
	var parts: Array[String] = []
	for tile in tiles:
		parts.append(tile.get_display_text())
	return ", ".join(parts) 
