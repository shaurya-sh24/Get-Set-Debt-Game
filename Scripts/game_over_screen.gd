extends Control

@onready var rounds_label: Label = $VBoxContainer/RoundsLabel
@onready var bets_label: Label = $VBoxContainer/BetsLabel
@onready var base_label: Label = $VBoxContainer/BaseLabel
@onready var pair_label: Label = $VBoxContainer/PairLabel
@onready var flush_label: Label = $VBoxContainer/FlushLabel
@onready var cards_used_label: Label = $VBoxContainer/CardsUsedLabel
@onready var straight_label: Label = $VBoxContainer/StraightLabel
@onready var straight_flush_label: Label = $VBoxContainer/StraightFlushLabel
@onready var trio_label: Label = $VBoxContainer/TrioLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var color_rect: ColorRect = $ColorRect
@onready var retry_button: Button = $RetryButton

func _ready() -> void:
	AudioManager.play_music("heartbeat", -5)
	
	retry_button.focus_mode = Control.FOCUS_NONE
	
	var tween = create_tween()
	
	tween.tween_property(color_rect, "modulate:a", 0, 3.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rounds_label.text = "ROUNDS COMPLETED: " + str(PlayerData.round)
	score_label.text = "TOTAL SCORE: " + str(PlayerData.total_score)
	bets_label.text = "BETS HIT: " + str(PlayerData.number_of_bets_landed)
	base_label.text = "BASE: " + str(PlayerData.number_of_bases)
	pair_label.text = "PAIR: " + str(PlayerData.number_of_pair)
	flush_label.text = "FLUSH: " + str(PlayerData.number_of_flush)
	straight_label.text = "STRAIGHT: " + str(PlayerData.number_of_straight)
	straight_flush_label.text = "STRAIGHT FLUSH: " + str(PlayerData.number_of_straight_flush)
	trio_label.text = "THREE OF A KIND: " + str(PlayerData.number_of_trio)
	cards_used_label.text = "CARDS USED: " + str(PlayerData.number_of_collectibles_used)


func _on_retry_button_pressed() -> void:
	AudioManager.play_sfx("ui", -15)
	AudioManager.stop_all_music()
	var tween = create_tween()
	
	tween.tween_property(color_rect, "modulate:a", 1, 2.0)

	await get_tree().create_timer(2.0).timeout
	SceneManager.load_new_main_scene()
