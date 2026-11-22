extends Node3D

var card_scene:PackedScene = preload("uid://du41vttg8asnd")
var collectible_scene = preload("uid://cxuhlqp3vjanx")

@onready var rowlette_frog: MeshInstance3D = $"Environment/CasinoRoom/Meshes/Node3D/Rowlette frog"
@onready var frog_hat: MeshInstance3D = $"Environment/CasinoRoom/Meshes/Node3D/frog hat"

@onready var player_cards: Node3D = $PlayerData/PlayerCards
@onready var player_card_markers: Node3D = $Environment/Markers/PlayerCardMarkers
@onready var player_collectibles: Node3D = $PlayerData/PlayerCollectibles
var selected_collectible: Node3D = null
var TV_MATERIAL = preload("uid://fn6guhymx2s4")

@onready var bg_audio_timer: Timer = $BgAudioTimer


const dialogue_sounds = "res://Assets/Audio/dialogues/frog"


@onready var start_button: Interactable = $Environment/StartButton
@onready var player: CharacterBody3D = $Player
@onready var markers: Node3D = $Environment/Markers
@onready var player_marker: Marker3D = $Environment/Markers/PlayerMarker
@onready var shop_markers: Node3D = $Environment/Markers/ShopMarkers
@onready var collectible_markers: Node3D = $Environment/Markers/CollectibleMarkers
@onready var shop: Node3D = $Environment/Shop

@onready var cutscene_camera: Camera3D = $Cutscene/CutsceneCamera
@onready var cutscene: Node3D = $Cutscene
@onready var frog_camera: Marker3D = $Cutscene/FrogCamera
@onready var bets_camera: Marker3D = $Cutscene/BetsCamera
@onready var shop_camera: Marker3D = $Cutscene/ShopCamera
@onready var roulette_camera_2: Marker3D = $Cutscene/RouletteCamera2
@onready var tv_camera: Marker3D = $Cutscene/TVCamera
@onready var dialogue_label: Label = $Cutscene/CutsceneCamera/CanvasLayer/Control/ColorRect/DialogueLabel
@onready var cutscene_control: Control = $Cutscene/CutsceneCamera/CanvasLayer/Control
@onready var skip_button: Button = $Cutscene/CutsceneCamera/CanvasLayer/Control/SkipButton

@onready var lights: Node3D = $Environment/Lights


@onready var roulette: StaticBody3D = $Environment/Roulette
@onready var roulette_screen: Node3D = $RouletteScreen
@onready var roulette_2d: Node2D = $RouletteScreen/SubViewport/Roulette2D
@onready var roulette_camera: Camera3D = $RouletteCamera
@onready var tv_viewport: SubViewport = $TV/SubViewport
@onready var tv_mesh: MeshInstance3D = $TV/MeshInstance3D



var number_of_cards = 0
var number_of_cards_selected = 0

