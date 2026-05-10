class_name PokerScreen
extends Control

const START_SCENE_PATH := "res://scenes/main/start_screen.tscn"
const POKER_MANAGER_SCRIPT := preload("res://scripts/core/poker_game_manager.gd")
const MAX_SELECTED := 3
const CARD_ASSET_PATH := "res://assets/cards/poker/%s_%s.png"
const COMPACT_CARD_ASSET_PATH := "res://assets/cards/poker/%s%s.png"
const CARD_SIZE := Vector2(170.0, 328.0)
const CARD_HOLDER_SIZE := Vector2(170.0, 368.0)
const CARD_REST_Y := 38.0
const CARD_SELECTED_Y := 0.0

var poker_manager = POKER_MANAGER_SCRIPT.new()
var selected_ids: Array = []

@onready var round_label: Label = $Root/TopBar/TopContent/RoundLabel
@onready var target_label: Label = $Root/TopBar/TopContent/TargetLabel
@onready var deck_label: Label = $Root/TopBar/TopContent/DeckLabel
@onready var score_label: Label = $Root/MainRow/SidePanel/SideContent/ScoreLabel
@onready var hands_label: Label = $Root/MainRow/SidePanel/SideContent/HandsLabel
@onready var discards_label: Label = $Root/MainRow/SidePanel/SideContent/DiscardsLabel
@onready var result_label: Label = $Root/MainRow/SidePanel/SideContent/ResultLabel
@onready var cards_row: HBoxContainer = $Root/CardPanel/CardContent/CardsRow
@onready var hint_label: Label = $Root/CardPanel/CardContent/HintLabel
@onready var play_button: Button = $Root/CardPanel/CardContent/ActionRow/PlayButton
@onready var discard_button: Button = $Root/CardPanel/CardContent/ActionRow/DiscardButton
@onready var new_run_button: Button = $Root/CardPanel/CardContent/ActionRow/NewRunButton
@onready var back_button: Button = $Root/TopBar/TopContent/BackButton
@onready var popup_layer: Control = $PopupLayer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_styles()
	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	new_run_button.pressed.connect(_on_new_run_pressed)
	back_button.pressed.connect(_on_back_pressed)
	poker_manager.start_run()
	_refresh_ui()

func _on_card_pressed(card_id: String) -> void:
	if selected_ids.has(card_id):
		selected_ids.erase(card_id)
	elif selected_ids.size() < MAX_SELECTED:
		selected_ids.append(card_id)
	_refresh_ui()

func _on_play_pressed() -> void:
	var previous_score: int = poker_manager.score
	var played_ids := selected_ids.duplicate()
	_set_actions_disabled(true)
	await _animate_selected_cards_exit(played_ids, Vector2(0.0, -90.0), 0.18)
	poker_manager.play_selected(played_ids)
	selected_ids = []
	_refresh_ui()
	var gained_score: int = poker_manager.score - previous_score
	_show_hand_result_banner(poker_manager.last_result.get("name", ""))
	_show_score_popup(gained_score)
	_set_actions_disabled(false)

func _on_discard_pressed() -> void:
	var discarded_ids := selected_ids.duplicate()
	_set_actions_disabled(true)
	await _animate_selected_cards_exit(discarded_ids, Vector2(0.0, 130.0), 0.16)
	if poker_manager.discard_selected(discarded_ids):
		selected_ids = []
	_refresh_ui()
	_set_actions_disabled(false)

func _on_new_run_pressed() -> void:
	selected_ids = []
	poker_manager.start_run()
	_refresh_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(START_SCENE_PATH)

