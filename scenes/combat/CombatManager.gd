extends Node2D
# Core combat engine executing the Turn-Based Deckbuilder FSM.
# Manages state changes, card resolution, enemy actions, and dimension shifts.

# Combat FSM States.
enum State { INIT, PLAYER_START, PLAYER_ACTION, PLAYER_END, ENEMY_TURN, VICTORY, DEFEAT }
var current_state: State = State.INIT

# RATIONALE: Tracks the current step of the first-combat guided card-play tutorial.
var tutorial_step: int = 0

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

# Slay the Spire style circular energy orb widgets.
var energy_orb: Panel
var energy_orb_label: Label

# RATIONALE: Retain mode flag - when true, the next card click retains instead of plays.
var _retain_mode_active: bool = false

# UI controls for top bar and Booklet Deck Viewer.
var top_bar: Panel
var progress_label: Label
var gold_label: Label
var deck_booklet_btn: Button
var deck_viewer_panel: Panel
var deck_scroll_container: ScrollContainer
var deck_grid: GridContainer
var current_viewer_pile: String = "Deck" # Current active tab: "Deck", "Draw", or "Discard"
var _transitioning_wave: bool = false # Gate to prevent double-clearing of wave states
var deck_viewer_layer: CanvasLayer # Dedicated layer for deck viewer modal to avoid mouse blocking

# Programmatic wave stages, targeting, and sprite variables.
var current_stage_idx: int = 0
var stages_data: Array = []
var active_enemies: Array = []
var selected_enemy_idx: int = 0
var player_sprite: Sprite2D = null