enum GameState {Idle, RoundStart, GettingCards, Roulette, ChoosingCards, UsingCollectible, ShowingResults, Cutscene, End}

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
			AudioManager.play_music("casino_theme", -15)
			clean_up_board()
			for c in player_cards.get_children():
				c.queue_free()
			make_shop_visible(true)
			player.show_mouse()
			player.capture_mouse()
			freeze_player(false)
			make_start_button_visible(true)
			if PlayerData.round != 1:
				spawn_items_in_shop()
			SignalBus.hide_showdown_button.emit()
		GameState.GettingCards:
			make_shop_visible(false)
			make_start_button_visible(false)
			player.show_mouse()
			player.capture_mouse()
			player.make_current_camera()
			roulette_screen.visible = false
			can_roulette_interact = true
			SignalBus.hide_use_button.emit()
		GameState.Roulette:
			make_shop_visible(false)
			make_start_button_visible(false)
			Globals.can_place_bet = true
			player.hide_mouse()
			player.release_mouse()
			can_roulette_interact = false
			roulette_2d.run_roulette()
			roulette_camera.current = true
			roulette_screen.visible = true
			SignalBus.hide_use_button.emit()
		GameState.ChoosingCards:
			make_shop_visible(false)
			make_start_button_visible(false)
			player.show_mouse()
			player.capture_mouse()
			player.make_current_camera()
			roulette_screen.visible = false
			can_roulette_interact = false
			SignalBus.show_showdown_button.emit()
			SignalBus.hide_use_button.emit()
		GameState.UsingCollectible:
			make_shop_visible(false)
			make_start_button_visible(false)
			player.show_mouse()
			player.capture_mouse()
			player.make_current_camera()
			roulette_screen.visible = false
			can_roulette_interact = false
			SignalBus.hide_showdown_button.emit()
			SignalBus.show_use_button.emit()
		GameState.RoundStart:
			AudioManager.play_music("casino_theme", -15)
			AudioManager.stop_music("frog_theme")
			player.interactions_enabled(true)
			cutscene_control.visible = false
			player.make_current_camera()
			for c in player_collectibles.get_children():
				c.can_be_selected = true
			freeze_player(true)
			player.global_position = player_marker.global_position
			make_shop_visible(false)
			make_start_button_visible(false)
			player.show_mouse()
			player.capture_mouse()
			SignalBus.hide_showdown_button.emit()
			SignalBus.hide_use_button.emit()
			
			PlayerData.take_money_from_player(PlayerData.round_fee)
			state = GameState.GettingCards
		GameState.ShowingResults:
			make_shop_visible(false)
			make_start_button_visible(false)
			player.hide_mouse()
			player.release_mouse()
			SignalBus.hide_showdown_button.emit()
			SignalBus.hide_use_button.emit()
			
			var round_stats = round_stats()
			
			PlayerData.total_score += round_stats
			
			player.show_combo_label(Globals.combo_data.get(combo)[1])
			
			await get_tree().create_timer(3.0).timeout
			
			if (round_stats) >= PlayerData.quota:
				AudioManager.play_sfx("round_end",-5)
				PlayerData.round += 1
				PlayerData.give_player_round_money(round_stats)
				PlayerData.calculate_round_stats()
				SignalBus.show_round_stats_panel.emit(round_stats, PlayerData.previous_quota, PlayerData.interest_earned, PlayerData.quota)
			else:
				state = GameState.End
		GameState.Cutscene:
			AudioManager.play_music("frog_theme",-5)
			player.hide_mouse()
			player.release_mouse()
		GameState.End:
			player.release_mouse()
			name_of_frog = "Rowlette: "
			player.hide_mouse()
			player.release_mouse()
			freeze_player(true)
			skip_button.visible = false
			for l in lights.get_children():
				l.light_color = Color(1.249, 0.0, 0.342)
			dialogue_label.text = ""
			player.interactions_enabled(false)
			cutscene_control.visible = true
			cutscene_camera.global_transform = tv_camera.global_transform
			cutscene_camera.current = true
			create_tween().tween_property(cutscene_camera, "global_transform", frog_camera.global_transform, 1)
			await get_tree().create_timer(1).timeout
			shake_pos(0.02, 100)
			give_dialogue("I told you I am very serious!")
			await get_tree().create_timer(3).timeout
			give_dialogue("Since you can’t pay us back,")
			await get_tree().create_timer(3).timeout
			give_dialogue("We will earn back whatever we can...")
			await get_tree().create_timer(3).timeout
			give_dialogue("We will earn back whatever we can...\n TEEHEE :3", 3)
			await get_tree().create_timer(4).timeout
			
			AudioManager.play_sfx("gun", 5)
			SceneManager.load_game_over_screen()
			

var is_shaking:= false

