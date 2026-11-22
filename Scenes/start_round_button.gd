extends Interactable

signal interacted()

var interactable = true

func _ready() -> void:
	prompt_message = "Start round"
	key_name = "E"

func interact(body):
	if interactable:
		emit_signal("interacted")

func interact_with_mouse():
	if interactable:
		emit_signal("interacted")

func get_prompt() -> String:
	if interactable:
		return prompt_message + "\n" + "[" + key_name + "]"
	else:
		return ""