# RATIONALE: Inner class helper to route damage and block-clearing actions to specific wave enemies.
class EnemyTarget:
	var manager: Node2D
	var index: int
	
	func _init(m: Node2D, idx: int) -> void:
		manager = m
		index = idx
		
	func take_damage(amount: int) -> void:
		manager.damage_enemy(index, amount)
		
	func clear_block() -> void:
		manager.clear_enemy_block(index)


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
	# Initialize wave stages data structures
	_init_stages_data()
	
	# Hide default enemy panel template since wave panels are spawned programmatically
	$UI/EnemyPanel.visible = false
	
	# Programmatically spawn player sprite facing right
	player_sprite = Sprite2D.new()
	player_sprite.texture = load("res://Assets/Sprites/character3.png")
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.scale = Vector2(5.0, 5.0)
	player_sprite.position = Vector2(250, 360)
	add_child(player_sprite)
	
	# Create top bar progression and booklet deck viewer UI
	_create_top_bar()
	_create_deck_viewer()

	# Programmatically spawn the RetainButton if it is missing from the scene tree.
	# RATIONALE: Avoids binary scene file corruption by instantiating the UI control in code.
	var action_vbox = $UI/ActionPanel/VBox
	if action_vbox and not action_vbox.has_node("RetainButton"):
		retain_btn = Button.new()
		retain_btn.name = "RetainButton"
		retain_btn.text = "Retain Card"
		action_vbox.add_child(retain_btn)
		retain_btn.pressed.connect(_on_retain_pressed)

	# Instantiate and add the custom sketch-style combat visuals.
	var visuals_script = load("res://scenes/combat/CombatVisuals.gd")
	if visuals_script:
		var visuals = Node2D.new()
		visuals.name = "CombatVisuals"
		visuals.set_script(visuals_script)
		add_child(visuals)

	# Warm beige background for dream child world combat sketch.
	if $UI/Background:
		$UI/Background.color = Color(0.95, 0.93, 0.87, 1.0)

	# Style HandPanel and ActionPanel with warm tan paper styleboxes and drop shadows.
	# Restyled to translucent glassmorphism with square corners and a thin highlight.
	var panel_bg = Color(0.95, 0.93, 0.88, 0.5) # Translucent beige glass base
	var panel_border = Color(1.0, 1.0, 1.0, 0.25) # Thin white glass shine border
	
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = panel_bg
	style_panel.border_width_left = 2
	style_panel.border_width_top = 2
	style_panel.border_width_right = 2
	style_panel.border_width_bottom = 2
	style_panel.border_color = panel_border
	style_panel.anti_aliasing = false
	style_panel.corner_radius_top_left = 0
	style_panel.corner_radius_top_right = 0
	style_panel.corner_radius_bottom_left = 0
	style_panel.corner_radius_bottom_right = 0
	style_panel.shadow_color = Color(0, 0, 0, 0.1) # Soft subtle shadow
	style_panel.shadow_size = 2
	style_panel.shadow_offset = Vector2(2, 2)
	
	$UI/HandPanel.add_theme_stylebox_override("panel", style_panel)
	$UI/ActionPanel.add_theme_stylebox_override("panel", style_panel)

	# Transparent empty stylebox for Player and Enemy panel to float floating labels.
	var empty_style = StyleBoxEmpty.new()
	$UI/PlayerPanel.add_theme_stylebox_override("panel", empty_style)
	$UI/EnemyPanel.add_theme_stylebox_override("panel", empty_style)

	# Reposition PlayerPanel and EnemyPanel to float above the health lines.
	$UI/PlayerPanel.position = Vector2(150, 150)
	$UI/PlayerPanel.size = Vector2(200, 100)
	$UI/EnemyPanel.position = Vector2(800, 150)
	$UI/EnemyPanel.size = Vector2(200, 100)

	# Make labels dark slate for high contrast readability against light sketch paper.
	var label_color = Color(0.12, 0.12, 0.15, 1.0)
	for label in [
		$UI/PlayerPanel/VBox/NameLabel,
		$UI/PlayerPanel/VBox/HPLabel,
		$UI/PlayerPanel/VBox/BlockLabel,
		$UI/EnemyPanel/VBox/NameLabel,
		$UI/EnemyPanel/VBox/HPLabel,
		$UI/EnemyPanel/VBox/BlockLabel,
		$UI/EnemyPanel/VBox/IntentLabel,
		$UI/FeedbackLabel
	]:
		if label:
			label.add_theme_color_override("font_color", label_color)

	# Hide default energy label inside VBox since we have a dedicated circular energy orb.
	player_energy_label.visible = false
	
	# Apply sketched paper styling to the action buttons (with dark text and brick red hover).
	# Restyled to match the translucent, square-cornered glossy aesthetic.
	var btn_bg_normal = Color(0.92, 0.90, 0.84, 0.65)
	var btn_bg_hover = Color(0.97, 0.95, 0.90, 0.75)
	var btn_border_normal = Color(0.12, 0.12, 0.15, 0.15)
	var btn_border_hover = Color(0.65, 0.25, 0.15, 0.4) # Muted brick red outline
	var btn_border_pressed = Color(0.12, 0.12, 0.15, 0.15)
	
	var style_btn_normal = StyleBoxFlat.new()
	style_btn_normal.bg_color = btn_bg_normal
	style_btn_normal.border_width_left = 2
	style_btn_normal.border_width_top = 2
	style_btn_normal.border_width_right = 2
	style_btn_normal.border_width_bottom = 2
	style_btn_normal.border_color = btn_border_normal
	style_btn_normal.anti_aliasing = false
	style_btn_normal.corner_radius_top_left = 0
	style_btn_normal.corner_radius_top_right = 0
	style_btn_normal.corner_radius_bottom_left = 0
	style_btn_normal.corner_radius_bottom_right = 0
	style_btn_normal.shadow_color = Color(0, 0, 0, 0.08)
	style_btn_normal.shadow_size = 1
	style_btn_normal.shadow_offset = Vector2(1, 1)
	
	var style_btn_hover = style_btn_normal.duplicate()
	style_btn_hover.bg_color = btn_bg_hover
	style_btn_hover.border_color = btn_border_hover
	
	var style_btn_pressed = style_btn_normal.duplicate()
	style_btn_pressed.bg_color = Color(0.85, 0.83, 0.77, 0.7)
	style_btn_pressed.border_color = btn_border_pressed
	style_btn_pressed.shadow_offset = Vector2(0, 0) # Pressed state shifts shadow flat
	
	for btn in [end_turn_btn, reroll_btn, shift_btn, retain_btn]:
		if btn:
			btn.add_theme_stylebox_override("normal", style_btn_normal)
			btn.add_theme_stylebox_override("hover", style_btn_hover)
			btn.add_theme_stylebox_override("pressed", style_btn_pressed)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			# Add high contrast dark font colors for the beige buttons
			btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.65, 0.25, 0.15, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.12, 0.15, 1.0))
			btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1.0))
			
			btn.resized.connect(func(): btn.pivot_offset = btn.size / 2)
			btn.mouse_entered.connect(func():
				if not btn.text.begins_with("▼ "):
					btn.text = "▼ " + btn.text
				var tw = btn.create_tween().set_parallel(true)
				tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			)
			btn.mouse_exited.connect(func():
				if btn.text.begins_with("▼ "):
					btn.text = btn.text.substr(2)
				var tw = btn.create_tween().set_parallel(true)
				tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			)

	# Create Slay the Spire style Energy Orb.
	_create_energy_orb()

	# Entry animations: slide character panels from off-screen into their layout position.
	call_deferred("_animate_combat_entry")

	# Reset combat-specific flags at the start of each combat.
	GlobalState.reset_combat_flags()
	
	# Check if we are resuming from a serialized shift.
	if ShiftManager.cached_combat_exists:
		var restored = ShiftManager.deserialize_combat()
		player_hp = restored["player_hp"]
		player_energy = restored["player_energy"]
		player_block = restored["player_block"]
		enemy_name = restored["enemy_name"]
		
		# RATIONALE: Restore wave stages from the deserialized cache, recreating sprites and panel layouts.
		current_stage_idx = restored.get("current_stage_idx", 0)
		_start_wave(current_stage_idx)
		
		var saved_enemies = restored.get("active_enemies", [])
		for idx in range(min(saved_enemies.size(), active_enemies.size())):
			active_enemies[idx]["hp"] = saved_enemies[idx]["hp"]
			active_enemies[idx]["block"] = saved_enemies[idx]["block"]
			active_enemies[idx]["intent"] = saved_enemies[idx]["intent"]
			active_enemies[idx]["intent_value"] = saved_enemies[idx]["intent_value"]
			if active_enemies[idx]["hp"] <= 0:
				if active_enemies[idx]["sprite"]: active_enemies[idx]["sprite"].visible = false
				if active_enemies[idx]["panel"]: active_enemies[idx]["panel"].visible = false
				if active_enemies[idx]["target_btn"]: active_enemies[idx]["target_btn"].visible = false
				
		_auto_select_alive_enemy()
		
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
		
		# RATIONALE: Start first wave stage.
		_start_wave(0)
		
		# Arrival sequence and companion advice.
		call_deferred("_trigger_companion_tutorial")
		
		# Update visual labels.
		update_ui()
		
		# RATIONALE: Hook into dialogue completion to trigger the guided card play tutorial.
		if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
			if not EventBus.dialogue_finished.is_connected(_on_intro_dialogue_finished):
				EventBus.dialogue_finished.connect(_on_intro_dialogue_finished)
		
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
			
			# RATIONALE: Trigger Turn 2 of the guided tutorial once the first turn ends.
			if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done") and tutorial_step == 3:
				tutorial_step = 4
				call_deferred("_trigger_tutorial_turn_2")
				
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
			
			# Fastened delays for snappier pacing.
			var enemy_timer = get_tree().create_timer(0.4)
			await enemy_timer.timeout
			execute_enemy_action()
			
			# Wait a moment before starting the next player turn.
			var timer = get_tree().create_timer(0.5)
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
			# If defeated by the Pack Leader without the confidence buff, point them back to the classroom Paper Monster.
			var timer = get_tree().create_timer(1.0)
			await timer.timeout
			
			if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
				DialogueSystem.start_dialogue({
					"start": {
						"text": "The Pack Leader's flames consume you. Your strikes were like paper against fire.",
						"next": "fail_2"
					},
					"fail_2": {
						# RATIONALE: Ground the warning in the quiz paper stressor instead of the paper monster.
						"text": "You feel a cold sweat. The quiz paper on your desk was jumbled. You ignored it. You did not face your panic.",
						"next": "fail_3"
					},
					"fail_3": {
						"text": "Perhaps if you had used the memory fragment to focus on the quiz paper, you would have found the confidence to cut through the flames.",
						"next": "fail_4"
					},
					"fail_4": {
						"text": "The dream collapses. The classroom snaps back around you. You must try again, and face your stressors directly this time.",
						"next": ""
					}
				}, "start")
			else:
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
# RATIONALE: Three-phase system based on HP thresholds, executed for each active wave enemy.
func decide_enemy_intent() -> void:
	var is_burning = GlobalState.has_flag("enemy_burning")
	
	for idx in range(active_enemies.size()):
		var enemy = active_enemies[idx]
		if enemy["hp"] <= 0:
			continue
			
		var hp_ratio: float = float(enemy["hp"]) / float(enemy["max_hp"])
		
		# RATIONALE: Fireball burning flag overrides intent. Defends are cancelled and converted to Attacks/Idles.
		if is_burning:
			var attack_chance: float
			var attack_val: int
			if hp_ratio > 0.66:
				attack_chance = 0.6
				attack_val = enemy["phase1_atk"]
			elif hp_ratio > 0.33:
				attack_chance = 0.75
				attack_val = enemy["phase2_atk"]
			else:
				attack_chance = 1.0
				attack_val = enemy["phase3_atk"]
				
			if randf() < attack_chance:
				enemy["intent"] = "Attack"
				enemy["intent_value"] = attack_val
			else:
				enemy["intent"] = "Idle"
				enemy["intent_value"] = 0
		else:
			# Standard phase-based intent roll
			var attack_chance: float
			var attack_val: int
			if hp_ratio > 0.66:
				attack_chance = 0.6
				attack_val = enemy["phase1_atk"]
			elif hp_ratio > 0.33:
				attack_chance = 0.75
				attack_val = enemy["phase2_atk"]
			else:
				attack_chance = 1.0
				attack_val = enemy["phase3_atk"]
				
			if randf() < attack_chance:
				enemy["intent"] = "Attack"
				enemy["intent_value"] = attack_val
			else:
				enemy["intent"] = "Defend"
				enemy["intent_value"] = enemy["defend_val"]
				
	if is_burning:
		GlobalState.set_flag("enemy_burning", false) # Consume burning flag
		animate_feedback("The enemies are burning - defense cancelled!")
		
	update_ui()

