extends Node3D

var card_scene:PackedScene = preload("uid://du41vttg8asnd")
var collectible_scene = preload("uid://cxuhlqp3vjanx")


@onready var player_cards: Node3D = $PlayerData/PlayerCards
@onready var player_card_markers: Node3D = $Environment/Markers/PlayerCardMarkers
@onready var player_collectibles: Node3D = $PlayerData/PlayerCollectibles
var selected_collectible: Node3D = null
var TV_MATERIAL = preload("uid://fn6guhymx2s4")

@onready var start_button: Interactable = $Environment/StartButton
@onready var player: CharacterBody3D = $Player
@onready var markers: Node3D = $Environment/Markers
@onready var player_marker: Marker3D = $Environment/Markers/PlayerMarker
@onready var shop_markers: Node3D = $Environment/Markers/ShopMarkers
@onready var collectible_markers: Node3D = $Environment/Markers/CollectibleMarkers
@onready var shop: Node3D = $Environment/Shop


@onready var roulette: StaticBody3D = $Environment/Roulette
@onready var roulette_screen: Node3D = $RouletteScreen
@onready var roulette_2d: Node2D = $RouletteScreen/SubViewport/Roulette2D
@onready var roulette_camera: Camera3D = $RouletteCamera
@onready var tv_viewport: SubViewport = $TV/SubViewport
@onready var tv_mesh: MeshInstance3D = $TV/MeshInstance3D


var number_of_cards = 0
var number_of_cards_selected = 0

enum GameState {Idle, GettingCards, Roulette, ChoosingCards, UsingCollectible, ShowingResults}

var can_roulette_interact: bool = false

var state: GameState = GameState.Idle:
	set(new_state):
		if state != new_state:
			exit_state(state)
			state = new_state
			enter_state(state)

func enter_state(new_state: GameState) -> void:
	match new_state:
		GameState.Idle:
			player.show_mouse()
			player.capture_mouse()
			SignalBus.hide_showdown_button.emit()
		GameState.GettingCards:
			player.show_mouse()
			player.capture_mouse()
			player.make_current_camera()
			roulette_screen.visible = false
			can_roulette_interact = true
			SignalBus.hide_use_button.emit()
		GameState.Roulette:
			Globals.can_place_bet = true
			player.hide_mouse()
			player.release_mouse()
			can_roulette_interact = false
			roulette_2d.run_roulette()
			roulette_camera.current = true
			roulette_screen.visible = true
			SignalBus.hide_use_button.emit()
		GameState.ChoosingCards:
			player.show_mouse()
			player.capture_mouse()
			player.make_current_camera()
			roulette_screen.visible = false
			can_roulette_interact = false
			SignalBus.show_showdown_button.emit()
			SignalBus.hide_use_button.emit()
		GameState.UsingCollectible:
			player.show_mouse()
			player.capture_mouse()
			player.make_current_camera()
			roulette_screen.visible = false
			can_roulette_interact = false
			SignalBus.hide_showdown_button.emit()
			SignalBus.show_use_button.emit()
		GameState.ShowingResults:
			player.show_mouse()
			player.capture_mouse()
			SignalBus.hide_showdown_button.emit()
			SignalBus.hide_use_button.emit()

func exit_state(old_state: GameState) -> void:
	match old_state:
		GameState.Roulette:
			pass

func tick_state(delta: float) -> void:
	match state:
		GameState.Idle:
			pass
		GameState.Roulette:
			pass
		GameState.GettingCards:
			cards_selection_moderation()
		GameState.ChoosingCards:
			cards_selection_moderation()
		GameState.UsingCollectible:
			use_button_disabling()
		GameState.ShowingResults:
			pass

