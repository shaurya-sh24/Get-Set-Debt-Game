extends Node

const MAIN = preload("uid://bwennd7rretlk")
const HOME_SCREEN = preload("uid://bkhg0bum7srtu")
const GAME_OVER_SCREEN = preload("uid://rjmhaqk44jc8")

func load_new_main_scene():
	PlayerData.reset_player_data()
	get_tree().change_scene_to_packed(MAIN)

func load_home_screen():
	get_tree().change_scene_to_packed(HOME_SCREEN)

func load_game_over_screen():
	get_tree().change_scene_to_packed(GAME_OVER_SCREEN)