# RATIONALE: Resolves all active wave enemies' intents against the player sequentially.
func execute_enemy_action() -> void:
	for idx in range(active_enemies.size()):
		var enemy = active_enemies[idx]
		if enemy["hp"] <= 0:
			continue
			
		# Enemy block decays at the start of their action turn.
		enemy["block"] = 0
		
		if enemy["intent"] == "Attack":
			var damage = enemy["intent_value"]
			if player_block >= damage:
				player_block -= damage
				animate_feedback(enemy["name"] + " attacked but was blocked!")
				update_stats_pulsed(true, false)
			else:
				damage -= player_block
				player_block = 0
				player_hp = max(0, player_hp - damage)
				GlobalState.player_current_hp = player_hp
				animate_feedback(enemy["name"] + " deals " + str(damage) + " damage!")
				
				shake_node($UI/PlayerPanel)
				flash_red($UI/PlayerPanel)
				update_stats_pulsed(true, false)
				
			if player_hp <= 0:
				transition_to(State.DEFEAT)
				return
		elif enemy["intent"] == "Defend":
			enemy["block"] += enemy["intent_value"]
			animate_feedback(enemy["name"] + " gains " + str(enemy["intent_value"]) + " block.")
			if enemy["panel"]:
				flash_blue(enemy["panel"])
			update_stats_pulsed(false, true)
		elif enemy["intent"] == "Idle":
			animate_feedback(enemy["name"] + " struggles through the flames and does nothing.")

