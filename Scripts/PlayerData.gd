extends Node

const Initial_Quota = 200
const Initial_Interest = 5
const Interest_Increase_Rate = 2
const Initial_Chips = 10
const Final_Interest = 20
const Initial_Round_Fee = 5

var round_fee: int = Initial_Round_Fee
var quota: int = Initial_Quota:
	set(new_quota):
		if new_quota != Initial_Quota:
			previous_quota = quota
		quota = new_quota

var interest: int = Initial_Interest

var round: int
var money: int
var number_of_collectibles: int

#GameOverData
var number_of_bases
var number_of_pair
var number_of_flush
var number_of_straight
var number_of_straight_flush
var number_of_trio
var number_of_bets_landed
var total_score
var number_of_collectibles_used

var previous_quota
var interest_earned

func _ready() -> void:
	calculate_round_stats()

func calculate_round_stats() -> void:
	round_fee = Initial_Round_Fee + (round-1)*2
	quota = 75 * round * (round - 1) + Initial_Quota
	interest = Initial_Interest + (round - 1) * Interest_Increase_Rate
	interest = clampi(interest, 0, Final_Interest)

func give_player_round_money(score: int) -> void:
	var float_interest: float = float(interest) / 100.0
	money += int(score * float_interest)
	interest_earned = int(score * float_interest)

func take_money_from_player(amount: int) -> void:
	money -= amount

func advance_round() -> void:
	round += 1
	calculate_round_stats()

func reset_player_data():
	round_fee = Initial_Round_Fee
	quota = Initial_Quota
	interest = Initial_Interest
	round = 1
	money = Initial_Chips
	number_of_collectibles = 0
	number_of_bases = 0
	number_of_pair = 0
	number_of_flush = 0
	number_of_straight = 0
	number_of_straight_flush = 0
	number_of_trio = 0
	number_of_bets_landed = 0
	total_score = 0
	number_of_collectibles_used = 0
