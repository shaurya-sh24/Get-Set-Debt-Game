extends StaticBody2D

@onready var roulette_center_node: Node2D = $"../Marker2D"
@onready var mouse_ray: RayCast2D = $"../RayCast2D"

var bet_scene:PackedScene = preload("uid://dy4121sm8twy6")

var bets_placed = 0

var spin_speed1: float = 5000.0
var centripetal_force1: float = 200.0 
var multiplicative_decay1: float = 0.985

var spin_speed2: float = 2500.0
var centripetal_force2: float = 150.0 
var multiplicative_decay2: float = 0.985

var number_chosen: int
var suit_chosen

var current_multiplier = 1

signal roulette_ended(multiplier)

@onready var number_pocket_markers: Node2D = $"../NumberPocketMarkers"
@onready var colour_pocket_markers: Node2D = $"../ColourPocketMarkers"

@onready var ball1: RigidBody2D = $"../Ball1"
@onready var ball2: RigidBody2D = $"../Ball2"
@onready var bets: Node2D = $"../Bets"

var is_spinning1: bool = false
var is_spinning2: bool = false

var audio_playing = false

func _ready() -> void:
	pass
	#var starting_marker = number_pocket_markers.get_child(randi_range(0,15))
	#ball1.global_position = starting_marker.global_position
	#
	#var starting_marker2 = colour_pocket_markers.get_child(randi_range(0,8))
	#ball2.global_position = starting_marker2.global_position
	#
	#spin_speed1 = randi_range(4500,5500)
	#spin_speed2 = randi_range(4500,5500)

func _physics_process(delta: float) -> void:
	if bets_placed ==5:
		Globals.can_place_bet = false
		ball1.visible = true
		ball2.visible = true
		ball1_physics()
		ball2_physics()

func run_roulette():
	ball1.freeze = false
	ball2.freeze = false
	centripetal_force1 = 200.0
	centripetal_force2 = 150.0 
	is_spinning1 = true
	is_spinning2 = true
	
	var starting_marker = number_pocket_markers.get_child(randi_range(0,15))
	ball1.global_position = starting_marker.global_position
	
	var starting_marker2 = colour_pocket_markers.get_child(randi_range(0,8))
	ball2.global_position = starting_marker2.global_position
	
	spin_speed1 = randi_range(4500,5500)
	spin_speed2 = randi_range(4500,5500)

func ball1_physics():
	if (not roulette_center_node or not is_spinning1):
		return
	
	spin_speed1 *= multiplicative_decay1
	centripetal_force1 *= 1.015
	clamp(centripetal_force1, 200, 500)
	
	if spin_speed1 <= 20.0:
		is_spinning1 = false
		AudioManager.stop_music("roulette")
		snap_to_closest_pocket1()
		return
	
	
	if !AudioManager.active_music.has("roulette"):
		AudioManager.play_music("roulette")
	
	var center_pos = roulette_center_node.global_position
	
	var to_ball = ball1.global_position - center_pos
	
	var radial_dir = to_ball.normalized()
	var tangential_dir = radial_dir.orthogonal()
	
	var inward_push = -radial_dir * centripetal_force1
	var forward_push = tangential_dir * spin_speed1
	
	ball1.apply_central_force(inward_push + forward_push)

func ball2_physics():
	if (not roulette_center_node or not is_spinning2):
		return
	
	spin_speed2 *= multiplicative_decay2
	centripetal_force2 *= 1.015
	clamp(centripetal_force2, 200, 500)
	
	if spin_speed2 <= 20.0:
		is_spinning2 = false
		snap_to_closest_pocket2()
		return

	var center_pos = roulette_center_node.global_position
	
	var to_ball = ball2.global_position - center_pos
	
	var radial_dir = to_ball.normalized()
	var tangential_dir = radial_dir.orthogonal()
	
	var inward_push = -radial_dir * centripetal_force2
	var forward_push = tangential_dir * spin_speed2
	
	ball2.apply_central_force(inward_push + forward_push)

func snap_to_closest_pocket1() -> void:
	AudioManager.stop_music("roulette")
	
	ball1.freeze = true
	
	var closest_pocket = null
	var shortest_distance: float = INF
	
	for pocket in number_pocket_markers.get_children():
		var dist = ball1.global_position.distance_to(pocket.global_position)
		if dist < shortest_distance:
			shortest_distance = dist
			closest_pocket = pocket

	if closest_pocket:
		var tween = create_tween()
		tween.tween_property(ball1, "global_position", closest_pocket.global_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		number_chosen = closest_pocket.get_meta("Value")
		
		for bet in bets.get_children():
			if bet.global_position == closest_pocket.global_position:
				current_multiplier *= number_chosen
				bet.change_colour()
				PlayerData.number_of_bets_landed += 1
		
		$"../Timer".start()

func snap_to_closest_pocket2() -> void:
	
	ball2.freeze = true
	
	var closest_pocket = null
	var shortest_distance: float = INF
	
	for pocket in colour_pocket_markers.get_children():
		var dist = ball2.global_position.distance_to(pocket.global_position)
		if dist < shortest_distance:
			shortest_distance = dist
			closest_pocket = pocket

	if closest_pocket:
		var tween = create_tween()
		tween.tween_property(ball2, "global_position", closest_pocket.global_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var n = (int(str(closest_pocket.name)[-1])%3)
		if n==1:
			suit_chosen = Globals.CardSuit.YELLOW
		elif n==2:
			suit_chosen = Globals.CardSuit.BLUE
		else:
			suit_chosen = Globals.CardSuit.MAGENTA
		for bet in bets.get_children():
			if bet.global_position == closest_pocket.global_position:
				bet.change_colour()
				PlayerData.number_of_bets_landed += 1
				current_multiplier *= 2

func _on_timer_timeout() -> void:
	roulette_ended.emit(current_multiplier)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Globals.can_place_bet:
		mouse_ray.global_position = get_global_mouse_position()
		mouse_ray.target_position = Vector2(0,1)
		var mouse_position = get_global_mouse_position()
		if !mouse_ray.is_colliding():
				var closest_pocket = null
				var shortest_distance: float = INF
				for pocket in number_pocket_markers.get_children():
					var dist = mouse_position.distance_to(pocket.global_position)
					if dist < shortest_distance:
						shortest_distance = dist
						closest_pocket = pocket
				for pocket in colour_pocket_markers.get_children():
					var dist = mouse_position.distance_to(pocket.global_position)
					if dist < shortest_distance:
						shortest_distance = dist
						closest_pocket = pocket
				
				for bet in bets.get_children():
					if bet.global_position == closest_pocket.global_position:
						return
				
				var bet_instance = bet_scene.instantiate()
				bets.add_child(bet_instance)
				bet_instance.global_position = closest_pocket.global_position
				
				AudioManager.play_sfx("bet", -5)
				
				if closest_pocket.get_parent() == number_pocket_markers:
					SignalBus.emit_signal("bet_placed","number", closest_pocket.get_meta("Value") as Globals.CardValue)
					bets_placed +=1
				elif closest_pocket.get_parent() == colour_pocket_markers:
					var n = (int(str(closest_pocket.name)[-1])%3)
					var pocket_suit
					if n==1:
						pocket_suit = Globals.CardSuit.YELLOW
					elif n==2:
						pocket_suit = Globals.CardSuit.BLUE
					else:
						pocket_suit = Globals.CardSuit.MAGENTA
					SignalBus.emit_signal("bet_placed","suit", pocket_suit)
					bets_placed +=1