func _ready() -> void:
	spawn_items_in_shop()
	SignalBus.collectible_selected.connect(collectible_selected)
	SignalBus.make_collectible_useable.connect(make_collectible_useable)
	SignalBus.use_button_clicked.connect(on_use_button_pressed)
	SignalBus.bet_placed.connect(on_bet_placed)
	
	await get_tree().process_frame
	
	var mat = tv_mesh.get_material_override() as StandardMaterial3D
	
	if mat:
		mat.albedo_texture = tv_viewport.get_texture()

var combo

func _process(delta: float) -> void:
	tick_state(delta)
	update_number_of_cards()
	roulette.can_interact = can_roulette_interact
	update_number_of_collectibles()


func compare_cards(c1, c2):
	var cards1 = c1.get_children()
	var cards2 = c2.get_children()
	cards1 = arrange_cards_in_order(cards1)
	cards2 = arrange_cards_in_order(cards2)
	
	if highest_combo(cards1)>highest_combo(cards2):
		combo = highest_combo(cards1)
		return c1
	elif (highest_combo(cards1)<highest_combo(cards2)):
		combo = highest_combo(cards2)
		return c2
	else:
		combo = highest_combo(cards2)
		if (combo == 0):
			if cards1[2].get_value() > cards2[2].get_value():
				
				return c1
			elif cards1[2].get_value() < cards2[2].get_value():
				return c2
			elif cards1[1].get_value() > cards2[1].get_value():
				return c1
			elif cards1[1].get_value() < cards2[1].get_value():
				return c2
			elif cards1[0].get_value() > cards2[0].get_value():
				return c1
			elif cards1[0].get_value() < cards2[0].get_value():
				return c2
			else:
				return 0
		if (combo == 1):
			var cards1_pair: int
			var cards1_remaining
			var cards2_pair: int
			var cards2_remaining
			if (cards1[0].get_value() == cards1[1].get_value()):
				cards1_pair = cards1[0].get_value()
				cards1_remaining = cards1[2].get_value()
			elif (cards1[2].get_value() == cards1[1].get_value()):
				cards1_pair = cards1[1].get_value()
				cards1_remaining = cards1[0].get_value()
			else:
				cards1_pair = cards1[0].get_value()
				cards1_remaining = cards1[1].get_value()
			if (cards2[0].get_value() == cards2[1].get_value()):
				cards2_pair = cards2[0].get_value()
				cards2_remaining = cards2[2].get_value()
			elif (cards2[2].get_value() == cards2[1].get_value()):
				cards2_pair = cards2[1].get_value()
				cards2_remaining = cards2[0].get_value()
			else:
				cards2_pair = cards2[0].get_value()
				cards2_remaining = cards2[1].get_value()
			
			if cards1_pair>cards2_pair:
				return c1
			elif cards2_pair>cards1_pair:
				return c2
			elif cards1_remaining > cards2_remaining:
				return c1
			elif cards1_remaining < cards2_remaining:
				return c2
			else:
				return 0
		if (combo == 2):
			if cards1[2].get_value() > cards2[2].get_value():
				return c1
			elif cards1[2].get_value() < cards2[2].get_value():
				return c2
			elif cards1[1].get_value() > cards2[1].get_value():
				return c1
			elif cards1[1].get_value() < cards2[1].get_value():
				return c2
			elif cards1[0].get_value() > cards2[0].get_value():
				return c1
			elif cards1[0].get_value() < cards2[0].get_value():
				return c2
			else:
				return 0
		if (combo == 3):
			if cards1[2] > cards2[2]:
				return c1
			elif cards1[2] < cards2[2]:
				return c2
			else:
				return 0
		if (combo == 4):
			if cards1[2] > cards2[2]:
				return c1
			elif cards1[2] < cards2[2]:
				return c2
			else:
				return 0
		if (combo == 5):
			if cards1[0].get_value() > cards2[0].get_value():
				return c1
			elif cards1[0].get_value() < cards2[0].get_value():
				return c2
			else:
				return 0

func print_cards(cards):
	for card in cards:
		print(card.suit_name, " ", str(card.value), "  ")

