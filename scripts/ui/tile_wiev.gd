class_name TileView
extends Button

signal tile_selected(tile: GameTileData)

@export_dir var tile_texture_directory := "res://assets/tiles"
@export var fallback_texture: Texture2D

var tile_data: GameTileData
var source_kind: String = ""
var source_row: int = -1
var source_column: int = -1
var current_slot_row: int = -1
var current_slot_column: int = -1

var tile_art: TextureRect

static var _texture_cache := {}
func setup(data: GameTileData, new_source_kind: String, row: int = -1, column: int = -1) -> void:
	tile_data = data
	source_kind = new_source_kind
	source_row = row
	source_column = column
	current_slot_row = row
	current_slot_column = column



	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(78, 114)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	mouse_filter = Control.MOUSE_FILTER_PASS
	_flatten_style(false)
	if not is_node_ready():
		await ready
	_apply_tile_texture()
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _ready() -> void:
	tile_art = get_node_or_null("TileArt") as TextureRect
	if tile_art == null:
		push_error("TileArt bulunamadı!")
		
func set_selected(selected: bool) -> void:
	_flatten_style(selected)
	if tile_art:
		tile_art.modulate = Color(1.0, 0.98, 0.88) if selected else Color.WHITE
		
func play_snap_animation() -> void:
	scale = Vector2(0.95, 0.95)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := TextureRect.new()
	preview.custom_minimum_size = custom_minimum_size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = tile_art.texture
	preview.modulate = Color(1.0, 1.0, 1.0, 0.94)
	set_drag_preview(preview)
	return {
		"tile_id": tile_data.id,
		"source_kind": source_kind,
		"source_row": source_row,
		"source_column": source_column
	}

func _on_pressed() -> void:
	tile_selected.emit(tile_data)

func _flatten_style(selected: bool) -> void:
	var style: StyleBox = StyleBoxEmpty.new()
	if selected:
		var accent := StyleBoxFlat.new()
		accent.bg_color = Color(1.0, 1.0, 1.0, 0.0)
		accent.border_color = Color(1.0, 0.89, 0.46, 0.95)
		accent.set_border_width_all(2)
		accent.corner_radius_top_left = 8
		accent.corner_radius_top_right = 8
		accent.corner_radius_bottom_left = 8
		accent.corner_radius_bottom_right = 8
		accent.expand_margin_left = 2.0
		accent.expand_margin_top = 2.0
		accent.expand_margin_right = 2.0
		accent.expand_margin_bottom = 2.0
		style = accent
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_stylebox_override("focus", style)
	add_theme_stylebox_override("disabled", style)

func _apply_tile_texture() -> void:
	if tile_art == null:
		return
	tile_art.texture = _load_tile_texture()

func _load_tile_texture() -> Texture2D:
	var texture_path = _tile_texture_path_for(tile_data)
	if texture_path != "":
		if not _texture_cache.has(texture_path):
			_texture_cache[texture_path] = load(texture_path)
		var loaded_texture: Texture2D = _texture_cache[texture_path]
		if loaded_texture != null:
			return loaded_texture
	return fallback_texture

func _tile_texture_path_for(data: GameTileData) -> String:
	if data == null or tile_texture_directory.strip_edges() == "":
		return ""
	var directory = tile_texture_directory
	if directory.ends_with("/"):
		directory = directory.left(directory.length() - 1)
	var file_name = "joker.png" if data.is_joker else "%s_%d.png" % [data.color.to_lower(), data.value]
	return "%s/%s" % [directory, file_name]
