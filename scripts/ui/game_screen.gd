class_name GameScreen
extends Control

@onready var layout: VBoxContainer = $Layout
@onready var round_label: Label = $Layout/TopBar/RoundLabel
@onready var target_score_label: Label = $Layout/TopBar/TargetScoreLabel
@onready var deck_count_label: Label = $Layout/TopBar/DeckCountLabel
@onready var hand_view: HandView = $Layout/HandContainer
@onready var result_label: RichTextLabel = $Layout/ResultPanel/ResultLabel
@onready var draw_button: Button = $Layout/Buttons/DrawButton
@onready var sort_color_button: Button = $Layout/Buttons/SortColorButton
@onready var sort_value_button: Button = $Layout/Buttons/SortValueButton
@onready var finish_round_button: Button = $Layout/Buttons/FinishRoundButton

var game_manager := GameManager.new()

func _ready() -> void:
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_button.pressed.connect(_on_draw_button_pressed)
	sort_color_button.pressed.connect(_on_sort_color_button_pressed)
	sort_value_button.pressed.connect(_on_sort_value_button_pressed)
	finish_round_button.pressed.connect(_on_finish_round_button_pressed)

	game_manager.start_game()
	_refresh_ui()
	result_label.text = ""

func _on_draw_button_pressed() -> void:
	game_manager.round_manager.draw_one_tile()
	_refresh_ui()

func _on_sort_color_button_pressed() -> void:
	game_manager.round_manager.hand_model.sort_by_color_then_value()
	_refresh_ui()

func _on_sort_value_button_pressed() -> void:
	game_manager.round_manager.hand_model.sort_by_value_then_color()
	_refresh_ui()

func _on_finish_round_button_pressed() -> void:
	var result = game_manager.finish_current_round()
	_refresh_ui()
	result_label.text = result.get_summary_text()

func _refresh_ui() -> void:
	round_label.text = "Round: %d" % game_manager.current_round
	target_score_label.text = "Target: %d" % game_manager.round_manager.target_score
	deck_count_label.text = "Deck: %d" % game_manager.round_manager.deck_manager.remaining_count()
	hand_view.render_tiles(game_manager.round_manager.hand_model.tiles)