func give_player_random_cards(numer_of_times: float = 3):
	for i in numer_of_times:
		spawn_card(player_cards)

func spawn_card(parent: Node3D):
	var card_instance = card_scene.instantiate()
	parent.add_child(card_instance)
	return card_instance

func highest_combo(cards: Array)-> int:
	if detect_trio(cards):
		return Globals.ComboType.TRIO
	elif detect_pure(cards):
		return Globals.ComboType.PURE_SEQUENCE 
	elif detect_sequence(cards):
		return Globals.ComboType.SEQUENCE
	elif detect_colour(cards):
		return Globals.ComboType.COLOUR
	elif detect_pair(cards):
		return Globals.ComboType.PAIR
	else:
		return Globals.ComboType.HIGH_CARD

func detect_trio(cards: Array) -> bool:
	return (cards[0].value == cards[1].value) and (cards[1].value == cards[2].value)

func detect_pure(cards: Array)->bool:
	if (cards[0].get_suit() != cards[1].get_suit()) or (cards[1].get_suit() != cards[2].get_suit()):
		return false
	
	if (cards[1].get_value() == cards[0].get_value() + 1) and (cards[1].get_value() == cards[2].get_value() - 1):
		return true
	
	return false

func detect_sequence(cards: Array)->bool:
	if (cards[1].get_value() == cards[0].get_value() + 1) and (cards[1].get_value() == cards[2].get_value() - 1):
		return true
	
	return false

func detect_colour(cards: Array)->bool:
	if (cards[0].get_suit() == cards[1].get_suit()) and (cards[1].get_suit() == cards[2].get_suit()) and (cards[0].get_suit() == cards[2].get_suit()):
		return true
	return false

func detect_pair(cards: Array)->bool:
	if (cards[0].value == cards[1].value) or (cards[1].value == cards[2].value) or (cards[2].value == cards[0].value):
		return true
	return false

func arrange_cards_in_order(cards: Array) -> Array:
	var sorted_cards = cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.value < b.value)
	return sorted_cards

func _on_timer_timeout() -> void:
	pass
	#print_cards(player_cards.get_children())
	#print(Globals.ComboType.find_key(combo))

func update_number_of_cards():
	var number = 0
	
	for m in player_card_markers.get_children():
		if m.get_meta("Occupied"):
			number += 1
	number_of_cards = number
	
	var num2 = 0
	
	for m in player_cards.get_children():
		if m.selected:
			num2 += 1
	
	number_of_cards_selected = num2

func _on_start_button_interacted() -> void:
	start_cutscene()
	roulette.can_interact = true
	#spawn_initial_player_cards()

func start_cutscene() -> void:
	can_roulette_interact = true
	start_button.visible = false
	create_tween().tween_property(player, "global_transform", player_marker.global_transform, 1)
	player.can_move = false
	player.can_jump = false
	state = GameState.GettingCards

func change_card_to_unique(card, cards_parent):

	card.change_card_to_random()
	for c in cards_parent.get_children():
		if (card.value == c.value and card.suit == c.suit and c!=card):
			change_card_to_unique(card, cards_parent)


#func spawn_initial_player_cards()->void:
	#var card1 = spawn_card(player_cards)
	#create_tween().tween_property(card1, "global_transform", player_card_marker_1.global_transform, 1)
	#var card2 = spawn_card(player_cards)
	#create_tween().tween_property(card2, "global_transform", player_card_marker_2.global_transform, 2)
	#change_card_to_unique(card2, player_cards)

func _on_roulette_2d_send_card(number: int, suit: int, multiplier) -> void:
	var card1 = spawn_card(player_cards)
	card1.value = number as Globals.CardValue
	card1.suit = Globals.CardSuit.values()[suit]
	card1.multiplier = multiplier
	var marker
	for m in player_card_markers.get_children():
		if !m.get_meta("Occupied"):
			marker = m
			break
	marker.set_meta("Occupied", true)
	create_tween().tween_property(card1, "global_transform", marker.global_transform, 1)
	
	await get_tree().create_timer(1.0).timeout
	
	
	if number_of_cards<5:
		state = GameState.GettingCards
	elif number_of_cards==5:
		state = GameState.ChoosingCards

