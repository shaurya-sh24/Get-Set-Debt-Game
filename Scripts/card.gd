extends Interactable

var cards_folder = "res://Assets/Cards/Card Material/"

@onready var outline_mesh: MeshInstance3D = $Sprite/Cube_025/OutlineMesh
@onready var outline_mesh_2: MeshInstance3D = $Sprite/Cube_025/OutlineMesh2

@export var card_data: CardData

@onready var mesh: MeshInstance3D = $Sprite/Cube_025

@onready var label: Label = $Sprite/Cube_025/SubViewport/Control/Label

@export var suit: Globals.CardSuit
@export var suit_name: String
@export var value: Globals.CardValue

var multiplier: int = 1

var can_be_selected: bool = true
var selected: bool = false

func _ready() -> void:
	outline_mesh.visible = false
	
	#suit = Globals.CardSuit.values().pick_random()
	#suit_name = Globals.CardSuit.find_key(suit)
	#value = Globals.CardValue.values().pick_random()

func hover_start():
	if get_parent().name == "PlayerCards":
		outline_mesh.visible = true

func hover_end():
	if get_parent().name == "PlayerCards":
		outline_mesh.visible = false

func interact(body) -> void:
	if can_be_selected:
		AudioManager.play_sfx("card_select", -10)
		selected = !selected

func interact_with_mouse():
	if can_be_selected:
		AudioManager.play_sfx("card_select", -10)
		selected = !selected

func get_prompt():
	return ""

func _process(delta: float) -> void:
	suit_name = Globals.CardSuit.find_key(suit)
	update_card_face()
	if selected:
		outline_mesh_2.visible = true
	else:
		outline_mesh_2.visible = false
	
	if multiplier>1:
		label.text = 'x'+str(multiplier)
	else:
		label.text = ""

func update_card_face():
	var mat = cards_folder+suit_name.to_lower()+str(value)+".tres"
	mesh.set_surface_override_material(1, load(mat))

func change_card_to_random():
	suit = Globals.CardSuit.values().pick_random()
	suit_name = Globals.CardSuit.find_key(suit)
	value = Globals.CardValue.values().pick_random()
	

func get_value():
	return value

func get_suit():
	return suit
