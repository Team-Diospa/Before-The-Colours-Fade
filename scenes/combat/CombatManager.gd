extends Node2D
# Core combat engine executing the Turn-Based Deckbuilder FSM.
# Manages state changes, card resolution, enemy actions, and dimension shifts.

# Combat FSM States.
enum State { INIT, PLAYER_START, PLAYER_ACTION, PLAYER_END, ENEMY_TURN, VICTORY, DEFEAT }
var current_state: State = State.INIT

# Player statistics.
var player_hp: int = 50
var player_max_hp: int = 50
var player_block: int = 0
var player_energy: int = 3
const MAX_ENERGY: int = 3

# Enemy statistics.
@export var enemy_name: String = "Castle Boss"
@export var enemy_hp: int = 50
@export var enemy_max_hp: int = 50
var enemy_block: int = 0
var enemy_intent: String = ""
var enemy_intent_value: int = 0

# Visual Nodes.
@onready var player_hp_label = $UI/PlayerPanel/VBox/HPLabel
@onready var player_block_label = $UI/PlayerPanel/VBox/BlockLabel
@onready var player_energy_label = $UI/PlayerPanel/VBox/EnergyLabel

@onready var enemy_name_label = $UI/EnemyPanel/VBox/NameLabel
@onready var enemy_hp_label = $UI/EnemyPanel/VBox/HPLabel
@onready var enemy_block_label = $UI/EnemyPanel/VBox/BlockLabel
@onready var enemy_intent_label = $UI/EnemyPanel/VBox/IntentLabel

@onready var hand_container = $UI/HandPanel/Margin/HBox
@onready var end_turn_btn = $UI/ActionPanel/VBox/EndTurnButton
@onready var reroll_btn = $UI/ActionPanel/VBox/RerollButton
@onready var shift_btn = $UI/ActionPanel/VBox/ShiftButton
@onready var feedback_label = $UI/FeedbackLabel

# Companion n.n. references.
var nn_dialogue_castle: Dictionary = {
	"start": {
		"text": "n.n.: Hilbert, that castle is a corruption of reality. Press E to use Strike and Defend to defeat it!",
		"next": ""
	}
}

var nn_dialogue_burning: Dictionary = {
	"start": {
		"text": "n.n.: The monster has a fiery blade. Attacks are useless! We must warp back to reality, Hilbert!",
		"next": ""
	}
}

func _ready() -> void:
	# Check if we are resuming from a serialized shift.
	if ShiftManager.cached_combat_exists:
		var restored = ShiftManager.deserialize_combat()
		player_hp = restored["player_hp"]
		enemy_name = restored["enemy_name"]
		enemy_hp = restored["enemy_hp"]
		enemy_max_hp = restored["enemy_max_hp"]
		
		# Let feedback know.
		feedback_label.text = "Returned from Reality with Buffs!"
	else:
		# Fresh start of combat.
		player_hp = GlobalState.player_current_hp
		player_max_hp = GlobalState.player_max_hp
		DeckManager.initialize_deck()
		GlobalState.dimension_charge = 0
		
		# Companion advice at start of battle.
		call_deferred("_trigger_companion_tutorial")
		
	# Update visual labels.
	update_ui()
	
	# Transition FSM to start the first round.
	transition_to(State.PLAYER_START)

func _trigger_companion_tutorial() -> void:
	if enemy_name == "Castle Boss":
		DialogueSystem.start_dialogue(nn_dialogue_castle, "start")
	elif enemy_name == "Pack Leader":
		DialogueSystem.start_dialogue(nn_dialogue_burning, "start")