func _on_roulette_interacted() -> void:
	state = GameState.Roulette

func player_got_all_cards()-> bool:
	var marker = null
	for m in player_card_markers.get_children():
		if !m.get_meta("Occupied"):
			marker = m
	if !marker:
		return true
	else:
		return false

func cards_selection_moderation():
	var number_of_cards_selected: int = 0
	for card in player_cards.get_children():
		if card.selected:
			number_of_cards_selected += 1
	if number_of_cards_selected==3:
		SignalBus.enable_showdown_button.emit()
		for card in player_cards.get_children():
			if !card.selected:
				card.can_be_selected = false
	else:
		SignalBus.disable_showdown_button.emit()
		for card in player_cards.get_children():
			card.can_be_selected = true

func on_bet_placed(bet_type, bet_number):
	#print(bet_type, bet_number)
	pass

func on_use_button_pressed():
	var selected_cards: Array = []
	for card in player_cards.get_children():
		if card.selected:
			selected_cards.append(card)
	
	var selected_collectible = null
	for c in player_collectibles.get_children():
		if c.selected:
			selected_collectible = c
			break
	
	use_collectible(selected_collectible, selected_cards)
	
	
func use_button_disabling():
	if not selected_collectible:
		SignalBus.disable_use_button.emit()
		return
	
	var selected_cards: Array = []
	for card in player_cards.get_children():
		if card.selected:
			selected_cards.append(card)
	
	var required_cards = get_required_cards_for_collectible(selected_collectible.collectible_type)
	
	if required_cards == 0:
		SignalBus.enable_use_button.emit()
		return
	
	if selected_cards.size() == required_cards:
		SignalBus.enable_use_button.emit()
	else:
		SignalBus.disable_use_button.emit()

func get_required_cards_for_collectible(collectible_type: Globals.CollectibleType) -> int:
	match collectible_type:
		Globals.CollectibleType.Alchemist:
			return 1
		Globals.CollectibleType.Ascend:
			return 1
		Globals.CollectibleType.Catalyst:
			return 0
		Globals.CollectibleType.ChameleonBlue:
			return 1
		Globals.CollectibleType.ChameleonPink:
			return 1
		Globals.CollectibleType.ChameleonYellow:
			return 1
		Globals.CollectibleType.Descend:
			return 1
		Globals.CollectibleType.Mimic:
			return 1
		Globals.CollectibleType.SixSeven:
			return 0
		_:
			return 1

func on_showdown_button_pressed():
	state = GameState.ShowingResults

func spawn_items_in_shop():
	var random_collectibles: Array = Globals.CollectibleType.values()
	random_collectibles.shuffle()
	random_collectibles = random_collectibles.slice(0, 4)
	
	for c in random_collectibles:
		var item_instance = collectible_scene.instantiate()
		var spawn_marker
		for m in shop_markers.get_children():
			if !m.get_meta("Occupied"):
				spawn_marker = m
				break
		spawn_marker.set_meta("Occupied", true)
		item_instance.global_transform = spawn_marker.global_transform
		shop.add_child(item_instance)
		item_instance.collectible_type = c

func update_number_of_collectibles():
	var number = 0
	for m in collectible_markers.get_children():
		if m.get_meta("Occupied"):
			number += 1
	PlayerData.number_of_collectibles = number

func make_collectible_useable(collectible):
	if PlayerData.number_of_collectibles >=3:
		return
	var marker
	for m in collectible_markers.get_children():
		if !m.get_meta("Occupied"):
			marker = m
			break
	marker.set_meta("Occupied", true)
	turn_marker_off(collectible, shop_markers)
	collectible.reparent(player_collectibles, true)
	create_tween().tween_property(collectible, "global_transform", marker.global_transform, 0.5)
	await get_tree().create_timer(0.5).timeout

