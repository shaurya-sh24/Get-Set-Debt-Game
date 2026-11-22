extends Node

# ==========================================
# AUDIO ASSET REGISTRY (Preloaded Streams)
# ==========================================

const MUSIC = {
	"bg1": preload("res://Assets/Audio/music/bg1.mp3"),
	"bg2": preload("res://Assets/Audio/music/bg2.mp3"),
	"casino_theme": preload("res://Assets/Audio/music/casino theme.mp3"),
	"frog_theme": preload("res://Assets/Audio/music/frog theme.mp3"),
	"fuzzy_static": preload("res://Assets/Audio/music/fuzzystatic.mp3"),
	"game_over": preload("res://Assets/Audio/music/game over alert.mp3"),
	"roulette": preload("res://Assets/Audio/music/roulette wheel.mp3"),
	"heartbeat": preload("res://Assets/Audio/music/heartbeat.mp3")
}

const SFX = {
	"bet": preload("res://Assets/Audio/sfx/bet_placing.mp3"),
	"card_select": preload("res://Assets/Audio/sfx/card select.mp3"),
	"card_swoop": preload("res://Assets/Audio/sfx/card swoop.mp3"),
	"gun": preload("res://Assets/Audio/sfx/gun bang.mp3"),
	"round_end": preload("res://Assets/Audio/sfx/round end.mp3"),
	"shop": preload("res://Assets/Audio/sfx/shop.mp3"),
	"ui": preload("res://Assets/Audio/sfx/ui_sound1.mp3")
}

const DIALOGUE = {
	"frog1": preload("res://Assets/Audio/dialogues/frog1.mp3"),
	"frog2": preload("res://Assets/Audio/dialogues/frog2.mp3"),
	"frog3": preload("res://Assets/Audio/dialogues/frog3.mp3"),
	"frog4": preload("res://Assets/Audio/dialogues/frog4.mp3"),
	"frog5": preload("res://Assets/Audio/dialogues/frog5.mp3"),
	"frog6": preload("res://Assets/Audio/dialogues/frog6.mp3"),
	"frog7": preload("res://Assets/Audio/dialogues/frog7.mp3"),
	"frog8": preload("res://Assets/Audio/dialogues/frog8.mp3"),
	"frog9": preload("res://Assets/Audio/dialogues/frog9.mp3"),
	"frog10": preload("res://Assets/Audio/dialogues/frog10.mp3"),
}

# ==========================================
# PUBLIC CORE FUNCTIONS
# ==========================================
var active_music: Dictionary = {}

# ==========================================
# PUBLIC CORE FUNCTIONS
# ==========================================

## Plays a Music track and tracks it so it can be stopped later.
func play_music(track_key: String, volume_db: float = 0.0) -> void:
	if not MUSIC.has(track_key):
		push_error("Music key not found: ", track_key)
		return
		
	# If this track is already playing, stop it first to prevent overlapping duplicates
	stop_music(track_key)
	
	# Spawn the player and store its reference in our dictionary
	var player = _spawn_audio_player(MUSIC[track_key], volume_db)
	active_music[track_key] = player

## Stops a specific currently playing music track.
func stop_music(track_key: String) -> void:
	if active_music.has(track_key):
		var player = active_music[track_key]
		# Ensure the node still exists before trying to delete it
		if is_instance_valid(player):
			player.queue_free() # Deleting the node stops the audio instantly
		active_music.erase(track_key)

## Stops absolutely all music currently playing.
func stop_all_music() -> void:
	for key in active_music.keys():
		stop_music(key)

## Plays a Sound Effect simultaneously.
func play_sfx(sfx_key: String, volume_db: float = 0.0) -> void:
	if SFX.has(sfx_key):
		_spawn_audio_player(SFX[sfx_key], volume_db)
	else:
		push_error("SFX key not found: ", sfx_key)

## Plays a Dialogue line simultaneously.
func play_dialogue(dialogue_key: String, volume_db: float = 0.0) -> void:
	if DIALOGUE.has(dialogue_key):
		_spawn_audio_player(DIALOGUE[dialogue_key], volume_db)
	else:
		push_error("Dialogue key not found: ", dialogue_key)

# ==========================================
# PRIVATE HELPER FUNCTIONS
# ==========================================

# Instantiates, configures, plays, and safely cleans up the player node.
# Now returns the AudioStreamPlayer so we can track it!
func _spawn_audio_player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var new_player := AudioStreamPlayer.new()
	new_player.stream = stream
	new_player.volume_db = volume
	
	add_child(new_player)
	new_player.play()
	
	new_player.finished.connect(new_player.queue_free)
	
	return new_player
