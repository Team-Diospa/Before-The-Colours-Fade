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
# RATIONALE: Damage and defend values are @export so each combat scene configures its own enemy
# without touching CombatManager logic. Adding a new enemy only requires a new .tscn.
@export var enemy_name: String = "Castle Boss"
@export var enemy_hp: int = 50
@export var enemy_max_hp: int = 50
@export var enemy_phase1_atk: int = 6     # HP > 66%: light pressure.
@export var enemy_phase2_atk: int = 9     # HP 33-66%: escalating aggression.
@export var enemy_phase3_atk: int = 13    # HP < 33%: desperate, maximum damage.
@export var enemy_defend_val: int = 5     # Block amount when enemy defends.
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
@onready var retain_btn = $UI/ActionPanel/VBox/RetainButton
@onready var feedback_label = $UI/FeedbackLabel

# RATIONALE: Retain mode flag - when true, the next card click retains instead of plays.
var _retain_mode_active: bool = false

# Castle Boss: Full n.n. introduction + world arrival + tutorial hints.
# RATIONALE: Follows the script beat-for-beat. n.n.'s 'mission log' framing is the key character detail -
# he is a machine that was activated, following installed instructions. This is a mystery anchor.
var nn_dialogue_castle: Dictionary = {
	"start": {
		"text": "You open your eyes. The air is warm. The cold is gone.",
		"next": "castle_step2"
	},
	"castle_step2": {
		"text": "A grassy field. Trees lean in a slow wind. Something big - a castle, about 100 meters out. It looks normal. But it doesn't feel normal.",
		"next": "castle_step3"
	},
	"castle_step3": {
		"text": "HEY YOU THERE!",
		"speaker": "???",
		"next": "castle_step4"
	},
	"castle_step4": {
		"text": "OVER HERE, DUMMY!",
		"speaker": "???",
		"next": "castle_step5"
	},
	"castle_step5": {
		"text": "You look up. A mechanical thing. Propeller spinning, keeping it airborne. Something about it feels... familiar. Like a schematic you drew a long time ago.",
		"next": "castle_step6"
	},
	"castle_step6": {
		"text": "n.n.? Is that you?",
		"speaker": "Hilbert",
		"next": "castle_step7"
	},
	"castle_step7": {
		"text": "Aww, you remember me?",
		"speaker": "n.n.",
		"next": "castle_step8"
	},
	"castle_step8": {
		"text": "How could I forget. You were one of my first schematics. How did you even get here? What is this place?",
		"speaker": "Hilbert",
		"next": "castle_step9"
	},
	"castle_step9": {
		# RATIONALE: 'Mission log installed' is the key character detail. n.n. doesn't know why he exists -
		# he's following pre-installed instructions. The player pieces together what that means.
		"text": "Well, I just got activated a moment ago. But I have a few mission logs that were installed when I activated. The first one is to enter the castle there and slay the evil that corrupted it.",
		"speaker": "n.n.",
		"next": "castle_step10"
	},
	"castle_step10": {
		"text": "The log also explained - this is the dream world. Here, you have some power that will help you eliminate the obstacles you face in your life.",
		"speaker": "n.n.",
		"next": "castle_step11"
	},
	"castle_step11": {
		"text": "So what power do I have?",
		"speaker": "Hilbert",
		"next": "castle_step12"
	},
	"castle_step12": {
		"text": "Let's try some of it out. Use Strike to attack. Use Defend to block. See what happens.",
		"speaker": "n.n.",
		"next": ""
	}
}

# Pack Leader: Burning village arrival before combat.
# RATIONALE: Faithful to script - n.n. approaches from a distance (not already beside Hilbert).
# The 'No time for questions' line is in the script and gives the scene its urgency.
var nn_dialogue_burning: Dictionary = {
	"start": {
		"text": "A very hot sensation. The smell of burning wood. Smoke rising in thick columns.",
		"next": "burn_step2"
	},
	"burn_step2": {
		"text": "You are in the middle of a burning village. In the distance, a small shape is moving fast toward you.",
		"next": "burn_step3"
	},
	"burn_step3": {
		"text": "Finally you're here! We really need your help. The monsters have invaded the village.",
		"speaker": "n.n.",
		"next": "burn_step4"
	},
	"burn_step4": {
		"text": "Wait - before that. What is this village?",
		"speaker": "Hilbert",
		"next": "burn_step5"
	},
	"burn_step5": {
		"text": "No time to ask questions. Let's just go.",
		"speaker": "n.n.",
		"next": ""
	}
}