# Triggered when playing a card button in UI.
func play_card(card: CardData) -> void:
	if current_state != State.PLAYER_ACTION:
		return
	if DialogueSystem.is_active:
		# RATIONALE: During the guided tutorial, allow playing cards even if the tutorial prompt bubble is open.
		# This makes the card play immediately responsive without requiring a manual dismiss.
		if not (enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done")):
			return
		
	# RATIONALE: Guided tutorial card restriction enforcement.
	# Ensures the player understands basic play order of Strike then Defend.
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		if tutorial_step == 1:
			if card.card_name != "Strike":
				DialogueSystem.start_dialogue({
					"start": {
						"text": "Try playing a Strike card first!",
						"speaker": "n.n.",
						"next": ""
					}
				}, "start")
				return
		elif tutorial_step == 2:
			if card.card_name != "Defend":
				DialogueSystem.start_dialogue({
					"start": {
						"text": "Try playing a Defend card next!",
						"speaker": "n.n.",
						"next": ""
					}
				}, "start")
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
		targets.append(EnemyTarget.new(self, selected_enemy_idx))
	elif card.target_mode == "all":
		for idx in range(active_enemies.size()):
			if active_enemies[idx]["hp"] > 0:
				targets.append(EnemyTarget.new(self, idx))
	elif card.target_mode == "random":
		var alive_indices = []
		for idx in range(active_enemies.size()):
			if active_enemies[idx]["hp"] > 0:
				alive_indices.append(idx)
		if not alive_indices.is_empty():
			var rand_idx = alive_indices[randi() % alive_indices.size()]
			targets.append(EnemyTarget.new(self, rand_idx))
		
	card.execute_effect(self, targets)
	
	# Move card from hand to discard pile.
	DeckManager.hand.erase(card)
	DeckManager.discard_pile.append(card)
	
	# Increment dimension charge on Attack and Special type cards.
	# RATIONALE: Thunder internally calls add_charge twice, Fortress calls it once.
	# Standard Attack cards call it once here. Defense cards do not charge the shift.
	if card.card_type == "Attack":
		ShiftManager.add_charge()
		
	# RATIONALE: Advance guided tutorial steps upon playing the expected cards.
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		if tutorial_step == 1:
			tutorial_step = 2
			call_deferred("_trigger_tutorial_step_2")
		elif tutorial_step == 2:
			tutorial_step = 3
			call_deferred("_trigger_tutorial_step_3")
		
		# RATIONALE: Pack Leader immunity tracking. Count attack plays without confidence buff.
		if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
			GlobalState.pack_leader_attack_count += 1
			if GlobalState.pack_leader_attack_count >= 2 and not GlobalState.has_flag("pack_leader_hint_shown"):
				GlobalState.set_flag("pack_leader_hint_shown", true)
				call_deferred("_trigger_pack_leader_hint")
		
	update_stats_pulsed(true, true)
	
	# Check for wave victory or stage transition.
	if _check_wave_victory():
		if current_stage_idx < stages_data.size() - 1:
			_transition_to_next_wave()
		else:
			transition_to(State.VICTORY)

# Fires the Pack Leader hint dialogue once the player has tried 2+ useless attacks.
func _trigger_pack_leader_hint() -> void:
	DialogueSystem.start_dialogue(pack_leader_hint_dialogue, "start")

# HP Modification callbacks from CardData.
# RATIONALE: Routes fallback take_damage calls to the currently selected wave enemy.
func take_damage(amount: int) -> void:
	damage_enemy(selected_enemy_idx, amount)

# Called by Heavy Slash fallback to strip block of the selected wave enemy.
func clear_block() -> void:
	clear_enemy_block(selected_enemy_idx)

func gain_block(amount: int) -> void:
	player_block += amount
	flash_blue($UI/PlayerPanel)
	update_stats_pulsed(true, false)

# Called by Fireball to immediately override any active Defend intents on all wave enemies.
func cancel_enemy_defend() -> void:
	var cancelled = false
	for enemy in active_enemies:
		if enemy["intent"] == "Defend":
			enemy["intent"] = "Idle"
			enemy["intent_value"] = 0
			cancelled = true
	if cancelled:
		GlobalState.set_flag("enemy_burning", false) # Consume the burn flag
		animate_feedback("The enemies are burning - defense cancelled!")
		update_ui()

# Reroll hand option button.
func _on_reroll_pressed() -> void:
	# RATIONALE: Block action while dialogue is active.
	if DialogueSystem.is_active:
		return
	# RATIONALE: Disable rerolls during the guided tutorial.
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		DialogueSystem.start_dialogue({
			"start": {
				"text": "Not yet. Follow the steps first!",
				"speaker": "n.n.",
				"next": ""
			}
		}, "start")
		return
	if DeckManager.can_reroll:
		DeckManager.reroll_hand()
		update_stats_pulsed(true, false)

# Retain card toggle button.
func _on_retain_pressed() -> void:
	# RATIONALE: Block action while dialogue is active.
	if DialogueSystem.is_active:
		return
	# RATIONALE: Disable retain during the guided tutorial.
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		DialogueSystem.start_dialogue({
			"start": {
				"text": "Not yet. Follow the steps first!",
				"speaker": "n.n.",
				"next": ""
			}
		}, "start")
		return
	if DeckManager.can_retain and not _retain_mode_active:
		_retain_mode_active = true
		animate_feedback("Select a card to retain for next turn.")
		_update_btn_text(retain_btn, "Retaining...\n(Click a card)")
		update_ui()

# Dimension Shift option button.
func _on_shift_pressed() -> void:
	# RATIONALE: Block action while dialogue is active.
	if DialogueSystem.is_active:
		return
	if ShiftManager.can_shift():
		# RATIONALE: Bateson's Double-Bind. Shifting isn't a clean escape; it has a visual cost.
		# Add a blinding white flash and violent screen shake before transitioning.
		var flash = ColorRect.new()
		flash.color = Color.WHITE
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$UI.add_child(flash)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(flash, "color:a", 0.0, 0.6)
		
		var original_pos = position
		var shake_tw = create_tween()
		for i in range(6):
			var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			shake_tw.tween_property(self, "position", original_pos + offset, 0.05)
		shake_tw.tween_property(self, "position", original_pos, 0.05)
		
		await shake_tw.finished
		
		var current_enemy = active_enemies[selected_enemy_idx]
		ShiftManager.serialize_combat(
			player_hp, 
			player_energy, 
			player_block, 
			enemy_name, 
			current_enemy["hp"], 
			current_enemy["max_hp"], 
			current_enemy["intent"], 
			current_enemy["intent_value"],
			active_enemies,
			current_stage_idx
		)
		GlobalState.acquired_fragments += 1
		SceneManager.transition_to_state("S_class")

# End Turn option button.
func _on_end_turn_pressed() -> void:
	# RATIONALE: Block action while dialogue is active.
	if DialogueSystem.is_active:
		return
	# RATIONALE: Enforce completion of tutorial cards before ending turn.
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		if tutorial_step != 3:
			DialogueSystem.start_dialogue({
				"start": {
					"text": "Finish your tutorial actions before ending the turn!",
					"speaker": "n.n.",
					"next": ""
				}
			}, "start")
			return
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
	
	# Update top bar progress and gold count labels
	if progress_label:
		progress_label.text = "Wave: " + str(current_stage_idx + 1) + "/" + str(stages_data.size())
	if gold_label:
		gold_label.text = "Fragments: " + str(GlobalState.acquired_fragments)

	# Update each programmatically cloned wave enemy panel
	for idx in range(active_enemies.size()):
		var enemy = active_enemies[idx]
		var panel = enemy["panel"]
		if panel:
			var name_lbl = panel.get_node_or_null("VBox/NameLabel")
			var hp_lbl = panel.get_node_or_null("VBox/HPLabel")
			var block_lbl = panel.get_node_or_null("VBox/BlockLabel")
			var intent_lbl = panel.get_node_or_null("VBox/IntentLabel")
			
			if name_lbl:
				var name_text = enemy["name"]
				if idx == selected_enemy_idx:
					name_text = "=> " + name_text + " <="
					name_lbl.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Sienna targeted
				else:
					name_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0)) # Graphite default
				name_lbl.text = name_text
			if hp_lbl:
				hp_lbl.text = "HP: " + str(enemy["hp"]) + "/" + str(enemy["max_hp"])
			if block_lbl:
				if enemy["block"] > 0:
					block_lbl.text = "[SHIELDED] Block: " + str(enemy["block"])
				else:
					block_lbl.text = "Block: " + str(enemy["block"])
			if intent_lbl:
				if enemy["hp"] <= 0:
					intent_lbl.text = "Defeated"
				elif enemy["intent"] == "Attack":
					intent_lbl.text = "Intent: Attack (" + str(enemy["intent_value"]) + ")"
				elif enemy["intent"] == "Defend":
					intent_lbl.text = "Intent: Defend (" + str(enemy["intent_value"]) + ")"
				else:
					intent_lbl.text = "Intent: Idle"
	
	# Dimension shifting button logic in Pack Leader fight.
	if enemy_name == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
		shift_btn.visible = true
		if ShiftManager.can_shift():
			shift_btn.disabled = false
			_update_btn_text(shift_btn, "Shift to Reality\n(READY)")
		else:
			shift_btn.disabled = true
			_update_btn_text(shift_btn, "Shift to Reality\n(" + str(GlobalState.dimension_charge) + "/3)")
	else:
		shift_btn.visible = false
		
	# Reroll button: disabled if used this round.
	reroll_btn.disabled = not DeckManager.can_reroll
	
	# Retain button: disabled if used this round or in retain mode.
	if retain_btn:
		retain_btn.disabled = not DeckManager.can_retain or _retain_mode_active
		if not _retain_mode_active:
			_update_btn_text(retain_btn, "Retain Card")

	# Update circular energy orb label
	if energy_orb_label:
		energy_orb_label.text = str(player_energy) + "/" + str(MAX_ENERGY)
		
	# Redraw custom combat visuals (Shift eye, health bars, drop shadows)
	var visuals = get_node_or_null("CombatVisuals")
	if visuals:
		visuals.queue_redraw()
	
	# Redraw card hand buttons with hover animations.
	for child in hand_container.get_children():
		child.queue_free()
		
	var card_index = 0
	for card in DeckManager.hand:
		var btn = Button.new()
		# Shrink cards to 95x45 and remove description to eliminate cognitive fatigue.
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(95, 45)
		
		# RATIONALE: Determine base button text and append [RETAINED] if the card is retained.
		var base_btn_text = card.card_name + " (" + str(card.energy_cost) + "E)"
		var display_text = base_btn_text
		if DeckManager.retained_card == card:
			display_text += " [RETAINED]"
		btn.text = display_text
		
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func(): play_card(card))
		hand_container.add_child(btn)
		
		# Simple flat retro pixel stylebox for card (with retro drop shadow).
		# Stylized as sketched translucent notebook card pieces with soft outlines.
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.96, 0.95, 0.92, 0.75) # Translucent light cream sketch paper
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.anti_aliasing = false
		card_style.corner_radius_top_left = 0
		card_style.corner_radius_top_right = 0
		card_style.corner_radius_bottom_left = 0
		card_style.corner_radius_bottom_right = 0
		card_style.shadow_color = Color(0, 0, 0, 0.08) # Muted shadow for paper cards
		card_style.shadow_size = 1
		card_style.shadow_offset = Vector2(1, 1)
		
		# Hand-colored pigments for borders: Crimson (Attack), Cobalt (Defense), Amber (Special)
		var border_color = Color(0.4, 0.4, 0.4, 0.5)
		if card.card_type == "Attack":
			border_color = Color(0.8, 0.3, 0.3, 0.5)
		elif card.card_type == "Defense":
			border_color = Color(0.3, 0.5, 0.8, 0.5)
		elif card.card_type == "Special":
			border_color = Color(0.8, 0.55, 0.2, 0.5)
		card_style.border_color = border_color
		
		var card_style_hover = card_style.duplicate()
		card_style_hover.bg_color = Color(0.99, 0.98, 0.95, 0.85)
		card_style_hover.border_color = border_color.lightened(0.15)
		
		var card_style_pressed = card_style.duplicate()
		card_style_pressed.bg_color = Color(0.88, 0.87, 0.84, 0.75)
		card_style_pressed.border_color = border_color.darkened(0.15)
		card_style_pressed.shadow_offset = Vector2(0, 0) # Shunts down when clicked
		
		btn.add_theme_stylebox_override("normal", card_style)
		btn.add_theme_stylebox_override("hover", card_style_hover)
		btn.add_theme_stylebox_override("pressed", card_style_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		# Force dark charcoal text overrides on the light beige cards for high-contrast legibility
		btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.65, 0.25, 0.15, 1.0)) # Highlight on hover
		btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.12, 0.15, 1.0))
		btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1.0))
		
		# Center the scaling pivot and set snappy hover transitions
		btn.pivot_offset = Vector2(47.5, 22.5)
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2)
		
		# Set mouse enter/exit: shows description in the main FeedbackLabel, scales up and rotates.
		# RATIONALE: We reuse the display_text computed at the top of the loop to avoid redeclaration errors.
		var tilt_angle = deg_to_rad(3.0)
		
		# Capture a unique hover tween state for this button closure.
		var active_tweens = { "tween": null }
		
		btn.mouse_entered.connect(func():
			if active_tweens["tween"]:
				active_tweens["tween"].kill()
			btn.text = "▼ " + display_text
			feedback_label.text = card.description
			active_tweens["tween"] = btn.create_tween().set_parallel(true)
			active_tweens["tween"].tween_property(btn, "scale", Vector2(1.1, 1.1), 0.12).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "rotation", tilt_angle, 0.12).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.12)
		)
		btn.mouse_exited.connect(func():
			if active_tweens["tween"]:
				active_tweens["tween"].kill()
			btn.text = display_text
			feedback_label.text = ""
			active_tweens["tween"] = btn.create_tween().set_parallel(true)
			active_tweens["tween"].tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "rotation", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
		)
		
		# Sequential dynamic pop-in bounce animation for card drawing.
		var delay = card_index * 0.04
		btn.scale = Vector2(0.5, 0.5)
		btn.modulate.a = 0.0
		var pop_tw = btn.create_tween().set_parallel(true)
		pop_tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
		pop_tw.tween_property(btn, "modulate:a", 1.0, 0.2).set_delay(delay)
		
		card_index += 1

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
		if selected_enemy_idx >= 0 and selected_enemy_idx < active_enemies.size():
			var panel = active_enemies[selected_enemy_idx]["panel"]
			if panel:
				var hp_lbl = panel.get_node_or_null("VBox/HPLabel")
				var block_lbl = panel.get_node_or_null("VBox/BlockLabel")
				if hp_lbl: pulse_label(hp_lbl)
				if block_lbl: pulse_label(block_lbl)

