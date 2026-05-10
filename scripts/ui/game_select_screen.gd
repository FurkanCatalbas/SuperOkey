class_name GameSelectScreen
extends Control

const START_SCENE_PATH := "res://scenes/main/start_screen.tscn"
const OKEY_SCENE_PATH := "res://scenes/game/Game.tscn"
const POKER_SCENE_PATH := "res://scenes/game/PokerGame.tscn"

@onready var title_label: Label = $TitleLabel
@onready var okey_button: Button = $OkeyButton
@onready var poker_button: Button = $PokerButton
@onready var back_button: Button = $BackButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_styles()
	okey_button.pressed.connect(_on_okey_pressed)
	poker_button.pressed.connect(_on_poker_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_okey_pressed() -> void:
	get_tree().change_scene_to_file(OKEY_SCENE_PATH)

func _on_poker_pressed() -> void:
	get_tree().change_scene_to_file(POKER_SCENE_PATH)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(START_SCENE_PATH)

func _apply_styles() -> void:
	$Background.modulate = Color(1.0, 1.0, 1.0, 0.92)
	title_label.add_theme_font_size_override("font_size", 52)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.56))
	title_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 0.98))
	title_label.add_theme_constant_override("outline_size", 5)
	for button in [okey_button, poker_button, back_button]:
		button.custom_minimum_size = Vector2(420.0, 150.0)
		button.add_theme_font_size_override("font_size", 28)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.1, 0.13, 0.17, 0.96), Color(1.0, 1.0, 1.0, 0.12)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.15, 0.2, 0.26, 0.98), Color(1.0, 0.82, 0.34, 0.95)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.07, 0.1, 0.14, 1.0), Color(1.0, 0.92, 0.58, 1.0)))
	back_button.custom_minimum_size = Vector2(300.0, 78.0)

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

func _button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style