func turn_marker_off(card, marker_set):
	for m in marker_set.get_children():
		if card.global_transform == m.global_transform:
			m.set_meta("Occupied", false)

#func collectible_selected(clicked_collectible):
	#if selected_collectible != null and selected_collectible != clicked_collectible:
		#selected_collectible.selected = false
		#selected_collectible.can_be_selected = true
	#
	#if selected_collectible == clicked_collectible:
		#clicked_collectible.selected = false
		#selected_collectible = null
		#state = GameState.GettingCards
	#else:
		#clicked_collectible.selected = true
		#selected_collectible = clicked_collectible
		#for c in player_collectibles.get_children():
			#if c != clicked_collectible:
				#c.can_be_selected = false
		#state = GameState.UsingCollectible
	#if selected_collectible == null:
		#for c in player_collectibles.get_children():
			#c.can_be_selected = true
		#if number_of_cards < 5:
			#state = GameState.GettingCards
		#elif number_of_cards == 5:
			#state = GameState.ChoosingCards

func collectible_selected(clicked_collectible):
	if selected_collectible != null and selected_collectible != clicked_collectible:
		selected_collectible.selected = false
		selected_collectible.can_be_selected = true
	
	if selected_collectible == clicked_collectible:
		# Deselect the current one
		clicked_collectible.selected = false
		selected_collectible = null
		# Return to appropriate state
		if number_of_cards < 5:
			state = GameState.GettingCards
		elif number_of_cards == 5:
			state = GameState.ChoosingCards
		# Re-enable all collectibles
		for c in player_collectibles.get_children():
			c.can_be_selected = true
	else:
		# Select the new one
		clicked_collectible.selected = true
		selected_collectible = clicked_collectible
		# Disable other collectibles
		for c in player_collectibles.get_children():
			if c != clicked_collectible:
				c.can_be_selected = false
		# Set state to UsingCollectible
		state = GameState.UsingCollectible


func use_collectible(collectible: Node3D, selected_cards: Array) -> void:
	match collectible.collectible_type:
		Globals.CollectibleType.Alchemist:
			for c in selected_cards:
				c.change_card_to_random()
		Globals.CollectibleType.Ascend:
			for c in selected_cards:
				if c.value!=8:
					c.value += 1
				else:
					c.value = 1
		Globals.CollectibleType.Catalyst:
			for c in selected_cards:
				c.multiplier *= 10
		Globals.CollectibleType.ChameleonBlue:
			for c in selected_cards:
				c.suit = Globals.CardSuit.BLUE
		Globals.CollectibleType.ChameleonPink:
			for c in selected_cards:
				c.suit = Globals.CardSuit.MAGENTA
		Globals.CollectibleType.ChameleonYellow:
			for c in selected_cards:
				c.suit = Globals.CardSuit.YELLOW
		Globals.CollectibleType.Descend:
			for c in selected_cards:
				if c.value!=1:
					c.value -= 1
				else:
					c.value = 8
		Globals.CollectibleType.Mimic:
			pass
		Globals.CollectibleType.SixSeven:
			var random_cards: Array = player_cards.get_children()
			random_cards.shuffle()
			random_cards[0].value = 6
			random_cards[1].value = 7
	
	collectible.selected = false
	
	player_collectibles.remove_child(collectible)
	turn_marker_off(collectible, collectible_markers)
	collectible.queue_free()
	selected_collectible = null
	
	if number_of_cards < 5:
		state = GameState.GettingCards
	elif number_of_cards == 5:
		state = GameState.ChoosingCards
	
	for card in player_cards.get_children():
		card.selected = false
		card.can_be_selected = true
		
	for c in player_collectibles.get_children():
		c.selected = false
		c.can_be_selected = true
		
	print("Collectible used and state reset")
