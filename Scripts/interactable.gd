class_name Interactable
extends StaticBody3D

@export var prompt_message: String = "Interact"
@export var key_name: String = "E"
@onready var prompt_keycode = OS.find_keycode_from_string(key_name)

func hover_start():
	pass

func hover_end():
	pass

func interact(body) -> void:
	pass

func interact_with_mouse():
	pass

func get_prompt() -> String:
	return prompt_message + "\n" + "[" + key_name + "]"