# RATIONALE: Pack Leader immunity hint - fires once after the player tries 2+ attacks with no effect.
# The script has n.n. directly instruct the warp. This is where the mechanic is taught narratively,
# so n.n. being direct here is correct. The indirect mystery approach is used everywhere else.
var pack_leader_hint_dialogue: Dictionary = {
	"start": {
		"text": "Your attacks barely leave a mark. The Pack Leader doesn't even blink.",
		"next": "hint_step2"
	},
	"hint_step2": {
		"text": "I think you need to warp back to reality.",
		"speaker": "n.n.",
		"next": "hint_step3"
	},
	"hint_step3": {
		"text": "What? What do you mean?",
		"speaker": "Hilbert",
		"next": "hint_step4"
	},
	"hint_step4": {
		"text": "Sometimes there is just some problem you need to face head on, from the other side. Now's the time.",
		"speaker": "n.n.",
		"next": "hint_step5"
	},
	"hint_step5": {
		"text": "But how? How do I warp back?",
		"speaker": "Hilbert",
		"next": "hint_step6"
	},
	"hint_step6": {
		# RATIONALE: Direct mechanic explanation per script. The Shift button is already visible in UI.
		# n.n. labels what the player can see - 'that gauge' refers to the charge bar onscreen.
		"text": "See that gauge? Keep fighting - even if the attacks don't land. Fill it, and you'll cross over.",
		"speaker": "n.n.",
		"next": ""
	}
}

func _ready() -> void:
	# Reset combat-specific flags at the start of each combat.
	GlobalState.reset_combat_flags()
	
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
		feedback_label.text = "Back in the dream. Something feels different now."
		
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
		
		# Arrival sequence and companion advice.
		call_deferred("_trigger_companion_tutorial")
		
		# Update visual labels.
		update_ui()
		
		# Transition FSM to start the first round.
		transition_to(State.PLAYER_START)

func _trigger_companion_tutorial() -> void:
	# RATIONALE: Play arrival+tutorial dialogue before combat. The dialogue is long enough to
	# give the player time to read before the FSM begins. The FSM is already in PLAYER_START
	# by the time dialogue starts, so card interaction is blocked until dialogue closes.
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
			_retain_mode_active = false
			
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
			# Disable buttons and clear retain mode.
			_retain_mode_active = false
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
			
			# RATIONALE: Contextual defeat line - grounds the restart in the narrative.
			var timer = get_tree().create_timer(1.0)
			await timer.timeout
			DialogueSystem.start_dialogue({
				"start": {
					"text": "The dream collapses. The classroom snaps back around you. Your pencil is still in your hand.",
					"next": ""
				}
			}, "start")
			if not EventBus.dialogue_finished.is_connected(_on_defeat_dialogue_finished):
				EventBus.dialogue_finished.connect(_on_defeat_dialogue_finished)

func _on_defeat_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_defeat_dialogue_finished)
	
	# RATIONALE: Clear the shift cached combat state to avoid resuming a dead combat on retry.
	ShiftManager.clear_cache()
	
	# RATIONALE: Reset all global narrative flags, baseline deck, and player HP back to default for a fresh run.
	# This fixes the 0 HP issue on retry and ensures a consistent restart from the apartment.
	GlobalState.reset_state()
	
	# Go back to apartment to try again.
	SceneManager.transition_to_state("S_apt")

# Decides what the enemy will do on its turn.
# RATIONALE: Three-phase system based on HP thresholds.
# Phase 1 (HP > 66%): Balanced pressure, defends often.
# Phase 2 (HP 33-66%): Increased aggression, more attacks.
# Phase 3 (HP < 33%): Always attacks at maximum damage - no more defending.
func decide_enemy_intent() -> void:
	var hp_ratio: float = float(enemy_hp) / float(enemy_max_hp)
	
	# RATIONALE: Fireball burning flag overrides intent - forces Attack, cancels Defend.
	# This makes Fireball tactically relevant against defensive enemies.
	if GlobalState.has_flag("enemy_burning"):
		enemy_intent = "Attack"
		enemy_intent_value = _get_phase_attack_value(hp_ratio)
		GlobalState.set_flag("enemy_burning", false)  # Consume the burn flag.
		animate_feedback("The enemy is burning - they can't defend!")
		update_ui()
		return
	
	# Phase-based intent roll.
	var attack_chance: float
	var attack_val: int
	
	if hp_ratio > 0.66:
		# Phase 1: Relaxed, exploratory. 60% attack, 40% defend.
		attack_chance = 0.6
		attack_val = enemy_phase1_atk
	elif hp_ratio > 0.33:
		# Phase 2: Cornered but dangerous. 75% attack, 25% defend.
		attack_chance = 0.75
		attack_val = enemy_phase2_atk
	else:
		# Phase 3: Desperate. Always attacks, maximum damage.
		attack_chance = 1.0
		attack_val = enemy_phase3_atk
	
	if randf() < attack_chance:
		enemy_intent = "Attack"
		enemy_intent_value = attack_val
	else:
		enemy_intent = "Defend"
		enemy_intent_value = enemy_defend_val
	
	update_ui()