func animate_feedback(text: String, is_turn_banner: bool = false) -> void:
	feedback_label.text = text
	feedback_label.pivot_offset = feedback_label.size / 2
	
	var tween = create_tween()
	if is_turn_banner:
		feedback_label.scale = Vector2(0.7, 0.7)
		feedback_label.modulate.a = 0.0
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
		tween.tween_property(feedback_label, "scale", Vector2(1.4, 1.4), 0.1)
		tween.tween_interval(0.3)
		tween.tween_property(feedback_label, "modulate:a", 0.8, 0.1)
		tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		feedback_label.scale = Vector2(1.1, 1.1)
		tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.08)

# Resolve transition after victory.
func _resolve_victory() -> void:
	if enemy_name == "Castle Boss":
		# RATIONALE: Pass true to start the post-Castle Boss transition in a fullscreen cutscene layout.
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
		}, "start", true)
		
		if not EventBus.dialogue_finished.is_connected(_on_castle_victory_finished):
			EventBus.dialogue_finished.connect(_on_castle_victory_finished)
		
	elif enemy_name == "Pack Leader":
		# RATIONALE: Faithful to docs/demo_narrative_flow.md - ends on a bittersweet, nostalgic note for Chapter 1.
		# Exposes the trace of his friend and leaves the future paths open-ended instead of forcing a final choice.
		DialogueSystem.start_dialogue({
			"start": {
				"text": "The fire is gone. The village is quiet now, Hilbert.",
				"speaker": "n.n.",
				"next": "win_step2"
			},
			"win_step2": {
				"text": "The fire is out. But the sky is turning white. The graphite lines of the village are losing definition.",
				"speaker": "Hilbert",
				"next": "win_step3"
			},
			"win_step3": {
				"text": "It's time to wake up, Hil. But don't worry. The drawings are still waiting. We never finished the propeller cart.",
				"speaker": "n.n.",
				"next": "win_step4"
			},
			"win_step4": {
				"text": "The dream shatters. The village and n.n. dissolve into falling graphite dust.",
				"next": "win_step5"
			},
			"win_step5": {
				# RATIONALE: Sensory details of classroom transition to ground waking up.
				"text": "You open your eyes. The air smells of dry summer grass cut by floor polish and chalk dust. The classroom is loud. The students are whispering. The professor is collecting the papers.",
				"dream_world": false,
				"next": "win_step6"
			},
			"win_step6": {
				"text": "Professor: Time's up, Hickman. Hand in your paper.",
				"speaker": "Professor",
				"next": "win_step7"
			},
			"win_step7": {
				# RATIONALE: Plant the final carved desk initials clue to align with the 9th fragment on the ending screen.
				"text": "You look down at your quiz sheet. At the bottom margin of the page, you notice a tiny propeller gear doodle. Beside the paper, carved into the dark wood of the desk, you see the faint, scarred initials: H.H. + L.G. 2024.",
				"next": "win_step8"
			},
			"win_step8": {
				"text": "You hand in the paper. You walk out of the classroom into the hallway.",
				"next": "win_step9"
			},
			"win_step9": {
				# RATIONALE: Specific, raw childhood details (2B lead smudge, rain on L.G.'s porch tin roof).
				"text": "You look at your hand, noticing a dark graphite smudge on your palm from the cheap 2B lead. In the silence of the hallway, the sound of rain hitting the window reminds you of water drumming on the tin roof under L.G.'s porch. His voice echoes:",
				"next": "win_step10"
			},
			"win_step10": {
				"text": "What if we could build a machine that flies to the sun? We will draw the blueprints tomorrow.",
				"next": "win_step11"
			},
			"win_step11": {
				# RATIONALE: Add the river-stone "dragon scale" pocket check.
				"text": "You stand still, looking at the rain-slicked window. He is gone. His chair next to you is vacant. But the pencil in your pocket is real, and your fingers trace the smooth river-stone 'dragon scale' he gave you.",
				"next": "win_step_demo_end"
			},
			"win_step_demo_end": {
				"text": "[System]: Before the Colours Fade. (Demo Ends)",
				"next": ""
			}
		}, "start", true)
		
		if not EventBus.dialogue_finished.is_connected(_on_pack_victory_finished):
			EventBus.dialogue_finished.connect(_on_pack_victory_finished)

# Bound listener callback to avoid signal reference leaks.
func _on_castle_victory_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_castle_victory_finished)
	SceneManager.transition_to_state("S_class")

