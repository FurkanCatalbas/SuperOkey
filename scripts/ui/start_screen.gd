class_name StartScreen
extends Control

const GAME_SCENE_PATH := "res://scenes/game/Game.tscn"

@onready var play_button: TextureButton = $CenterBox/PlayButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_styles()
	play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _apply_styles() -> void:
	play_button.custom_minimum_size = Vector2.ZERO
	play_button.ignore_texture_size = false
	play_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	if play_button.texture_normal != null:
		var click_mask := BitMap.new()
		click_mask.create_from_image_alpha(play_button.texture_normal.get_image())
		play_button.texture_click_mask = click_mask
