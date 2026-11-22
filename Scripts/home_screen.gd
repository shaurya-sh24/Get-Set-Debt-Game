extends Control

@onready var play_button: Button = $PlayButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_music("frog_theme",-5)
	play_button.focus_mode = Control.FOCUS_NONE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	AudioManager.stop_music("frog_theme")
	AudioManager.play_sfx("ui", -15)
	SceneManager.load_new_main_scene()
