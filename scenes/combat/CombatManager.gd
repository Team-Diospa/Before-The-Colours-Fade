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
		player_energy = restored["player_energy"]
		player_block = restored["player_block"]
		enemy_name = restored["enemy_name"]
		enemy_hp = restored["enemy_hp"]
		enemy_max_hp = restored["enemy_max_hp"]
		enemy_intent = restored["enemy_intent"]
		enemy_intent_value = restored["enemy_intent_value"]
		
		# Let feedback know.
		feedback_label.text = "Returned from Reality with Buffs!"
		
		# Update UI layout prior to state change.
		update_ui()
		
		# RATIONALE: Transition directly to PLAYER_ACTION to avoid reset logic (which runs in PLAYER_START)
		# and to retain original turn hand and stats.
		transition_to(State.PLAYER_ACTION)
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
			# RATIONALE: Apply temporary modifiers from reality choices, then consume them.
			player_energy = MAX_ENERGY + GlobalState.starting_energy_modifier
			player_block = GlobalState.starting_block_modifier
			
			# Reset round-specific deck mechanics.
			DeckManager.can_reroll = true
			DeckManager.can_retain = true
			
			# Clean discarded cards and draw 5 + starting draw modifier cards.
			DeckManager.discard_hand()
			DeckManager.draw_cards(5 + GlobalState.starting_draw_modifier)
			
			# Consume first-turn temporary modifiers.
			GlobalState.starting_energy_modifier = 0
			GlobalState.starting_block_modifier = 0
			GlobalState.starting_draw_modifier = 0
			
			# Choose enemy action for this turn.
			decide_enemy_intent()
			
			# Update buttons and stats.
			update_ui()
			animate_feedback("YOUR TURN", true)
			transition_to(State.PLAYER_ACTION)
			
		State.PLAYER_ACTION:
			# Enable player interactive controls.
			set_buttons_disabled(false)
			
		State.PLAYER_END:
			# Disable buttons.
			set_buttons_disabled(true)
			transition_to(State.ENEMY_TURN)
			
		State.ENEMY_TURN:
			animate_feedback("ENEMY TURN", true)
			
			# RATIONALE: Delay enemy action by 1.0s to allow player to register the transition.
			var enemy_timer = get_tree().create_timer(1.0)
			await enemy_timer.timeout
			execute_enemy_action()
			
			# Wait a moment before starting the next player turn.
			var timer = get_tree().create_timer(1.2)
			await timer.timeout
			
			if current_state == State.ENEMY_TURN:
				transition_to(State.PLAYER_START)
				
		State.VICTORY:
			set_buttons_disabled(true)
			animate_feedback("Victory! " + enemy_name + " Slayed.")
			
			# Reset cache since fight is complete.
			ShiftManager.clear_cache()
			
			# Trigger victory sequence.
			_resolve_victory()
			
		State.DEFEAT:
			set_buttons_disabled(true)
			animate_feedback("Defeated...")
			
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
			animate_feedback(enemy_name + " attacked but was blocked!")
			update_stats_pulsed(true, false)
		else:
			damage -= player_block
			player_block = 0
			player_hp = max(0, player_hp - damage)
			GlobalState.player_current_hp = player_hp
			animate_feedback(enemy_name + " deals " + str(damage) + " damage!")
			
			# RATIONALE: Shaking player panel on taking damage to improve visual feedback (juice).
			shake_node($UI/PlayerPanel)
			update_stats_pulsed(true, false)
			
		if player_hp <= 0:
			transition_to(State.DEFEAT)
			return
	elif enemy_intent == "Defend":
		enemy_block += enemy_intent_value
		animate_feedback(enemy_name + " gains " + str(enemy_intent_value) + " block.")
		update_stats_pulsed(false, true)

# Triggered when playing a card button in UI.
func play_card(card: CardData) -> void:
	if current_state != State.PLAYER_ACTION:
		return
	if player_energy < card.energy_cost:
		animate_feedback("Not enough energy!")
		return
		
	player_energy -= card.energy_cost
	
	# Execute effect depending on card.
	var targets: Array = []
	if card.target_mode == "single":
		targets.append(self)
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
		
	update_stats_pulsed(true, true)
	
	# Check for victory.
	if enemy_hp <= 0:
		transition_to(State.VICTORY)

# HP Modification callbacks from CardData.
func take_damage(amount: int) -> void:
	# Special boss mechanic for Burning Village (Pack Leader).
	if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
		amount = 1 # Negligible damage without the confidence buff
		animate_feedback("Attacks are ineffective! The Pack Leader laughs.")
		
	if enemy_block >= amount:
		enemy_block -= amount
	else:
		amount -= enemy_block
		enemy_block = 0
		enemy_hp = max(0, enemy_hp - amount)
		
	# RATIONALE: Shaking enemy panel on taking damage to feel responsive.
	shake_node($UI/EnemyPanel)
	update_stats_pulsed(false, true)

func gain_block(amount: int) -> void:
	player_block += amount
	update_stats_pulsed(true, false)

# Reroll hand option button.
func _on_reroll_pressed() -> void:
	if DeckManager.can_reroll and player_energy >= 1:
		player_energy -= 1
		DeckManager.reroll_hand()
		update_stats_pulsed(true, false)

# Dimension Shift option button.
func _on_shift_pressed() -> void:
	if ShiftManager.can_shift():
		ShiftManager.serialize_combat(
			player_hp, 
			player_energy, 
			player_block, 
			enemy_name, 
			enemy_hp, 
			enemy_max_hp, 
			enemy_intent, 
			enemy_intent_value
		)
		GlobalState.acquired_fragments += 1
		SceneManager.transition_to_state("S_class")

