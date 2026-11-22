extends Interactable

signal interacted()

var can_interact: bool = false
@onready var main: Node3D = $"../.."

func _ready() -> void:
	prompt_message = "Spin roulette to get card"
	key_name = "E"

func get_prompt() -> String:
	if can_interact and !main.player_got_all_cards():
		return prompt_message + "\n" + "[" + key_name + "]"
	else:
		return ""

func interact(body):
	if can_interact and !main.player_got_all_cards():
		print("interacted with roulette")
		emit_signal("interacted")