func shake_pos(intensity: float = 0.02, duration: float = 0.25):
	if is_shaking: return
	if not is_inside_tree(): return
	is_shaking = true
	
	var time_left = duration
	var start_position = cutscene_camera.position
	
	while time_left>0:
		var offset = Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), 0)
		
		cutscene_camera.position = start_position + offset
		time_left -= get_process_delta_time()
		
		await get_tree().process_frame
		
		if not is_inside_tree():
			is_shaking = false
			return
		
	cutscene_camera.position = start_position
	is_shaking = false


func exit_state(old_state: GameState) -> void:
	match old_state:
		GameState.Roulette:
			pass

func tick_state(delta: float) -> void:
	match state:
		GameState.Idle:
			for c in player_collectibles.get_children():
				c.can_be_selected = false
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


func clean_up_board() -> void:
	for card in player_cards.get_children():
		card.queue_free()
	for m in player_card_markers.get_children():
		m.set_meta("Occupied", false)
	number_of_cards = 0
	
	for item in shop.get_children():
		item.queue_free()
	for m in shop_markers.get_children():
		m.set_meta("Occupied", false)
	start_button.visible = true

func _ready() -> void:
	AudioManager.play_music("fuzzy_static", -4.0)
	
	bg_audio_timer.wait_time = randf_range(60.0, 300.0)
	
	SignalBus.collectible_selected.connect(collectible_selected)
	SignalBus.make_collectible_useable.connect(make_collectible_useable)
	SignalBus.use_button_clicked.connect(on_use_button_pressed)
	SignalBus.bet_placed.connect(on_bet_placed)
	SignalBus.showdown_button_clicked.connect(on_showdown_button_pressed)
	SignalBus.next_round_button_pressed.connect(next_round_button_pressed)
	
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

func highest_combo(cards: Array) -> int:
	if cards.size() != 3:
		return Globals.ComboType.BASE

	var sorted_cards = cards.duplicate()
	sorted_cards.sort_custom(func(a, b): return a.value < b.value)

	if detect_trio(sorted_cards):
		PlayerData.number_of_trio += 1
		return Globals.ComboType.TRIO
	elif detect_pure(sorted_cards):
		PlayerData.number_of_straight_flush += 1
		return Globals.ComboType.PURE_SEQUENCE 
	elif detect_sequence(sorted_cards):
		PlayerData.number_of_straight += 1
		return Globals.ComboType.SEQUENCE
	elif detect_colour(sorted_cards):
		PlayerData.number_of_flush += 1
		return Globals.ComboType.COLOUR
	elif detect_pair(sorted_cards):
		PlayerData.number_of_pair += 1
		return Globals.ComboType.PAIR
	else:
		PlayerData.number_of_bases += 1
		return Globals.ComboType.BASE

func detect_trio(cards: Array) -> bool:
	return (cards[0].value == cards[1].value) and (cards[1].value == cards[2].value)

func detect_pure(cards: Array) -> bool:
	if (cards[0].suit != cards[1].suit) or (cards[1].suit != cards[2].suit):
		return false
	
	return (cards[1].value == cards[0].value + 1) and (cards[2].value == cards[1].value + 1)

func detect_sequence(cards: Array) -> bool:
	return (cards[1].value == cards[0].value + 1) and (cards[2].value == cards[1].value + 1)

func detect_colour(cards: Array) -> bool:
	return (cards[0].suit == cards[1].suit) and (cards[1].suit == cards[2].suit)

func detect_pair(cards: Array) -> bool:
	return (cards[0].value == cards[1].value) or (cards[1].value == cards[2].value) or (cards[2].value == cards[0].value)

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
	if PlayerData.round == 1:
		state = GameState.Cutscene
		start_initial_cutscene()
	else:
		if PlayerData.money >= PlayerData.round_fee:
			start_cutscene()
		else:
			SignalBus.give_help.emit("YOU DON'T HAVE ENOUGH CHIPS FOR ROUND FEES.")
			await get_tree().create_timer(2.0).timeout
			state = GameState.End
	roulette.can_interact = true
	#spawn_initial_player_cards()