# Returns the phase-appropriate attack value without modifying intent (used by burning override).
func _get_phase_attack_value(hp_ratio: float) -> int:
	if hp_ratio > 0.66:
		return enemy_phase1_atk
	elif hp_ratio > 0.33:
		return enemy_phase2_atk
	else:
		return enemy_phase3_atk

# Resolves the enemy's intent against the player.
func execute_enemy_action() -> void:
	if enemy_hp <= 0:
		return
		
	# Enemy block decays at the start of their action turn.
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
	
	# RATIONALE: If retain mode is active, the next card click retains the card for next turn.
	if _retain_mode_active:
		DeckManager.retain_card(card)
		_retain_mode_active = false
		animate_feedback("Card retained for next turn.")
		update_ui()
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
	
	# Increment dimension charge on Attack and Special type cards.
	# RATIONALE: Thunder internally calls add_charge twice, Fortress calls it once.
	# Standard Attack cards call it once here. Defense cards do not charge the shift.
	if card.card_type == "Attack":
		ShiftManager.add_charge()
		
		# RATIONALE: Pack Leader immunity tracking. Count attack plays without confidence buff.
		if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
			GlobalState.pack_leader_attack_count += 1
			if GlobalState.pack_leader_attack_count >= 2 and not GlobalState.has_flag("pack_leader_hint_shown"):
				GlobalState.set_flag("pack_leader_hint_shown", true)
				call_deferred("_trigger_pack_leader_hint")
		
	update_stats_pulsed(true, true)
	
	# Check for victory.
	if enemy_hp <= 0:
		transition_to(State.VICTORY)

# Fires the Pack Leader hint dialogue once the player has tried 2+ useless attacks.
func _trigger_pack_leader_hint() -> void:
	DialogueSystem.start_dialogue(pack_leader_hint_dialogue, "start")

# HP Modification callbacks from CardData.
func take_damage(amount: int) -> void:
	# Special boss mechanic for Burning Village (Pack Leader).
	if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
		amount = 1 # Negligible damage without the confidence buff
		animate_feedback("The Pack Leader laughs. Your attacks don't reach it.")
		
	if enemy_block >= amount:
		enemy_block -= amount
	else:
		amount -= enemy_block
		enemy_block = 0
		enemy_hp = max(0, enemy_hp - amount)
		
	# RATIONALE: Shaking enemy panel on taking damage to feel responsive.
	shake_node($UI/EnemyPanel)
	update_stats_pulsed(false, true)

# Called by Heavy Slash to strip enemy block before dealing damage.
func clear_block() -> void:
	enemy_block = 0
	animate_feedback("Heavy Slash breaks through the defense!")
	update_stats_pulsed(false, true)

func gain_block(amount: int) -> void:
	player_block += amount
	update_stats_pulsed(true, false)

# Reroll hand option button.
func _on_reroll_pressed() -> void:
	# RATIONALE: Reroll no longer costs energy (plan item 4.2). Only the once-per-round
	# limit applies. The player sacrifices their current hand, not their action economy.
	if DeckManager.can_reroll:
		DeckManager.reroll_hand()
		update_stats_pulsed(true, false)

# Retain card toggle button.
func _on_retain_pressed() -> void:
	if DeckManager.can_retain and not _retain_mode_active:
		_retain_mode_active = true
		animate_feedback("Select a card to retain for next turn.")
		retain_btn.text = "Retaining...\n(Click a card)"
		update_ui()

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
		
	# Reroll button: disabled if used this round.
	reroll_btn.disabled = not DeckManager.can_reroll
	
	# Retain button: disabled if used this round or in retain mode.
	if retain_btn:
		retain_btn.disabled = not DeckManager.can_retain or _retain_mode_active
		if not _retain_mode_active:
			retain_btn.text = "Retain Card"
	
	# Redraw card hand buttons with hover animations.
	for child in hand_container.get_children():
		child.queue_free()
		
	for card in DeckManager.hand:
		var btn = Button.new()
		# RATIONALE: SIZE_EXPAND_FILL distributes buttons proportionally across the panel.
		# Fixed 130px min caused horizontal overflow with 5 cards. Minimum is now a floor only.
		# Full description is accessible via Tab overlay where space is available.
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(80, 90)
		btn.text = card.card_name + " (" + str(card.energy_cost) + "E)\n" + card.description
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func(): play_card(card))
		hand_container.add_child(btn)
		
		# RATIONALE: Center the scaling pivot and add smooth hover scale transitions.
		# Pivot is set after add_child so btn.size is resolved by the layout engine.
		btn.pivot_offset = Vector2(btn.custom_minimum_size.x / 2, btn.custom_minimum_size.y)
		btn.mouse_entered.connect(func():
			var tween = btn.create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.10, 1.10), 0.12)
			tween.tween_property(btn, "modulate", Color(1.1, 1.1, 1.2, 1.0), 0.12)
		)
		btn.mouse_exited.connect(func():
			var tween = btn.create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
			tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		)