func transition_to(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.PLAYER_START:
			# Reset energy and defensive block.
			player_energy = MAX_ENERGY
			player_block = 0
			
			# Reset round-specific deck mechanics.
			DeckManager.can_reroll = true
			DeckManager.can_retain = true
			
			# Clean discarded cards and draw 5 new cards.
			DeckManager.discard_hand()
			DeckManager.draw_cards(5)
			
			# Choose enemy action for this turn.
			decide_enemy_intent()
			
			# Update buttons.
			update_ui()
			transition_to(State.PLAYER_ACTION)
			
		State.PLAYER_ACTION:
			# Enable player interactive controls.
			set_buttons_disabled(false)
			
		State.PLAYER_END:
			# Disable buttons.
			set_buttons_disabled(true)
			
			# Transition (block decays at PLAYER_START, protecting player during ENEMY_TURN).
			transition_to(State.ENEMY_TURN)
			
		State.ENEMY_TURN:
			# Resolve enemy attack/defend intent.
			execute_enemy_action()
			
			# Wait a moment before starting the next player turn.
			var timer = get_tree().create_timer(1.2)
			await timer.timeout
			
			if current_state == State.ENEMY_TURN:
				transition_to(State.PLAYER_START)
				
		State.VICTORY:
			set_buttons_disabled(true)
			feedback_label.text = "Victory! " + enemy_name + " Slayed."
			
			# Reset cache since fight is complete.
			ShiftManager.clear_cache()
			
			# Trigger victory sequence.
			_resolve_victory()
			
		State.DEFEAT:
			set_buttons_disabled(true)
			feedback_label.text = "Defeated..."
			
			# Go back to apartment to try again.
			var timer = get_tree().create_timer(2.0)
			await timer.timeout
			SceneManager.transition_to_state("S_apt")

# Decides what the enemy will do on its turn.
func decide_enemy_intent() -> void:
	var roll = randf()
	if roll < 0.6:
		enemy_intent = "Attack"
		enemy_intent_value = 6 if enemy_name == "Castle Boss" else 10
	else:
		enemy_intent = "Defend"
		enemy_intent_value = 5 if enemy_name == "Castle Boss" else 8
	update_ui()

# Resolves the enemy's intent against the player.
func execute_enemy_action() -> void:
	if enemy_hp <= 0:
		return
		
	# decay enemy blocks.
	enemy_block = 0
	
	if enemy_intent == "Attack":
		var damage = enemy_intent_value
		# Apply block mitigation.
		if player_block >= damage:
			player_block -= damage
			feedback_label.text = enemy_name + " attacked but was blocked!"
		else:
			damage -= player_block
			player_block = 0
			player_hp = max(0, player_hp - damage)
			GlobalState.player_current_hp = player_hp
			feedback_label.text = enemy_name + " deals " + str(damage) + " damage!"
			
		if player_hp <= 0:
			transition_to(State.DEFEAT)
			return
	elif enemy_intent == "Defend":
		enemy_block += enemy_intent_value
		feedback_label.text = enemy_name + " gains " + str(enemy_intent_value) + " block."
		
	update_ui()

# Triggered when playing a card button in UI.
func play_card(card: CardData) -> void:
	if current_state != State.PLAYER_ACTION:
		return
	if player_energy < card.energy_cost:
		feedback_label.text = "Not enough energy!"
		return
		
	player_energy -= card.energy_cost
	
	# Execute effect depending on card.
	var targets: Array = []
	if card.target_mode == "single":
		targets.append(self) # We resolve targets against this node
	elif card.target_mode == "all":
		targets.append(self)
	elif card.target_mode == "random":
		targets.append(self)
		
	card.execute_effect(self, targets)
	
	# Move card from hand to discard pile.
	DeckManager.hand.erase(card)
	DeckManager.discard_pile.append(card)
	
	# Increment dimension charge on attacks.
	if card.card_type == "Attack":
		ShiftManager.add_charge()
		
	update_ui()
	
	# Check for victory.
	if enemy_hp <= 0:
		transition_to(State.VICTORY)

# HP Modification callbacks from CardData.
func take_damage(amount: int) -> void:
	# Special boss mechanic for Burning Village (Pack Leader).
	if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
		amount = 1 # Negligible damage without the confidence buff
		feedback_label.text = "Attacks are ineffective! The Pack Leader laughs."
		
	if enemy_block >= amount:
		enemy_block -= amount
	else:
		amount -= enemy_block
		enemy_block = 0
		enemy_hp = max(0, enemy_hp - amount)
		
	update_ui()

func gain_block(amount: int) -> void:
	player_block += amount
	update_ui()

# Reroll hand option button.
func _on_reroll_pressed() -> void:
	if DeckManager.can_reroll and player_energy >= 1:
		player_energy -= 1
		DeckManager.reroll_hand()
		update_ui()

# Dimension Shift option button.
func _on_shift_pressed() -> void:
	if ShiftManager.can_shift():
		# Serialize this exact combat state.
		ShiftManager.serialize_combat(player_hp, enemy_name, enemy_hp, enemy_max_hp)
		
		# Award a fragment to allow interaction in reality.
		GlobalState.acquired_fragments += 1
		
		# Shift back to classroom (where paper monster can be resolved).
		SceneManager.transition_to_state("S_class")

# End Turn option button.
func _on_end_turn_pressed() -> void:
	transition_to(State.PLAYER_END)

# Update screen widgets.
func update_ui() -> void:
	player_hp_label.text = "HP: " + str(player_hp) + "/" + str(player_max_hp)
	player_block_label.text = "Block: " + str(player_block)
	player_energy_label.text = "Energy: " + str(player_energy) + "/" + str(MAX_ENERGY)
	
	enemy_name_label.text = enemy_name
	enemy_hp_label.text = "HP: " + str(enemy_hp) + "/" + str(enemy_max_hp)
	enemy_block_label.text = "Block: " + str(enemy_block)
	enemy_intent_label.text = "Intent: " + enemy_intent + " (" + str(enemy_intent_value) + ")"
	
	# Dimension shifting button logic in Pack Leader fight.
	if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
		shift_btn.visible = true
		if ShiftManager.can_shift():
			shift_btn.disabled = false
			shift_btn.text = "Shift to Reality\n(READY)"
		else:
			shift_btn.disabled = true
			shift_btn.text = "Shift to Reality\n(" + str(GlobalState.dimension_charge) + "/3)"
	else:
		# Hide the button in Castle Boss tutorial and after the buff is already used.
		shift_btn.visible = false
		
	reroll_btn.disabled = not DeckManager.can_reroll or player_energy < 1
	
	# Redraw card hand buttons.
	for child in hand_container.get_children():
		child.queue_free()
		
	for card in DeckManager.hand:
		var btn = Button.new()
		btn.text = card.card_name + " (" + str(card.energy_cost) + ")\n" + card.description
		btn.custom_minimum_size = Vector2(130, 80)
		btn.pressed.connect(func(): play_card(card))
		hand_container.add_child(btn)

func set_buttons_disabled(disabled: bool) -> void:
	end_turn_btn.disabled = disabled
	reroll_btn.disabled = disabled or not DeckManager.can_reroll or player_energy < 1
	for btn in hand_container.get_children():
		btn.disabled = disabled

# Resolve transition after victory.
func _resolve_victory() -> void:
	if enemy_name == "Castle Boss":
		# Castle Boss defeated -> returns to Classroom (S_class).
		DialogueSystem.start_dialogue({
			"start": {
				"text": "n.n.: Wow, that was awesome Hilbert! I didn't know you could do that.",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "n.n.: But this is only a dream, you need to go back to reality. Wake up...",
				"next": ""
			}
		}, "start")
		
		if not EventBus.dialogue_finished.is_connected(_on_castle_victory_finished):
			EventBus.dialogue_finished.connect(_on_castle_victory_finished)
		
	elif enemy_name == "Pack Leader":
		# Pack Leader defeated -> game victory.
		DialogueSystem.start_dialogue({
			"start": {
				"text": "n.n.: With that determination and resolve, the monster perished from sight!",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "The burning village returns to the sunny calmness of childhood dreams.",
				"next": "win_step3"
			},
			"win_step3": {
				"text": "Demo Complete! You have successfully faced the quiz and conquered Hilbert's inner doubt. Thank you for playing!",
				"next": ""
			}
		}, "start")
		
		if not EventBus.dialogue_finished.is_connected(_on_pack_victory_finished):
			EventBus.dialogue_finished.connect(_on_pack_victory_finished)

# Bound listener callback to avoid signal reference leaks.
func _on_castle_victory_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_castle_victory_finished)
	SceneManager.transition_to_state("S_class")

# Bound listener callback to avoid signal reference leaks.
func _on_pack_victory_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_pack_victory_finished)
	# Go back to apartment (reset).
	GlobalState.reset_state()
	SceneManager.transition_to_state("S_apt")

