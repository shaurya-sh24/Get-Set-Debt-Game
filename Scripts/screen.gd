extends Control

@onready var quota_label: Label = $QuotaLabel
@onready var interest_label: Label = $InterestLabel
@onready var chips_label: Label = $ChipsLabel
@onready var round_fee_label: Label = $RoundFeeLabel


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	quota_label.text = str(PlayerData.quota)
	interest_label.text = str(PlayerData.interest) + "%"
	chips_label.text = str(PlayerData.money)
	round_fee_label.text = str(PlayerData.round_fee)
