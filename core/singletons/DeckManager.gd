extends Node
# Autoload singleton to manage the player's card piles during combat.
# Adheres to set-theoretic isolation of Draw, Hand, and Discard piles.

# Deck card collections.
var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []

# Limits per round (reset at PLAYER_START).
var can_reroll: bool = true
var can_retain: bool = true

# Tracks if a card is marked for retention.
var retained_card: Resource = null

# Set up initial master deck if empty.
func initialize_deck() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	retained_card = null
	
	# Load cards.
	var strike_res = load("res://data/cards/strike.tres")
	var defend_res = load("res://data/cards/defend.tres")
	var dstrike_res = load("res://data/cards/double_strike.tres")
	var fireball_res = load("res://data/cards/fireball.tres")
	var thunder_res = load("res://data/cards/thunder.tres")
	
	# Assemble master deck of 10 cards.
	var master_deck = [
		strike_res, strike_res, strike_res, strike_res,
		defend_res, defend_res, defend_res,
		dstrike_res, fireball_res, thunder_res
	]
	
	# Shuffle and assign to draw pile.
	draw_pile = fisher_yates(master_deck)

# Fisher-Yates shuffle algorithm for unbiased probability.
func fisher_yates(array: Array) -> Array:
	var result = array.duplicate()
	var n = result.size()
	for i in range(n - 1, 0, -1):
		# Pick a random index between 0 and i inclusive.
		var j = randi() % (i + 1)
		# Swap elements.
		var temp = result[i]
		result[i] = result[j]
		result[j] = temp
	return result

# Draw cards from the draw pile into hand.
func draw_cards(count: int) -> void:
	for i in range(count):
		if draw_pile.is_empty():
			# Recycled discard pile if draw pile is exhausted.
			if discard_pile.is_empty():
				break # Absolute deck exhaustion
			draw_pile = fisher_yates(discard_pile)
			discard_pile.clear()
			
		var card = draw_pile.pop_back()
		hand.append(card)
		EventBus.card_drawn_to_ui.emit(card)

# Discard the current hand (except retained card) into the discard pile.
func discard_hand() -> void:
	var new_hand: Array = []
	for card in hand:
		if card == retained_card:
			new_hand.append(card)
		else:
			discard_pile.append(card)
	hand = new_hand
	retained_card = null # Clear the retain marker for the next turn

# Reroll hand mechanic: discards the hand and draws 5 new cards. Available once per round.
func reroll_hand() -> void:
	if not can_reroll:
		return
	can_reroll = false
	
	# Discard current hand.
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	
	# Draw new hand.
	draw_cards(5)

# Retain card mechanic: select a card to keep for the next turn. Available once per round.
func retain_card(card: Resource) -> void:
	if not can_retain:
		return
	if card in hand:
		retained_card = card
		can_retain = false