# End Turn option button.
func _on_end_turn_pressed() -> void:
	transition_to(State.PLAYER_END)

# Update screen widgets.
func update_ui() -> void:
	# Show active buffs near the player's name.
	var buff_text = ""
	if GlobalState.has_flag("buff_confidence_active"):
		buff_text = " [Confidence: +100% DMG]"
	elif GlobalState.has_flag("buff_courage_active"):
		buff_text = " [Courage: +50% DMG]"
	$UI/PlayerPanel/VBox/NameLabel.text = "Hilbert Hickman" + buff_text
	
	player_hp_label.text = "HP: " + str(player_hp) + "/" + str(player_max_hp)
	
	# Highlight active block protection.
	if player_block > 0:
		player_block_label.text = "[SHIELDED] Block: " + str(player_block)
	else:
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
		shift_btn.visible = false
		
	reroll_btn.disabled = not DeckManager.can_reroll or player_energy < 1
	
	# Redraw card hand buttons with hover animations.
	for child in hand_container.get_children():
		child.queue_free()
		
	for card in DeckManager.hand:
		var btn = Button.new()
		btn.text = card.card_name + " (" + str(card.energy_cost) + ")\n" + card.description
		btn.custom_minimum_size = Vector2(130, 80)
		btn.pressed.connect(func(): play_card(card))
		hand_container.add_child(btn)
		
		# RATIONALE: Center the scaling pivot and add smooth hover scale transitions.
		btn.pivot_offset = Vector2(65, 80)
		btn.mouse_entered.connect(func():
			var tween = btn.create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.12)
			tween.tween_property(btn, "modulate", Color(1.1, 1.1, 1.2, 1.0), 0.12)
		)
		btn.mouse_exited.connect(func():
			var tween = btn.create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
			tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		)

func set_buttons_disabled(disabled: bool) -> void:
	end_turn_btn.disabled = disabled
	reroll_btn.disabled = disabled or not DeckManager.can_reroll or player_energy < 1
	for btn in hand_container.get_children():
		btn.disabled = disabled

# RATIONALE: Visual juice helpers: shaking panels on damage, pulsing text, and turn banners.
func shake_node(node: Control) -> void:
	if not node: return
	var original_pos = node.position
	var tween = create_tween()
	for i in range(6):
		var offset = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
		tween.tween_property(node, "position", original_pos + offset, 0.02)
	tween.tween_property(node, "position", original_pos, 0.02)

func pulse_label(label: Label) -> void:
	if not label: return
	label.pivot_offset = label.size / 2
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)

func update_stats_pulsed(pulse_player: bool, pulse_enemy: bool) -> void:
	update_ui()
	if pulse_player:
		pulse_label(player_hp_label)
		pulse_label(player_block_label)
		pulse_label(player_energy_label)
	if pulse_enemy:
		pulse_label(enemy_hp_label)
		pulse_label(enemy_block_label)

func animate_feedback(text: String, is_turn_banner: bool = false) -> void:
	feedback_label.text = text
	feedback_label.pivot_offset = feedback_label.size / 2
	
	var tween = create_tween()
	if is_turn_banner:
		feedback_label.scale = Vector2(0.7, 0.7)
		feedback_label.modulate.a = 0.0
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.15)
		tween.tween_property(feedback_label, "scale", Vector2(1.4, 1.4), 0.15)
		tween.tween_interval(0.6)
		tween.tween_property(feedback_label, "modulate:a", 0.8, 0.2)
		tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.2)
	else:
		feedback_label.scale = Vector2(1.1, 1.1)
		tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.10)

# Resolve transition after victory.
# RATIONALE: Substantially revised dialogues to integrate the memory decay psychological horror theme.
func _resolve_victory() -> void:
	if enemy_name == "Castle Boss":
		DialogueSystem.start_dialogue({
			"start": {
				"text": "n.n.: We did it, Hilbert! The castle is secure again.",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "Hilbert: Yeah. But my head feels weirdly light. Like I'm forgetting what class we have next.",
				"next": "win_step3"
			},
			"win_step3": {
				"text": "n.n.: Don't worry about it! Just focus on the morning. Let's wake up.",
				"next": ""
			}
		}, "start")
		
		if not EventBus.dialogue_finished.is_connected(_on_castle_victory_finished):
			EventBus.dialogue_finished.connect(_on_castle_victory_finished)
		
	elif enemy_name == "Pack Leader":
		DialogueSystem.start_dialogue({
			"start": {
				"text": "n.n.: The fire is out, Hilbert. The valley is quiet.",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "Hilbert: It is. But I feel... like I left something behind in the classroom. A notebook? A pen?",
				"next": "win_step3"
			},
			"win_step3": {
				"text": "n.n.: It is fine. You do not need it anymore. You passed. Let's head home.",
				"next": "win_step4"
			},
			"win_step4": {
				"text": "You wake up at your desk in the classroom. The quiz paper in front of you is fully solved. You passed.",
				"next": "win_step5"
			},
			"win_step5": {
				"text": "But the seat next to you is empty and covered in a thin layer of dust. You pull out your phone.",
				"next": "win_step6"
			},
			"win_step6": {
				"text": "Your contact list has a blank entry named 'n.n.' that you do not recognize. You stare at it blankly.",
				"next": "win_step7"
			},
			"win_step7": {
				"text": "Demo Complete. Thank you for playing 'Before the Colours Fade'.",
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
	GlobalState.reset_state()
	SceneManager.transition_to_state("S_apt")

