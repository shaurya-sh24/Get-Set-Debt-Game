extends Node2D

@onready var roulette: StaticBody2D = $Roulette
@onready var ball_1: RigidBody2D = $Ball1
@onready var ball_2: RigidBody2D = $Ball2
@onready var bets: Node2D = $Bets

var number_chosen: int
var suit_chosen

signal send_card(number: int, suit: int, multiplier: int)

func _process(delta: float) -> void:
	number_chosen = roulette.number_chosen
	suit_chosen = roulette.suit_chosen

func run_roulette():
	roulette.run_roulette()

func _on_roulette_ended(multiplier) -> void:
	for bet in bets.get_children():
		bet.queue_free()
	roulette.bets_placed = 0
	roulette.current_multiplier = 1
	ball_1.visible = false
	ball_2.visible = false
	send_card.emit(number_chosen, suit_chosen, multiplier)
