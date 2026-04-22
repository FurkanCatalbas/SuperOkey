class_name DiscardZone
extends PanelContainer

signal tile_discarded(data: Dictionary)

var _active: bool = true
var _hovered: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	_update_style()

func set_active(active: bool) -> void:
	_active = active
	_update_style()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	_hovered = _active and typeof(data) == TYPE_DICTIONARY and data.get("source_kind", "") == "hand"
	_update_style()
	return _hovered

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_hovered = false
	_update_style()
	tile_discarded.emit(data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_hovered = false
		_update_style()

func _update_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.set_border_width_all(3)
	style.bg_color = Color(0.36, 0.09, 0.09, 0.88) if _active else Color(0.17, 0.16, 0.18, 0.82)
	style.border_color = Color(1.0, 0.54, 0.32, 0.96) if _hovered else Color(0.56, 0.14, 0.14, 0.9)
	style.shadow_color = Color(0.24, 0.03, 0.03, 0.34) if _active else Color(0.0, 0.0, 0.0, 0.18)
	style.shadow_size = 12
	add_theme_stylebox_override("panel", style)