func _refresh_ui() -> void:
	round_label.text = "Poker Round %d" % poker_manager.round
	target_label.text = "Hedef %d" % poker_manager.target_score
	deck_label.text = "Deste %d" % poker_manager.deck.size()
	score_label.text = str(poker_manager.score)
	hands_label.text = "El hakki: %d" % poker_manager.hands_left
	discards_label.text = "Degisim: %d" % poker_manager.discards_left

	if poker_manager.last_result.is_empty():
		result_label.text = "3 karta kadar sec, poker elini oyna."
	elif poker_manager.last_result.get("run_over", false):
		result_label.text = "%s\nChip %d x%d = %d\nRun bitti. Yeni run baslat." % [
			poker_manager.last_result.get("name", ""),
			poker_manager.last_result.get("chips", 0),
			poker_manager.last_result.get("multiplier", 0),
			poker_manager.last_result.get("score", 0),
		]
	elif poker_manager.last_result.get("round_advanced", false):
		result_label.text = "%s\nChip %d x%d = %d\nYeni round!" % [
			poker_manager.last_result.get("name", ""),
			poker_manager.last_result.get("chips", 0),
			poker_manager.last_result.get("multiplier", 0),
			poker_manager.last_result.get("score", 0),
		]
	else:
		result_label.text = "%s\nChip %d x%d = %d" % [
			poker_manager.last_result.get("name", ""),
			poker_manager.last_result.get("chips", 0),
			poker_manager.last_result.get("multiplier", 0),
			poker_manager.last_result.get("score", 0),
		]

	hint_label.text = "%d/%d kart secili" % [selected_ids.size(), MAX_SELECTED]
	play_button.disabled = selected_ids.is_empty() or poker_manager.hands_left <= 0
	discard_button.disabled = selected_ids.is_empty() or poker_manager.discards_left <= 0
	_render_cards()

func _render_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()

	for card in poker_manager.hand:
		var card_holder := Control.new()
		card_holder.custom_minimum_size = CARD_HOLDER_SIZE
		cards_row.add_child(card_holder)

		var card_button := Button.new()
		card_button.name = card["id"]
		card_button.custom_minimum_size = CARD_SIZE
		card_button.size = CARD_SIZE
		card_button.position = Vector2(0.0, CARD_REST_Y)
		card_button.toggle_mode = true
		card_button.button_pressed = selected_ids.has(card["id"])
		card_button.clip_contents = true
		var card_texture := _card_texture(card)
		if card_texture != null:
			card_button.text = ""
		else:
			card_button.text = "%s\n%s" % [_rank_label(card["rank"]), card["suit"]]
		card_button.add_theme_font_size_override("font_size", 30)
		card_button.add_theme_stylebox_override("normal", _card_style(card["suit"], false))
		card_button.add_theme_stylebox_override("hover", _card_style(card["suit"], true))
		card_button.add_theme_stylebox_override("pressed", _selected_card_style(card["suit"]))
		card_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		card_button.pivot_offset = CARD_SIZE * 0.5
		card_button.pressed.connect(_on_card_pressed.bind(card["id"]))
		card_holder.add_child(card_button)
		if card_texture != null:
			var image_panel := PanelContainer.new()
			image_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image_panel.clip_contents = true
			image_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			image_panel.add_theme_stylebox_override("panel", _card_image_mask_style())
			card_button.add_child(image_panel)

			var texture_rect := TextureRect.new()
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			texture_rect.offset_left = 0.0
			texture_rect.offset_top = 0.0
			texture_rect.offset_right = 0.0
			texture_rect.offset_bottom = 0.0
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
			texture_rect.texture = card_texture
			image_panel.add_child(texture_rect)
		_animate_card_to_state(card_button, selected_ids.has(card["id"]))