func start_cutscene() -> void:
	can_roulette_interact = true
	start_button.visible = false
	create_tween().tween_property(player, "global_transform", player_marker.global_transform, 1)
	player.can_move = false
	player.can_jump = false
	state = GameState.RoundStart

func change_card_to_unique(card, cards_parent):
	card.change_card_to_random()
	for c in cards_parent.get_children():
		if (card.value == c.value and card.suit == c.suit and c!=card):
			change_card_to_unique(card, cards_parent)


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
	AudioManager.play_sfx("card_swoop", -10)
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
	AudioManager.play_sfx("ui", -15)
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
			return 3
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
		if spawn_marker == null:
			push_error("No free marker for collectible spawn!")
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

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F) and state == GameState.Cutscene:
		skip_button.pressed.emit()

func make_collectible_useable(collectible):
	if PlayerData.number_of_collectibles>=3:
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
		if card.global_position.distance_to(m.global_position) < 0.1:
			m.set_meta("Occupied", false)
			break

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

func make_shop_visible(state: bool):
	for s in shop.get_children():
		s.visible = state

func make_start_button_visible(state: bool):
	frog_hat.visible = state
	rowlette_frog.visible = state
	start_button.visible = state
	start_button.interactable = state

func round_stats()->int:
	var selected_cards: Array = []
	for card in player_cards.get_children():
		if card.selected:
			selected_cards.append(card)
	
	combo = highest_combo(selected_cards)
	
	var combo_score = Globals.combo_data.get(combo)[0]
	var number_score = 0
	
	for c in selected_cards:
		number_score += c.value * c.multiplier
	
	return combo_score * number_score
	
func use_collectible(collectible: Node3D, selected_cards: Array) -> void:
	PlayerData.number_of_collectibles_used += 1
	match collectible.collectible_type:
		Globals.CollectibleType.Alchemist:
			for c in selected_cards:
				c.suit = Globals.CardSuit.values().pick_random()
		Globals.CollectibleType.Ascend:
			for c in selected_cards:
				if c.value != 8:
					c.value += 1
				else:
					c.value = 1
		Globals.CollectibleType.Catalyst:
			for c in selected_cards:
				c.multiplier += 10
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
				if c.value != 1:
					c.value -= 1
				else:
					c.value = 8
		Globals.CollectibleType.Mimic:
			var highest_value = 0
			for c in player_cards.get_children():
				highest_value = max(c.value, highest_value)
			selected_cards[0].value = highest_value
		Globals.CollectibleType.SixSeven:
			var random_cards: Array = player_cards.get_children()
			if random_cards.size() >= 2:
				random_cards.shuffle()
				random_cards[0].value = 6
				random_cards[0].multiplier = 7
				random_cards[1].value = 7
				random_cards[1].multiplier = 6

	collectible.selected = false
	
	turn_marker_off(collectible, collectible_markers)
	
	player_collectibles.remove_child(collectible)
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

func freeze_player(state):
	if state == true:
		player.can_move = false
		player.can_jump = false
	else:
		player.can_move = true
		player.can_jump = false

func next_round_button_pressed():
	if state == GameState.ShowingResults:
		state = GameState.Idle

var name_of_frog:String = "Unknown: "

func give_dialogue(dialogue: String, time: float = 1):
	if state == GameState.Cutscene or state==GameState.End:
		AudioManager.play_dialogue("frog"+str(randi_range(1,10)),-2)
		create_tween().tween_property(dialogue_label, "text", name_of_frog + "\n"+dialogue, time)