# Bound listener callback to avoid signal reference leaks.
func _on_pack_victory_finished() -> void:
	# RATIONALE: Save choice as "demo" and check if all 9 memory flags are active for the secret ending.
	EventBus.dialogue_finished.disconnect(_on_pack_victory_finished)
	GlobalState.chosen_ending = "demo"
	GlobalState.set_flag("scratch_found", true) # Unlocks the final scratch memory slot
	
	# Check secret ending conditions.
	var all_9_flags = true
	var required_flags = [
		"bed_slept",
		"desk_searched",
		"guitar_played",
		"peer1_talked",
		"peer2_talked",
		"locker_searched",
		"quiz_started",
		"buff_confidence_active",
		"scratch_found"
	]
	for f in required_flags:
		if not GlobalState.has_flag(f):
			all_9_flags = false
			break
			
	if all_9_flags:
		# Set the flag to enable secret ending loop and key discovery in S_hall.
		GlobalState.set_flag("secret_ending_active", true)
		SceneManager.transition_to_state("S_hall")
	else:
		SceneManager.transition_to_state("S_ending")

# Helper to update button text while maintaining the selection indicator if hovered.
func _update_btn_text(btn: Button, text: String) -> void:
	if not btn: return
	if btn.is_hovered():
		btn.text = "▼ " + text
	else:
		btn.text = text

# Visual flash helper for damage impact.
func flash_red(node: Control) -> void:
	if not node: return
	var original_modulate = node.modulate
	var tween = create_tween()
	tween.tween_property(node, "modulate", Color(1.8, 0.4, 0.4, 1.0), 0.08)
	tween.tween_property(node, "modulate", original_modulate, 0.08)

# Visual flash helper for block gain.
func flash_blue(node: Control) -> void:
	if not node: return
	var original_modulate = node.modulate
	var tween = create_tween()
	tween.tween_property(node, "modulate", Color(0.4, 0.7, 1.8, 1.0), 0.08)
	tween.tween_property(node, "modulate", original_modulate, 0.08)

# Slides character panels into the screen when combat starts.
func _animate_combat_entry() -> void:
	var p_panel = $UI/PlayerPanel
	if p_panel:
		var target_x = p_panel.position.x
		p_panel.position.x = -320
		var p_tween = create_tween()
		p_tween.tween_property(p_panel, "position:x", target_x, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	var e_panel = $UI/EnemyPanel
	if e_panel:
		var target_x = e_panel.position.x
		e_panel.position.x = 1180
		var e_tween = create_tween()
		e_tween.tween_property(e_panel, "position:x", target_x, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Creates the Slay the Spire style Energy Orb programmatically.
func _create_energy_orb() -> void:
	energy_orb = Panel.new()
	energy_orb.custom_minimum_size = Vector2(64, 64)
	energy_orb.position = Vector2(90, 480) # Next to the cards layout
	
	# Transparent stylebox since CombatVisuals.gd renders the sketchy orb backgrounds
	var empty_style = StyleBoxEmpty.new()
	energy_orb.add_theme_stylebox_override("panel", empty_style)
	$UI.add_child(energy_orb)
	
	energy_orb_label = Label.new()
	energy_orb_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	energy_orb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_orb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_orb_label.text = "3/3"
	energy_orb_label.add_theme_font_size_override("font_size", 18)
	# High contrast bold text with a dark drop shadow for maximum readability over sketchy rays
	energy_orb_label.add_theme_color_override("font_color", Color.WHITE)
	energy_orb_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.12, 0.15, 1.0))
	energy_orb_label.add_theme_constant_override("shadow_offset_x", 1)
	energy_orb_label.add_theme_constant_override("shadow_offset_y", 1)
	energy_orb_label.add_theme_constant_override("shadow_outline_size", 3)
	energy_orb.add_child(energy_orb_label)

# Triggered when n.n.'s introduction dialogue completes.
# Sets up step 1 of the guided tutorial.
func _on_intro_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_intro_dialogue_finished)
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		tutorial_step = 1
		DialogueSystem.start_dialogue({
			"start": {
				"text": "Look at your cards at the bottom. Strike deals damage, and Defend blocks enemy attacks. Notice the Castle Boss intends to attack you for 6 damage this turn!",
				"speaker": "n.n.",
				"next": "tut_2"
			},
			"tut_2": {
				"text": "Try playing a Strike card first to damage the Castle Boss.",
				"speaker": "n.n.",
				"next": ""
			}
		}, "start")

# Prompts the player to play Defend next.
func _trigger_tutorial_step_2() -> void:
	DialogueSystem.start_dialogue({
		"start": {
			"text": "Great! Now play a Defend card to protect yourself from the incoming attack.",
			"speaker": "n.n.",
			"next": ""
		}
	}, "start")

# Prompts the player to end their turn.
func _trigger_tutorial_step_3() -> void:
	DialogueSystem.start_dialogue({
		"start": {
			"text": "Perfect! You have 1 energy left. You cannot play any more cards because both Strike and Defend cost 1 energy. Press 'End Turn' to let the enemy act.",
			"speaker": "n.n.",
			"next": ""
		}
	}, "start")

# Welcomes the player to turn 2 and explains advanced actions.
func _trigger_tutorial_turn_2() -> void:
	DialogueSystem.start_dialogue({
		"start": {
			"text": "Good job! Your block absorbed the damage. You also have a 'Reroll' button to replace your hand for free once per round, and a 'Retain' button to save a card for next turn. Use them wisely.",
			"speaker": "n.n.",
			"next": "tut_end"
		},
		"tut_end": {
			"text": "Let's finish this fight!",
			"speaker": "n.n.",
			"next": ""
		}
	}, "start")
	GlobalState.set_flag("tutorial_done", true)

# -----------------------------------------------------------------------------
# WAVE STAGES & PROGRAMMATIC SPATIAL LAYOUT HELPER METHODS
# -----------------------------------------------------------------------------

# RATIONALE: Defines the 3-wave encounter sequence data structures for Castle Boss & Pack Leader battles.
func _init_stages_data() -> void:
	stages_data.clear()
	if enemy_name == "Castle Boss":
		# Castle Boss / Grassy Field Level Waves.
		stages_data = [
			[
				{"name": "Castle Boss", "hp": 30, "max_hp": 30, "phase1_atk": 4, "phase2_atk": 6, "phase3_atk": 8, "defend_val": 4}
			],
			[
				{"name": "Sentry", "hp": 20, "max_hp": 20, "phase1_atk": 5, "phase2_atk": 7, "phase3_atk": 9, "defend_val": 4},
				{"name": "Sentry", "hp": 20, "max_hp": 20, "phase1_atk": 5, "phase2_atk": 7, "phase3_atk": 9, "defend_val": 4}
			],
			[
				{"name": "Castle Boss", "hp": 60, "max_hp": 60, "phase1_atk": 6, "phase2_atk": 9, "phase3_atk": 13, "defend_val": 5}
			]
		]
	else:
		# Pack Leader / Burning Village Level Waves.
		stages_data = [
			[
				{"name": "Feral Wolf", "hp": 20, "max_hp": 20, "phase1_atk": 5, "phase2_atk": 7, "phase3_atk": 9, "defend_val": 4},
				{"name": "Feral Wolf", "hp": 20, "max_hp": 20, "phase1_atk": 5, "phase2_atk": 7, "phase3_atk": 9, "defend_val": 4}
			],
			[
				{"name": "Beta Wolf", "hp": 35, "max_hp": 35, "phase1_atk": 6, "phase2_atk": 8, "phase3_atk": 11, "defend_val": 5}
			],
			[
				{"name": "Pack Leader", "hp": 60, "max_hp": 60, "phase1_atk": 7, "phase2_atk": 10, "phase3_atk": 14, "defend_val": 6}
			]
		]