func _animate_card_to_state(card_button: Button, selected: bool) -> void:
	var target_y := CARD_SELECTED_Y if selected else CARD_REST_Y
	var target_scale := Vector2(1.04, 1.04) if selected else Vector2.ONE
	var target_modulate := Color(1.0, 0.96, 0.74, 1.0) if selected else Color.WHITE
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_button, "position:y", target_y, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "scale", target_scale, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_button, "modulate", target_modulate, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _animate_selected_cards_exit(card_ids: Array, offset: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var animated := false
	for card_button in _card_buttons_by_ids(card_ids):
		animated = true
		tween.tween_property(card_button, "position", card_button.position + offset, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(card_button, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(card_button, "scale", Vector2(0.86, 0.86), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if animated:
		await tween.finished

func _card_buttons_by_ids(card_ids: Array) -> Array:
	var buttons := []
	for holder in cards_row.get_children():
		for child in holder.get_children():
			if child is Button and card_ids.has(str(child.name)):
				buttons.append(child)
	return buttons

func _show_score_popup(score_delta: int) -> void:
	if score_delta <= 0:
		return
	var label := Label.new()
	label.text = "+%d" % score_delta
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(size.x * 0.5 - 90.0, size.y * 0.34)
	label.size = Vector2(180.0, 60.0)
	label.modulate = Color(1.0, 0.9, 0.36, 1.0)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.05, 0.0, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	popup_layer.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 72.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.finished.connect(label.queue_free)

func _show_hand_result_banner(hand_name: String) -> void:
	if hand_name.is_empty():
		return
	var label := Label.new()
	label.text = hand_name.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(size.x * 0.5 - 220.0, size.y * 0.18)
	label.size = Vector2(440.0, 72.0)
	label.scale = Vector2(0.78, 0.78)
	label.modulate = Color(0.75, 1.0, 0.86, 0.0)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.08, 0.05, 0.96))
	label.add_theme_constant_override("outline_size", 5)
	popup_layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(label, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.22)
	tween.finished.connect(label.queue_free)

func _set_actions_disabled(disabled: bool) -> void:
	play_button.disabled = disabled or selected_ids.is_empty() or poker_manager.hands_left <= 0
	discard_button.disabled = disabled or selected_ids.is_empty() or poker_manager.discards_left <= 0
	new_run_button.disabled = disabled
	back_button.disabled = disabled

func _rank_label(rank: int) -> String:
	match rank:
		1:
			return "A"
		11:
			return "J"
		12:
			return "Q"
		13:
			return "K"
		14:
			return "A"
	return str(rank)

func _card_texture(card: Dictionary) -> Texture2D:
	for texture_path in _card_texture_paths(card):
		if ResourceLoader.exists(texture_path):
			return load(texture_path)
	return null

func _card_texture_paths(card: Dictionary) -> Array[String]:
	var suit_name := _suit_asset_name(card["suit"])
	return [
		CARD_ASSET_PATH % [suit_name, _rank_asset_name(card["rank"])],
		COMPACT_CARD_ASSET_PATH % [suit_name, _rank_number_asset_name(card["rank"])],
	]

func _suit_asset_name(suit: String) -> String:
	match suit:
		"red":
			return "red"
		"white":
			return "white"
		"black":
			return "black"
		"blue":
			return "blue"
	return suit.to_lower()

func _rank_asset_name(rank: int) -> String:
	match rank:
		1:
			return "ace"
		11:
			return "jack"
		12:
			return "queen"
		13:
			return "king"
		14:
			return "ace"
	return str(rank)

func _rank_number_asset_name(rank: int) -> String:
	return str(rank)

func _apply_styles() -> void:
	$Background.color = Color(0.025, 0.035, 0.045)
	$Root/TopBar.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.96), Color(0.65, 0.85, 1.0, 0.25), 18, 2))
	$Root/MainRow/SidePanel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.07, 0.09, 0.96), Color(1.0, 0.82, 0.38, 0.35), 22, 2))
	$Root/CardPanel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.22, 0.16, 0.95), Color(0.64, 1.0, 0.82, 0.22), 28, 2))
	score_label.add_theme_font_size_override("font_size", 54)
	result_label.add_theme_font_size_override("font_size", 22)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button in [play_button, discard_button, new_run_button, back_button]:
		button.add_theme_font_size_override("font_size", 20)

func _card_style(suit: String, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.96, 0.9) if not hovered else Color(1.0, 0.99, 0.94)
	style.border_color = Color(0.95, 0.78, 0.32) if suit == "red" or suit == "blue" else Color(0.22, 0.25, 0.3)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style

func _selected_card_style(suit: String) -> StyleBoxFlat:
	var style := _card_style(suit, true)
	style.bg_color = Color(1.0, 0.88, 0.48)
	style.border_color = Color(1.0, 0.96, 0.64)
	return style

func _card_image_mask_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _panel_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