func start_initial_cutscene():
	start_button.interactable = false
	dialogue_label.text = ""
	player.interactions_enabled(false)
	cutscene_control.visible = true
	cutscene_camera.global_transform = player.global_transform
	cutscene_camera.current = true
	create_tween().tween_property(cutscene_camera, "global_transform", frog_camera.global_transform, 1)
	await get_tree().create_timer(1).timeout
	give_dialogue("VOILA! A new one has arrived!!!")
	await get_tree().create_timer(4).timeout
	give_dialogue("This place wont feel so empty anymore.",0.5)
	await get_tree().create_timer(1.5).timeout
	give_dialogue("This place wont feel so empty anymore..",0.5)
	await get_tree().create_timer(1.5).timeout
	give_dialogue("This place wont feel so empty anymore...",0.5)
	await get_tree().create_timer(1.5).timeout
	give_dialogue("This place wont feel so empty anymore...\n     ...well, as long as you are alive.",3)
	await get_tree().create_timer(4).timeout
	give_dialogue("ANYWAYS, My name is ROWLETTE.")
	await get_tree().create_timer(4).timeout
	name_of_frog = "Rowlette: "
	give_dialogue("I am the ringleader of this casino.")
	await get_tree().create_timer(4).timeout
	give_dialogue("Let me explain the rules quickly,\nso you can repay your debt and earn your freedom!")
	await get_tree().create_timer(4).timeout
	
	create_tween().tween_property(cutscene_camera, "global_transform", roulette_camera_2.global_transform, 2)
	
	give_dialogue("The roulette wheel is your best friend...")
	await get_tree().create_timer(6).timeout
	give_dialogue("and your worst enemy.")
	await get_tree().create_timer(4).timeout
	give_dialogue("Collect cards by spinning the wheel, ")
	await get_tree().create_timer(3).timeout
	give_dialogue("the outer wheel decides the value, and the inner wheel decides the colour\nof the card.")
	await get_tree().create_timer(5).timeout
	give_dialogue("Collect 5 cards and make poker-like combinations of 3 to score.")
	await get_tree().create_timer(5).timeout
	
	create_tween().tween_property(cutscene_camera, "global_transform", bets_camera.global_transform, 1)
	
	give_dialogue("You can place 5 bets on the numbers and colours overall")
	await get_tree().create_timer(5.5).timeout
	give_dialogue("scoring a place with a bet on it increases your score multiplier.")
	await get_tree().create_timer(5.5).timeout
	give_dialogue("for colours, it gives a x2 mult,\n   for numbers it gives a mult equal to the number.")
	await get_tree().create_timer(7).timeout
	give_dialogue("You must place your bets before you start spinning the roulette wheel")
	await get_tree().create_timer(5.5).timeout
	
	create_tween().tween_property(cutscene_camera, "global_transform", tv_camera.global_transform, 2)
	
	give_dialogue("Score and fulfill your quota every round")
	await get_tree().create_timer(5).timeout
	give_dialogue("Score and fulfill your quota every round\n           OR FACE THE CONSEQUENCES.")
	await get_tree().create_timer(5).timeout
	give_dialogue("Earn interest income on your score as CHIPS.")
	await get_tree().create_timer(5).timeout
	give_dialogue("Also don't forget, each round costs some chips.")
	await get_tree().create_timer(5).timeout
	
	create_tween().tween_property(cutscene_camera, "global_transform", shop_camera.global_transform, 1.5)
	
	give_dialogue("Spend your chips at the shops for collectibles.")
	await get_tree().create_timer(5).timeout
	
	create_tween().tween_property(cutscene_camera, "global_transform", frog_camera.global_transform, 1.5)
	give_dialogue("Good luck amigo.")
	await get_tree().create_timer(2).timeout
	give_dialogue("If you need anything, dont reach out to me!")
	await get_tree().create_timer(2).timeout
	give_dialogue("I am very serious...")
	await get_tree().create_timer(2).timeout
	give_dialogue("I am very serious...\n        TEEHEE :3")
	await get_tree().create_timer(2).timeout
	
	state = GameState.RoundStart
	start_button.interactable = true
	


func _on_skip_button_pressed() -> void:
	AudioManager.play_sfx("ui", -15)
	state = GameState.RoundStart


func _on_bg_audio_timer_timeout() -> void:
	AudioManager.play_music("bg2", -10)