# RATIONALE: Spawns sprites, duplicated panels, and target-select overlays for a specific stage wave index.
func _start_wave(stage_idx: int) -> void:
	current_stage_idx = stage_idx
	
	# Clean up any existing nodes from a previous wave stage.
	for enemy in active_enemies:
		if enemy.get("sprite") and is_instance_valid(enemy["sprite"]):
			enemy["sprite"].queue_free()
		if enemy.get("panel") and is_instance_valid(enemy["panel"]):
			enemy["panel"].queue_free()
		if enemy.get("target_btn") and is_instance_valid(enemy["target_btn"]):
			enemy["target_btn"].queue_free()
			
	active_enemies.clear()
	
	var wave_enemies = stages_data[stage_idx]
	var enemy_count = wave_enemies.size()
	
	# Determine X coordinates on the screen based on total enemy count to space them out side-by-side.
	var x_coords = []
	if enemy_count == 1:
		x_coords = [850]
	elif enemy_count == 2:
		x_coords = [750, 950]
	elif enemy_count == 3:
		x_coords = [700, 850, 1000]
		
	# Instantiate each wave enemy's sprite, stat panel, and click target.
	for i in range(enemy_count):
		var conf = wave_enemies[i]
		var enemy_data = {
			"name": conf["name"],
			"hp": conf["hp"],
			"max_hp": conf["max_hp"],
			"block": conf.get("block", 0),
			"intent": conf.get("intent", "Idle"),
			"intent_value": conf.get("intent_value", 0),
			"phase1_atk": conf["phase1_atk"],
			"phase2_atk": conf["phase2_atk"],
			"phase3_atk": conf["phase3_atk"],
			"defend_val": conf["defend_val"],
			"smooth_hp_ratio": 1.0,
			"sprite": null,
			"panel": null,
			"target_btn": null
		}
		
		# Programmatically spawn the enemy sprite facing left (flipped).
		var sprite = Sprite2D.new()
		sprite.texture = load("res://Assets/Sprites/Monster.png")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(5.0, 5.0)
		sprite.position = Vector2(x_coords[i], 360)
		sprite.flip_h = true
		add_child(sprite)
		enemy_data["sprite"] = sprite
		
		# Programmatically duplicate the template EnemyPanel for clean sienna styling layout.
		var panel = $UI/EnemyPanel.duplicate()
		panel.visible = true
		panel.position = Vector2(x_coords[i] - 100, 130)
		panel.size = Vector2(200, 100)
		$UI.add_child(panel)
		enemy_data["panel"] = panel
		
		# Programmatically spawn a transparent overlay button covering the sprite to detect target clicks.
		var target_btn = Button.new()
		target_btn.size = Vector2(160, 240)
		target_btn.position = Vector2(x_coords[i] - 80, 240)
		var empty_style = StyleBoxEmpty.new()
		target_btn.add_theme_stylebox_override("normal", empty_style)
		target_btn.add_theme_stylebox_override("hover", empty_style)
		target_btn.add_theme_stylebox_override("pressed", empty_style)
		target_btn.add_theme_stylebox_override("focus", empty_style)
		target_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		target_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(target_btn)
		enemy_data["target_btn"] = target_btn
		
		var idx_closure = i
		target_btn.pressed.connect(func(): _on_enemy_clicked(idx_closure))
		
		active_enemies.append(enemy_data)
		
	selected_enemy_idx = 0
	_auto_select_alive_enemy()
	update_ui()

# RATIONALE: Updates targeted enemy index on manual click.
func _on_enemy_clicked(idx: int) -> void:
	# RATIONALE: Block selections if a dialogue bubble or panel is currently playing.
	if DialogueSystem.is_active:
		return
	if idx >= 0 and idx < active_enemies.size() and active_enemies[idx]["hp"] > 0:
		selected_enemy_idx = idx
		animate_feedback("Targeted " + active_enemies[idx]["name"] + ".")
		update_ui()

# RATIONALE: Moves targeting to the first alive enemy if current target falls to 0 HP.
func _auto_select_alive_enemy() -> void:
	if selected_enemy_idx >= 0 and selected_enemy_idx < active_enemies.size():
		if active_enemies[selected_enemy_idx]["hp"] > 0:
			return
	for idx in range(active_enemies.size()):
		if active_enemies[idx]["hp"] > 0:
			selected_enemy_idx = idx
			return

# RATIONALE: Verifies if all active enemies of the current stage wave are defeated.
func _check_wave_victory() -> bool:
	for enemy in active_enemies:
		if enemy["hp"] > 0:
			return false
	return true

# RATIONALE: Transitions to the next wave, triggering standard PLAYER_START cleanup.
func _transition_to_next_wave() -> void:
	_transitioning_wave = true
	animate_feedback("Wave Defeated! Moving to next stage...", true)
	
	var timer = get_tree().create_timer(1.0)
	await timer.timeout
	
	_start_wave(current_stage_idx + 1)
	_transitioning_wave = false
	
	transition_to(State.PLAYER_START)

# RATIONALE: Programmatically builds a sienna sketch style top bar for wave progression.
func _create_top_bar() -> void:
	top_bar = Panel.new()
	top_bar.name = "TopBar"
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1152, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.93, 0.88, 0.85)
	style.border_width_bottom = 2
	style.border_color = Color(0.12, 0.12, 0.15, 0.25)
	top_bar.add_theme_stylebox_override("panel", style)
	$UI.add_child(top_bar)
	
	progress_label = Label.new()
	progress_label.position = Vector2(20, 10)
	progress_label.size = Vector2(200, 30)
	progress_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	progress_label.add_theme_font_size_override("font_size", 16)
	top_bar.add_child(progress_label)
	
	gold_label = Label.new()
	gold_label.position = Vector2(300, 10)
	gold_label.size = Vector2(200, 30)
	gold_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	gold_label.add_theme_font_size_override("font_size", 16)
	top_bar.add_child(gold_label)
	
	deck_booklet_btn = Button.new()
	deck_booklet_btn.name = "DeckBookletBtn"
	deck_booklet_btn.text = "Deck Booklet"
	deck_booklet_btn.position = Vector2(950, 10)
	deck_booklet_btn.size = Vector2(150, 30)
	
	var btn_style_normal = StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.92, 0.90, 0.84, 0.8)
	btn_style_normal.border_width_left = 1
	btn_style_normal.border_width_top = 1
	btn_style_normal.border_width_right = 1
	btn_style_normal.border_width_bottom = 1
	btn_style_normal.border_color = Color(0.12, 0.12, 0.15, 0.25)
	
	var btn_style_hover = btn_style_normal.duplicate()
	btn_style_hover.bg_color = Color(0.97, 0.95, 0.90, 0.9)
	btn_style_hover.border_color = Color(0.65, 0.25, 0.15, 0.5)
	
	deck_booklet_btn.add_theme_stylebox_override("normal", btn_style_normal)
	deck_booklet_btn.add_theme_stylebox_override("hover", btn_style_hover)
	deck_booklet_btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	deck_booklet_btn.add_theme_color_override("font_hover_color", Color(0.65, 0.25, 0.15, 1.0))
	
	deck_booklet_btn.pressed.connect(_toggle_deck_viewer)
	top_bar.add_child(deck_booklet_btn)

