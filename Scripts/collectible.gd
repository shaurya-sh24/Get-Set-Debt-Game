extends Interactable

var collectible_folder = "res://Assets/Collectibles/"

@onready var hover_mesh: MeshInstance3D = $Sprite/Cube_025/OutlineMesh
@onready var clicked_mesh: MeshInstance3D = $Sprite/Cube_025/OutlineMesh2
@onready var mesh: MeshInstance3D = $Sprite/Cube_025
@onready var price_mesh: MeshInstance3D = $Sprite/Cube_025/PriceMesh
@onready var label: Label = $Sprite/Cube_025/SubViewport/Control/Label

enum STATE {Item, Collectible}



@export var collectible_type: Globals.CollectibleType
@export var price: int

var desc: String
var collectible_name: String

var state = STATE.Item:
	set(new_state):
		if new_state==STATE.Collectible:
			state = STATE.Collectible



var can_be_selected = true
var selected: bool = false



func _ready() -> void:
	hover_mesh.visible = false

func hover_start():
	hover_mesh.visible = true

func hover_end():
	hover_mesh.visible = false

func interact(body) -> void:
	if state == STATE.Collectible and can_be_selected:
		AudioManager.play_sfx("card_select", -10)
		SignalBus.collectible_selected.emit(self)
	elif state == STATE.Item:
		if (PlayerData.money>=price+PlayerData.round_fee) and PlayerData.number_of_collectibles<3:
			AudioManager.play_sfx("shop", -10)
			state = STATE.Collectible
			PlayerData.take_money_from_player(price)
			SignalBus.make_collectible_useable.emit(self)
		if (PlayerData.money<price+PlayerData.round_fee) and PlayerData.number_of_collectibles<3:
			SignalBus.give_help.emit("SAVE CHIPS FOR ROUND FEE!")
		if PlayerData.number_of_collectibles>=3:
			SignalBus.give_help.emit("YOU CAN ONLY HAVE 3 COLLECTIBLES!")

func interact_with_mouse():
	if state == STATE.Collectible and can_be_selected:
		AudioManager.play_sfx("card_select", -10)
		SignalBus.collectible_selected.emit(self)
	elif state == STATE.Item:
		if (PlayerData.money>=price+PlayerData.round_fee) and PlayerData.number_of_collectibles<3:
			AudioManager.play_sfx("shop", -10)
			state = STATE.Collectible
			PlayerData.take_money_from_player(price)
			SignalBus.make_collectible_useable.emit(self)
		if (PlayerData.money<price+PlayerData.round_fee) and PlayerData.number_of_collectibles<3:
			SignalBus.give_help.emit("SAVE CHIPS FOR ROUND FEE!")
		if PlayerData.number_of_collectibles>=3:
			SignalBus.give_help.emit("YOU CAN ONLY HAVE 3 COLLECTIBLES!")



func get_prompt():
	return collectible_name+": "+desc

func _process(delta: float) -> void:
	update_collectible_data()
	if selected and state == STATE.Collectible:
		clicked_mesh.visible = true
	elif !selected and state == STATE.Collectible:
		clicked_mesh.visible = false

func update_collectible_data():
	var mat = collectible_folder+collectible_name+".tres"
	mesh.set_surface_override_material(1, load(mat))
	collectible_name = Globals.CollectibleType.find_key(collectible_type)
	price = Globals.collectible_data[collectible_type]["price"]
	desc = Globals.collectible_data[collectible_type]["desc"]
	label.text = "🪙"+str(price)
	
	if state == STATE.Item:
		price_mesh.visible = true
	else:
		price_mesh.visible = false
		
