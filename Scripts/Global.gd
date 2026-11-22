extends Node

enum CardSuit {YELLOW, BLUE, MAGENTA}
enum CardValue {EGG = 1, EMBRYO = 2, TADPOLE = 3, TADHIND = 4, TADFRONT = 5, YOUNG = 6, OLD = 7, SKELETON = 8}
enum ComboType {BASE, PAIR, COLOUR, SEQUENCE, PURE_SEQUENCE, TRIO}
enum CollectibleType{Alchemist, Ascend, Catalyst, ChameleonBlue, ChameleonPink, ChameleonYellow, Descend, Mimic, SixSeven}

var can_place_bet:bool = false


var collectible_data: Dictionary = {
	CollectibleType.Alchemist: {"price": 55, "desc": "Converts the colour of any 3 selected cards to any random colour"},
	CollectibleType.Ascend: {"price": 40, "desc": "Add 1 value to any selected card"},
	CollectibleType.Catalyst: {"price": 75, "desc": "Adds 10x multiplier to the selected card"},
	CollectibleType.ChameleonBlue: {"price": 25, "desc": "Change selected card to blue colour"},
	CollectibleType.ChameleonPink: {"price": 25, "desc": "Change selected card to magenta colour"},
	CollectibleType.ChameleonYellow: {"price": 25, "desc": "Change selected card to yellow colour"},
	CollectibleType.Descend: {"price": 40, "desc": "Subtract 1 value from any selected card"},
	CollectibleType.Mimic: {"price": 50, "desc": "Changes the selected card's value to the highest value in deck"},
	CollectibleType.SixSeven: {"price": 67, "desc": "Converts the value of any 2 random cards to 6 and 7 with mults 7 and 6"}
	}

var combo_data: Dictionary = {
	ComboType.BASE: [5,"BASE"],
	ComboType.PAIR: [15,"PAIR"],
	ComboType.COLOUR: [25,"FLUSH"],
	ComboType.SEQUENCE: [45,"STRAIGHT"],
	ComboType.PURE_SEQUENCE: [60, "STRAIGHT FLUSH"],
	ComboType.TRIO: [100, "THREE OF A KIND"],
	}