# RATIONALE: Creates a booklet modal popup rendering on a separate high CanvasLayer (92),
# ensuring input events are never captured when the panel is set to invisible.
func _create_deck_viewer() -> void:
	deck_viewer_layer = CanvasLayer.new()
	deck_viewer_layer.layer = 92
	add_child(deck_viewer_layer)
	
	deck_viewer_panel = Panel.new()
	deck_viewer_panel.name = "DeckViewerPanel"
	deck_viewer_panel.position = Vector2(200, 100)
	deck_viewer_panel.size = Vector2(752, 450)
	deck_viewer_panel.visible = false
	deck_viewer_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.93, 0.88, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.65, 0.25, 0.15, 0.8)
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 5
	deck_viewer_panel.add_theme_stylebox_override("panel", style)
	deck_viewer_layer.add_child(deck_viewer_panel)
	
	var title = Label.new()
	title.text = "Deck Booklet"
	title.position = Vector2(20, 15)
	title.size = Vector2(200, 30)
	title.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0))
	title.add_theme_font_size_override("font_size", 20)
	deck_viewer_panel.add_child(title)
	
	var tab_hbox = HBoxContainer.new()
	tab_hbox.position = Vector2(250, 15)
	tab_hbox.size = Vector2(300, 30)
	deck_viewer_panel.add_child(tab_hbox)
	
	for tab_name in ["Deck", "Draw", "Discard"]:
		var btn = Button.new()
		btn.text = tab_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _render_deck_grid(tab_name))
		
		var tab_style = StyleBoxFlat.new()
		tab_style.bg_color = Color(0.92, 0.90, 0.84, 0.8)
		tab_style.border_width_left = 1
		tab_style.border_width_top = 1
		tab_style.border_width_right = 1
		tab_style.border_width_bottom = 1
		tab_style.border_color = Color(0.12, 0.12, 0.15, 0.25)
		
		btn.add_theme_stylebox_override("normal", tab_style)
		btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
		tab_hbox.add_child(btn)
		
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(700, 15)
	close_btn.size = Vector2(30, 30)
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.3, 0.3, 0.8)
	close_style.border_width_left = 1
	close_style.border_width_top = 1
	close_style.border_width_right = 1
	close_style.border_width_bottom = 1
	close_style.border_color = Color(0.12, 0.12, 0.15, 0.25)
	
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(_toggle_deck_viewer)
	deck_viewer_panel.add_child(close_btn)
	
	deck_scroll_container = ScrollContainer.new()
	deck_scroll_container.position = Vector2(20, 60)
	deck_scroll_container.size = Vector2(712, 370)
	deck_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	deck_viewer_panel.add_child(deck_scroll_container)
	
	deck_grid = GridContainer.new()
	deck_grid.columns = 4
	deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_grid.add_theme_constant_override("h_separation", 15)
	deck_grid.add_theme_constant_override("v_separation", 15)
	deck_scroll_container.add_child(deck_grid)

# RATIONALE: Renders card buttons within the deck booklet scroll grid.
func _render_deck_grid(pile_name: String) -> void:
	current_viewer_pile = pile_name
	for child in deck_grid.get_children():
		child.queue_free()
		
	var pile = []
	if pile_name == "Deck":
		pile = GlobalState.master_deck
	elif pile_name == "Draw":
		pile = DeckManager.draw_pile
	elif pile_name == "Discard":
		pile = DeckManager.discard_pile
		
	for card in pile:
		var card_panel = Panel.new()
		card_panel.custom_minimum_size = Vector2(160, 100)
		
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.96, 0.95, 0.92, 1.0)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		
		var border_color = Color(0.4, 0.4, 0.4, 0.6)
		if card.card_type == "Attack":
			border_color = Color(0.8, 0.3, 0.3, 0.6)
		elif card.card_type == "Defense":
			border_color = Color(0.3, 0.5, 0.8, 0.6)
		elif card.card_type == "Special":
			border_color = Color(0.8, 0.55, 0.2, 0.6)
		panel_style.border_color = border_color
		
		card_panel.add_theme_stylebox_override("panel", panel_style)
		deck_grid.add_child(card_panel)
		
		var name_lbl = Label.new()
		name_lbl.text = card.card_name + " (" + str(card.energy_cost) + "E)"
		name_lbl.position = Vector2(10, 10)
		name_lbl.size = Vector2(140, 20)
		name_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
		name_lbl.add_theme_font_size_override("font_size", 14)
		card_panel.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = card.description
		desc_lbl.position = Vector2(10, 40)
		desc_lbl.size = Vector2(140, 50)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		card_panel.add_child(desc_lbl)

# RATIONALE: Toggles visibility of the booklet deck viewer panel.
func _toggle_deck_viewer() -> void:
	if not deck_viewer_panel:
		return
	deck_viewer_panel.visible = not deck_viewer_panel.visible
	if deck_viewer_panel.visible:
		_render_deck_grid("Deck")

# RATIONALE: Routes taking damage to a specific active wave enemy.
func damage_enemy(idx: int, amount: int) -> void:
	if idx < 0 or idx >= active_enemies.size():
		return
	var enemy = active_enemies[idx]
	if enemy["hp"] <= 0:
		return
		
	var actual_dmg = amount
	
	# Apply boss protection mechanic in Pack Leader fight if confidence is missing.
	if enemy["name"] == "Pack Leader" and not GlobalState.has_flag("buff_confidence_active"):
		actual_dmg = 1
		amount = 1
		animate_feedback("The Pack Leader laughs. Your attacks don't reach it.")
		
	if enemy["block"] >= actual_dmg:
		enemy["block"] -= actual_dmg
		actual_dmg = 0
	else:
		actual_dmg -= enemy["block"]
		enemy["block"] = 0
		enemy["hp"] = max(0, enemy["hp"] - actual_dmg)
		
	if enemy["panel"]:
		shake_node(enemy["panel"])
		flash_red(enemy["panel"])
		
	animate_feedback("Hilbert deals " + str(amount) + " damage to " + enemy["name"] + ".")
	update_stats_pulsed(false, true)
	
	if enemy["hp"] <= 0:
		animate_feedback(enemy["name"] + " is defeated!")
		if enemy["sprite"]:
			enemy["sprite"].visible = false
		if enemy["panel"]:
			enemy["panel"].visible = false
		if enemy["target_btn"]:
			enemy["target_btn"].visible = false
			
		_auto_select_alive_enemy()

# RATIONALE: Routes block clearing to a specific active wave enemy.
func clear_enemy_block(idx: int) -> void:
	if idx < 0 or idx >= active_enemies.size():
		return
	active_enemies[idx]["block"] = 0
	animate_feedback("Heavy Slash breaks through the defense of " + active_enemies[idx]["name"] + "!")
	update_stats_pulsed(false, true)