func set_buttons_disabled(disabled: bool) -> void:
	end_turn_btn.disabled = disabled
	reroll_btn.disabled = disabled or not DeckManager.can_reroll
	if retain_btn:
		retain_btn.disabled = disabled or not DeckManager.can_retain
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
func _resolve_victory() -> void:
	if enemy_name == "Castle Boss":
		DialogueSystem.start_dialogue({
			"start": {
				"text": "Wow, that was awesome Hilbert. I didn't know you could do that.",
				"speaker": "n.n.",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "Well, me neither. But somehow I just had the courage. I haven't had this much fun in a long time.",
				"speaker": "Hilbert",
				"next": "win_step3"
			},
			"win_step3": {
				"text": "That's great to hear. But... I'm afraid this is where we have to part ways.",
				"speaker": "n.n.",
				"next": "win_step4"
			},
			"win_step4": {
				"text": "Wait, why? Aren't there many more adventures to come?",
				"speaker": "Hilbert",
				"next": "win_step5"
			},
			"win_step5": {
				# RATIONALE: Parapet mystery anchor inserted here, before the forced farewell.
				# Hilbert asks about a design detail - the player pieces together what this means later.
				"text": "Look at the parapet. Did we draw it with crenellations or flat?",
				"speaker": "Hilbert",
				"next": "win_step6"
			},
			"win_step6": {
				"text": "Flat. The pencil was blunt. We said we'd sharpen it in the morning.",
				"speaker": "n.n.",
				"next": "win_step7"
			},
			"win_step7": {
				"text": "Yes there will be. But you have to wake up too. This is only a dream, Hilbert. You need to go back to reality.",
				"speaker": "n.n.",
				"next": "win_step8"
			},
			"win_step8": {
				# RATIONALE: Script line verbatim - the cut-off mid-sentence is intentional.
				# The world ending the sentence for Hilbert is the point.
				"text": "No. Wait. I can't. I don-",
				"speaker": "Hilbert",
				"next": ""
			}
		}, "start")
		
		if not EventBus.dialogue_finished.is_connected(_on_castle_victory_finished):
			EventBus.dialogue_finished.connect(_on_castle_victory_finished)
		
	elif enemy_name == "Pack Leader":
		DialogueSystem.start_dialogue({
			"start": {
				"text": "The fire is gone. The village is quiet now, Hilbert.",
				"speaker": "n.n.",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "The fire is out. But the sky is turning white.",
				"speaker": "Hilbert",
				"next": "win_step3"
			},
			"win_step3": {
				# RATIONALE: Environmental fading instead of n.n. announcing "wake up".
				# n.n. observes the decay; Hilbert notices it himself.
				"text": "The graphite is smudging. The lines of the village are losing definition.",
				"next": "win_step4"
			},
			"win_step4": {
				"text": "Wait. I drew you with... there was a second signature on the cover page. A cursive L.",
				"speaker": "Hilbert",
				"next": "win_step5"
			},
			"win_step5": {
				# RATIONALE: n.n. does not say "wake up." He observes the world fading, as Hilbert does.
				"text": "The field is going quiet.",
				"speaker": "n.n.",
				"next": "win_step6"
			},
			"win_step6": {
				"text": "You are back at your desk. The exam paper in front of you is completed, every answer filled in your own handwriting. You don't remember solving a single question.",
				"next": "win_step7"
			},
			"win_step7": {
				"text": "The desk next to you is covered in a layer of dust. A faint pencil scratch on the wood reads: H.H. + L.G. 2024.",
				"next": "win_step8"
			},
			"win_step8": {
				# RATIONALE: Demo ends here. No fourth-wall break. The player holds this image.
				"text": "You check your phone. One contact. No name. The caller ID reads: n.n.",
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
