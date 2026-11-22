extends Node

# Phase Signals
signal phase_changed(new_phase)

# Gameplay Signals
signal bet_placed(bet_type:String, bet_on)
signal roulette_spin_started()
signal card_generated(card_data: CardData)
signal card_selected_for_hand(card_data: CardData)
signal consumable_used(item_id: String)

# Match Flow Signals
signal score_calculated(final_score: int, is_win: bool)
signal money_changed(new_total: int)

#Next Round Prep
signal next_round_button_pressed()
signal show_round_stats_panel(RoundScore: int, CurrentQuota: int, InterestEarned: int, NewQuota: int)

#Showdown button
signal disable_showdown_button()
signal enable_showdown_button()
signal showdown_button_clicked()
signal show_showdown_button()
signal hide_showdown_button()


#Showdown button
signal disable_use_button()
signal enable_use_button()
signal use_button_clicked()
signal show_use_button()
signal hide_use_button()


#collectible
signal make_collectible_useable(collectible)
signal collectible_selected(collectible)

#help
signal give_help(desc: String)

#Cutscenes
signal dialogue_deliver(desc: String)
