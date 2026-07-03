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

# Visual Nodes - all declared in the .tscn, grabbed here at scene ready.
@onready var hand_container = $UI/HandPanel
@onready var end_turn_btn = $UI/ActionPanel/VBox/EndTurnButton
@onready var reroll_btn = $UI/ActionPanel/VBox/RerollButton
@onready var ultimate_btn = $UI/ActionPanel/VBox/UltimateButton
@onready var retain_btn = $UI/ActionPanel/VBox/RetainButton
@onready var feedback_label = $UI/FeedbackLabel
@onready var energy_orb: Panel = $UI/EnergyOrb
@onready var energy_orb_label: Label = $UI/EnergyOrb/EnergyOrbLabel
@onready var top_bar: Panel = $UI/TopBar
@onready var progress_label: Label = $UI/TopBar/ProgressLabel
@onready var gold_label: Label = $UI/TopBar/GoldLabel
@onready var deck_booklet_btn: Button = $UI/DeckBookletBtn
@onready var deck_viewer_layer: CanvasLayer = $DeckViewerLayer
@onready var deck_viewer_panel: Panel = $DeckViewerLayer/DeckViewerPanel
@onready var deck_scroll_container: ScrollContainer = $DeckViewerLayer/DeckViewerPanel/DeckScrollContainer
@onready var deck_grid: GridContainer = $DeckViewerLayer/DeckViewerPanel/DeckScrollContainer/DeckGrid
@onready var player_sprite: Sprite2D = $UI/PlayerSprite

# Retain mode flag - when true, the next card click retains instead of plays.
var _retain_mode_active: bool = false

# Current active deck viewer tab: "Deck", "Draw", or "Discard".
var current_viewer_pile: String = "Deck"
var _transitioning_wave: bool = false # Gate to prevent double-clearing of wave states

# Programmatic wave stages, targeting, and sprite variables.
var current_stage_idx: int = 0
var stages_data: Array = []
var active_enemies: Array = []
var selected_enemy_idx: int = 0

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


func _build_hud_panel(panel: Panel, is_player: bool) -> void:
	# Clear out old styling instantly so duplicate() doesn't copy dead nodes
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
		
	# Clean, sleek, translucent beige glass panel to match the rest of the UI
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.93, 0.88, 0.9) # Warm beige, high opacity
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.65, 0.25, 0.15, 0.8) # Sienna border (matches Deck Viewer)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.1)
	style.shadow_size = 2
	style.shadow_offset = Vector2(2, 2)
	panel.add_theme_stylebox_override("panel", style)
	
	# Very compact, clean panel size with no wasted space
	panel.custom_minimum_size = Vector2(220, 75)
	panel.size = Vector2(220, 75)
	
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0)) # Dark text
	name_lbl.add_theme_font_size_override("font_size", 12)
	
	var hp_lbl = Label.new()
	hp_lbl.name = "HPLabelText"
	hp_lbl.text = "HP"
	hp_lbl.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0)) # Darker red text
	hp_lbl.add_theme_font_size_override("font_size", 10)
	
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.show_percentage = false
	hp_bar.size = Vector2(80, 16) # Thinner horizontally
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.18, 0.8) # Dark inset background
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.65, 0.25, 0.15, 0.5) # Sienna subtle border matching HUD
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	
	var fg_style = StyleBoxFlat.new()
	if is_player:
		fg_style.bg_color = Color(0.35, 0.7, 0.35, 1.0) # Pleasant green
	else:
		fg_style.bg_color = Color(0.8, 0.35, 0.35, 1.0) # Pleasant red
	fg_style.corner_radius_top_left = 3
	fg_style.corner_radius_top_right = 3
	fg_style.corner_radius_bottom_left = 3
	fg_style.corner_radius_bottom_right = 3
	
	hp_bar.add_theme_stylebox_override("background", bg_style)
	hp_bar.add_theme_stylebox_override("fill", fg_style)
	
	var block_icon = TextureRect.new()
	block_icon.name = "BlockIcon"
	block_icon.size = Vector2(20, 20)
	block_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	block_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	block_icon.visible = true
	# Fixed correct texture path for the shield icon
	if FileAccess.file_exists("res://Assets/UI/block_icon_16x16 (armor readout shield).png"):
		block_icon.texture = load("res://Assets/UI/block_icon_16x16 (armor readout shield).png")
	else:
		block_icon.modulate = Color(0,0,0,0) # Hide if asset missing
	
	var block_lbl = Label.new()
	block_lbl.name = "BlockLabel"
	block_lbl.add_theme_color_override("font_color", Color(0.2, 0.4, 0.8, 1.0)) # Darker blue text
	block_lbl.add_theme_font_size_override("font_size", 10)
	block_lbl.visible = false # Hidden if 0
	
	var intent_icon = TextureRect.new()
	intent_icon.name = "IntentIcon"
	intent_icon.size = Vector2(16, 16)
	intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var intent_lbl = Label.new()
	intent_lbl.name = "IntentLabel"
	intent_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0)) # Dark text
	intent_lbl.add_theme_font_size_override("font_size", 12)
	
	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.size = Vector2(48, 48)
	portrait.position = Vector2(10, 13) # Perfect fit for the 75px height
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if is_player:
		if FileAccess.file_exists("res://Assets/Sprites/DreamHilbertSideways icon.png"):
			portrait.texture = load("res://Assets/Sprites/DreamHilbertSideways icon.png")
		name_lbl.text = "HILBERT"
	else:
		if FileAccess.file_exists("res://Assets/Sprites/PACKLEADER.png"):
			portrait.texture = load("res://Assets/Sprites/PACKLEADER.png")
			
	panel.add_child(portrait)
	
	# Clean layout for 220x75
	name_lbl.position = Vector2(65, 8)
	hp_lbl.position = Vector2(65, 30)
	hp_bar.position = Vector2(85, 30)
	block_icon.position = Vector2(65, 50)
	block_lbl.position = Vector2(90, 52)
	intent_icon.position = Vector2(175, 8) # Icon to the left
	intent_lbl.position = Vector2(195, 8) # Number to the right
		
	panel.add_child(name_lbl)
	panel.add_child(hp_lbl)
	panel.add_child(hp_bar)
	panel.add_child(block_icon)
	panel.add_child(block_lbl)
	panel.add_child(intent_icon)
	panel.add_child(intent_lbl)

func _ready() -> void:
	
	if player_sprite:
		var p_tex = load("res://Assets/Sprites/Hilbert_dream_battleIdle-Sheet_7x1.png")
		if p_tex:
			player_sprite.texture = p_tex
			player_sprite.hframes = 7
			player_sprite.vframes = 1
			# Scale down because old sprite was 128x128, new is 200x200
			player_sprite.scale = Vector2(1, 1)
	# Set a global theme font for all UI elements to PixelifySans per user request
	var global_theme = Theme.new()
	var main_font = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")
	if main_font:
		global_theme.default_font = main_font
	for child in $UI.get_children():
		if child is Control:
			child.theme = global_theme
	
	# Initialize wave stages data structures
	_init_stages_data()

	# All UI nodes are declared in the .tscn.
	# Nothing to spawn - just connect signals and wire the deck tab buttons.
	_connect_deck_tabs()

	# EnemyTemplate handles visibility internally when duplicated.
	if has_node("UI/EnemyTemplate"):
		$UI/EnemyTemplate.visible = false

	# HandPanel children can be cleared safely since cards are spawned per-draw.
	for child in $UI/HandPanel.get_children():
		child.queue_free()

	# FeedbackLabel color - it's baked into the .tscn but set here too for consistency.
	$UI/FeedbackLabel.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))

	# Action button hover tweens (runtime-only, not storable in .tscn).
	for btn in [end_turn_btn, reroll_btn, ultimate_btn, retain_btn]:
		if not btn:
			continue
			
		_style_action_button(btn)
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2)
		btn.mouse_entered.connect(func():
			var tw = btn.create_tween().set_parallel(true)
			tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
		)
		btn.mouse_exited.connect(func():
			var tw = btn.create_tween().set_parallel(true)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		)

	# EnergyOrb is declared in .tscn; no spawning needed.

	# Entry animations: slide character panels from off-screen into their layout position.
	call_deferred("_animate_combat_entry")
	
	if enemy_name == "Castle Boss":
		# Play the ambient gears looping sound for the Castle Boss level
		# EventBus.play_sound.emit("gears_loop")
		# EventBus.play_sound.emit("amb_nn_propeller")
		pass
	elif enemy_name == "Pack Leader":
		# EventBus.play_sound.emit("amb_nn_propeller")
		pass

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

func _connect_deck_tabs() -> void:
	# RATIONALE: The DeckViewerPanel tab buttons and close button are now in .tscn
	# with signal connections wired to _on_deck_tab_pressed / _toggle_deck_viewer.
	# This function is a no-op placeholder in case manual connection is needed later.
	pass

func _on_deck_tab_pressed(pile_name: String) -> void:
	# Routes deck viewer tab button presses to the grid renderer.
	_render_deck_grid(pile_name)

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
			EventBus.stop_sound.emit("gears_loop")
			EventBus.stop_sound.emit("amb_nn_propeller")
			EventBus.play_sound.emit("victory_chord")
			animate_feedback("VICTORY", true)
			
			var banner_bg = $UI.get_node_or_null("FeedbackBannerBg")
			if banner_bg:
				var vic_tex = "res://Assets/Combat/UI/victory_banner_240x48.png"
				if FileAccess.file_exists(vic_tex):
					banner_bg.texture = load(vic_tex)
					banner_bg.custom_minimum_size = Vector2(360, 72)
					banner_bg.position = feedback_label.position + (feedback_label.size / 2.0) - Vector2(180, 36)
					banner_bg.visible = true
					banner_bg.modulate.a = 1.0
			
			# Reset cache since fight is complete.
			ShiftManager.clear_cache()
			
			if enemy_name == "Castle Boss":
				SceneManager.stop_sfx("gears_loop")
			
			# Trigger victory sequence.
			_resolve_victory()
			
		State.DEFEAT:
			set_buttons_disabled(true)
			EventBus.stop_sound.emit("gears_loop")
			EventBus.stop_sound.emit("amb_nn_propeller")
			EventBus.play_sound.emit("defeat_strike")
			animate_feedback("DEFEATED", true)
			
			var banner_bg = $UI.get_node_or_null("FeedbackBannerBg")
			if banner_bg:
				var def_tex = "res://Assets/Combat/UI/defeat_banner_240x48.png"
				if FileAccess.file_exists(def_tex):
					banner_bg.texture = load(def_tex)
					banner_bg.custom_minimum_size = Vector2(360, 72)
					banner_bg.position = feedback_label.position + (feedback_label.size / 2.0) - Vector2(180, 36)
					banner_bg.visible = true
					banner_bg.modulate.a = 1.0
			
			if enemy_name == "Castle Boss":
				SceneManager.stop_sfx("gears_loop")
			
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
		EventBus.play_sound.emit("burn_tick")
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
				EventBus.play_sound.emit("player_hit")
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
		EventBus.play_sound.emit("error")
		animate_feedback("Not enough energy!")
		return
		
	player_energy -= card.energy_cost
	EventBus.play_sound.emit("card_lift")
	
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
		EventBus.play_sound.emit("burn_tick")
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

# Ultimate Attack option button.
func _on_ultimate_pressed() -> void:
	# RATIONALE: Block action while dialogue is active.
	if DialogueSystem.is_active:
		return
	if GlobalState.dimension_charge >= 3:
		# Add a blinding white flash and violent screen shake for the ultimate.
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
			var offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
			shake_tw.tween_property(self, "position", original_pos + offset, 0.05)
		shake_tw.tween_property(self, "position", original_pos, 0.05)
		
		# Play multiple heavy SFX for the Ultimate attack!
		EventBus.play_sound.emit("double_slice")
		EventBus.play_sound.emit("metal_clamp")
		
		await shake_tw.finished
		flash.queue_free()
		
		# Execute the ultimate attack!
		GlobalState.dimension_charge -= 3
		var current_enemy = active_enemies[selected_enemy_idx]
		
		# Deal 20 massive damage and gain 10 block.
		var ult_damage = 20
		var ult_block = 10
		
		current_enemy["hp"] -= ult_damage
		player_block += ult_block
		
		animate_feedback("ULTIMATE! 20 Damage & 10 Block!")
		
		if current_enemy["hp"] <= 0:
			current_enemy["hp"] = 0
			animate_feedback(current_enemy["name"] + " is defeated!")
			if current_enemy["sprite"]:
				current_enemy["sprite"].visible = false
			if current_enemy["panel"]:
				current_enemy["panel"].visible = false
			if current_enemy["target_btn"]:
				current_enemy["target_btn"].visible = false
			_auto_select_alive_enemy()
			
		update_ui()
		# Play impact animation on the enemy sprite if it's still alive/visible
		if is_instance_valid(current_enemy["sprite"]) and current_enemy["sprite"].visible:
			var sprite_tw = create_tween()
			sprite_tw.tween_property(current_enemy["sprite"], "modulate", Color(2.0, 0.0, 0.0), 0.1)
			sprite_tw.tween_property(current_enemy["sprite"], "modulate", Color(1.0, 1.0, 1.0), 0.2)

		# Check for wave victory
		if _check_wave_victory():
			if current_stage_idx < stages_data.size() - 1:
				_transition_to_next_wave()
			else:
				transition_to(State.VICTORY)


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
	EventBus.play_sound.emit("end_turn")
	transition_to(State.PLAYER_END)

# Update screen widgets.
func update_ui() -> void:
	# Show active buffs near the player's name.
	var buff_text = ""
	if GlobalState.has_flag("buff_confidence_active"):
		buff_text = " [Confidence: +100% DMG]"
	elif GlobalState.has_flag("buff_courage_active"):
		buff_text = " [Courage: +50% DMG]"
	
	var p_name = $UI/PlayerPanel.get_node_or_null("NameLabel")
	var p_hp_bar = $UI/PlayerPanel.get_node_or_null("HPBar")
	var p_block_lbl = $UI/PlayerPanel.get_node_or_null("BlockLabel")
	var p_block_icon = $UI/PlayerPanel.get_node_or_null("BlockIcon")
	
	if p_name: p_name.text = "HILBERT" # Buff text removed to prevent overflow
	if p_hp_bar:
		p_hp_bar.max_value = player_max_hp
		p_hp_bar.value = player_hp
	if p_block_lbl: p_block_lbl.text = str(player_block)
	if p_block_icon: p_block_icon.visible = player_block > 0
	if p_block_lbl: p_block_lbl.visible = player_block > 0

	
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
			var name_lbl = panel.get_node_or_null("NameLabel")
			var hp_bar = panel.get_node_or_null("HPBar")
			var block_lbl = panel.get_node_or_null("BlockLabel")
			var block_icon = panel.get_node_or_null("BlockIcon")
			
			var intent_lbl = panel.get_node_or_null("IntentLabel")
			var intent_icon = panel.get_node_or_null("IntentIcon")
			
			if name_lbl:
				var name_text = enemy["name"].to_upper()
				if idx == selected_enemy_idx:
					name_lbl.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Sienna targeted
				else:
					name_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0)) # Dark text default
				name_lbl.text = name_text
				
			if hp_bar:
				hp_bar.max_value = enemy["max_hp"]
				hp_bar.value = enemy["hp"]
				
			if block_lbl:
				block_lbl.text = str(enemy["block"])
				block_lbl.visible = enemy["block"] > 0
			if block_icon:
				block_icon.visible = true # Always visible now
				
			if intent_lbl:
				if enemy["hp"] <= 0:
					intent_lbl.text = "Defeated"
					intent_icon.visible = false
					if enemy["name"] == "Castle Boss" or enemy["name"] == "Pack Leader":
						EventBus.stop_sound.emit("gears_loop")
						EventBus.stop_sound.emit("amb_nn_propeller")
					if enemy.get("arrow") and is_instance_valid(enemy["arrow"]):
						enemy["arrow"].visible = false
						if enemy["arrow"].has_meta("tween") and is_instance_valid(enemy["arrow"].get_meta("tween")):
							enemy["arrow"].get_meta("tween").kill()
				else:
					var icon_file = ""
					if enemy["intent"] == "Attack":
						intent_lbl.text = str(enemy["intent_value"])
						icon_file = "res://Assets/UI/attack_indicator_16x16.png"
					elif enemy["intent"] == "Defend":
						intent_lbl.text = str(enemy["intent_value"])
						icon_file = "res://Assets/UI/defend_indicator_16x16.png"
					else:
						intent_lbl.text = ""
						icon_file = "res://Assets/UI/special_indicator_16x16.png"
						
					if intent_icon:
						if icon_file != "" and FileAccess.file_exists(icon_file):
							intent_icon.texture = load(icon_file)
							intent_icon.visible = true
						else:
							intent_icon.visible = false
					intent_lbl.visible = (intent_lbl.text != "")
	
	# Ultimate button logic in Pack Leader fight (or any fight now).
	# Enable the ultimate button only if we have full charge.
	if ultimate_btn:
		ultimate_btn.visible = true
		ultimate_btn.disabled = GlobalState.dimension_charge < 3
		ultimate_btn.text = "Ultimate Attack"
		
	# Update the True Shift Gauge (Now Ultimate Gauge) in the center of the screen
	var true_gauge = $UI.get_node_or_null("UltimateGauge")
	if true_gauge:
		true_gauge.value = 100 # Force it to draw the full texture
		var charge_clamped = clampi(GlobalState.dimension_charge, 0, 3)
		var gauge_path = "res://Assets/UI/shift_gauge_bar_" + str(charge_clamped) + "_120x16.png"
		if FileAccess.file_exists(gauge_path):
			true_gauge.texture_progress = load(gauge_path)
		
	# Reroll button: disabled if used this round.
	reroll_btn.disabled = not DeckManager.can_reroll
	
	# Retain button: disabled if used this round or in retain mode.
	if retain_btn:
		retain_btn.disabled = not DeckManager.can_retain or _retain_mode_active

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
		
	var hand_size = DeckManager.hand.size()
	var card_index = 0
	# Squish overlapping cards slightly if there are many
	var card_spacing = min(150.0, 700.0 / max(1.0, float(hand_size)))
	var combat_font = load("res://Assets/Fonts/VT323-Regular.ttf")
	var card_font_main = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")
	
	for card in DeckManager.hand:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(98, 140)
		btn.size = Vector2(98, 140)
		btn.text = "" 
		
		var card_img_name = card.card_name.to_lower().replace(" ", "_")
		var illustration_path = "res://Assets/Cards/" + card_img_name + ".png"
		
		var style_normal = StyleBoxTexture.new()
		if FileAccess.file_exists(illustration_path):
			style_normal.texture = load(illustration_path)
		else:
			var style_fallback = StyleBoxFlat.new()
			style_fallback.bg_color = Color(0.95, 0.93, 0.88, 0.95)
			style_fallback.border_width_left = 2
			style_fallback.border_width_top = 2
			style_fallback.border_width_right = 2
			style_fallback.border_width_bottom = 2
			style_fallback.border_color = Color(0.12, 0.12, 0.15, 0.25)
			style_normal = style_fallback
			
		var style_hover = style_normal.duplicate()
		if style_hover is StyleBoxTexture:
			style_hover.modulate_color = Color(1.1, 1.1, 1.1, 1.0)
		else:
			style_hover.bg_color = Color(0.99, 0.98, 0.95, 1.0)
			
		var style_pressed = style_normal.duplicate()
		if style_pressed is StyleBoxTexture:
			style_pressed.modulate_color = Color(0.85, 0.85, 0.85, 1.0)
		else:
			style_pressed.bg_color = Color(0.85, 0.83, 0.78, 1.0)
			
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		# User requested names drawn on top of the illustrations
		var title_lbl = Label.new()
		title_lbl.text = card.card_name
		if card_font_main:
			title_lbl.add_theme_font_override("font", card_font_main)
		title_lbl.add_theme_font_size_override("font_size", 10)
		title_lbl.add_theme_color_override("font_color", Color.WHITE)
		title_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.position = Vector2(0, 8)
		title_lbl.size = Vector2(98, 20)
		btn.add_child(title_lbl)
		
		if DeckManager.retained_card == card:
			var ret_lbl = Label.new()
			ret_lbl.text = "R"
			ret_lbl.add_theme_font_override("font", combat_font)
			ret_lbl.add_theme_font_size_override("font_size", 12)
			ret_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1, 1.0))
			ret_lbl.position = Vector2(84, 6)
			btn.add_child(ret_lbl)
			
		btn.pressed.connect(func(): play_card(card))
		hand_container.add_child(btn)
		
		btn.pivot_offset = Vector2(49, 140) # Pivot at bottom center for realistic fanning
		
		# --- Slay the Spire Fanning Math ---
		var relative_i = float(card_index) - (float(hand_size) - 1.0) / 2.0
		var base_rot = deg_to_rad(relative_i * 6.0) # 6 degrees of fan per card
		var base_x = 325.0 + (relative_i * card_spacing) - 49.0 # Center of HandPanel is 325
		var base_y = 40.0 + (abs(relative_i) * abs(relative_i) * 4.0) # Parabolic dip
		var base_pos = Vector2(base_x, base_y)
		
		btn.rotation = base_rot
		btn.position = Vector2(base_x, base_y + 200) # Start from bottom offscreen
		btn.z_index = card_index
		
		var active_tweens = { "tween": null }
		var hover_pos = Vector2(base_x, base_y - 40.0) # Pop upwards slightly
		
		btn.mouse_entered.connect(func():
			EventBus.play_sound.emit("card_hover")
			if active_tweens["tween"]: active_tweens["tween"].kill()
			feedback_label.text = card.description
			btn.z_index = 100 # Bring to very front
			active_tweens["tween"] = btn.create_tween().set_parallel(true)
			active_tweens["tween"].tween_property(btn, "scale", Vector2(1.8, 1.8), 0.12).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "position", hover_pos, 0.12).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "modulate", Color(1.15, 1.15, 1.15, 1.0), 0.12)
		)
		btn.mouse_exited.connect(func():
			if active_tweens["tween"]: active_tweens["tween"].kill()
			feedback_label.text = ""
			btn.z_index = card_index # Restore correct Z-order
			active_tweens["tween"] = btn.create_tween().set_parallel(true)
			active_tweens["tween"].tween_property(btn, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "rotation", base_rot, 0.1).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "position", base_pos, 0.1).set_trans(Tween.TRANS_SINE)
			active_tweens["tween"].tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
		)
		
		# Draw animation
		var delay = card_index * 0.04
		btn.scale = Vector2(0.5, 0.5)
		btn.modulate.a = 0.0
		var pop_tw = btn.create_tween().set_parallel(true)
		pop_tw.tween_property(btn, "scale", Vector2(1.5, 1.5), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
		pop_tw.tween_property(btn, "position", base_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
		pop_tw.tween_property(btn, "modulate:a", 1.0, 0.2).set_delay(delay)
		
		card_index += 1

func set_buttons_disabled(disabled: bool) -> void:
	end_turn_btn.disabled = disabled
	reroll_btn.disabled = disabled or not DeckManager.can_reroll
	if retain_btn:
		retain_btn.disabled = disabled or not DeckManager.can_retain
	for btn in hand_container.get_children():
		if btn is Button:
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
		var p_hp_val = $UI/PlayerPanel.get_node_or_null("HPValue")
		var p_block_lbl = $UI/PlayerPanel.get_node_or_null("BlockLabel")
		if p_hp_val: pulse_label(p_hp_val)
		if p_block_lbl: pulse_label(p_block_lbl)
		if energy_orb_label: pulse_label(energy_orb_label)
	if pulse_enemy:
		if selected_enemy_idx >= 0 and selected_enemy_idx < active_enemies.size():
			var panel = active_enemies[selected_enemy_idx]["panel"]
			if panel:
				var hp_val = panel.get_node_or_null("HPValue")
				var block_lbl = panel.get_node_or_null("BlockLabel")
				if hp_val: pulse_label(hp_val)
				if block_lbl: pulse_label(block_lbl)

func animate_feedback(text: String, is_turn_banner: bool = false) -> void:
	feedback_label.text = text
	feedback_label.pivot_offset = feedback_label.size / 2
	
	# Apply pixel font to the feedback label
	var combat_font = load("res://Assets/Fonts/VT323-Regular.ttf")
	feedback_label.add_theme_font_override("font", combat_font)
	
	var banner_bg = $UI.get_node_or_null("FeedbackBannerBg")
	if banner_bg:
		banner_bg.visible = false # Default hide
		
	var tween = create_tween()
	if is_turn_banner:
		if banner_bg:
			# RATIONALE: Select the appropriate banner texture based on the feedback text.
			# turn_banner_400x80 (1207x256 real -> render at 400x80) for turn transitions.
			# victory_banner_240x48 (583x211 real -> render at 240x48) for victory.
			# defeat_banner_240x48 (583x211 real -> render at 240x48) for defeat.
			var tex_path = "res://Assets/UI/turn_banner_400x80.png"
			var banner_w = 400.0
			var banner_h = 80.0
			
			if "VICTORY" in text.to_upper():
				tex_path = "res://Assets/UI/victory_banner_240x48.png"
				banner_w = 240.0
				banner_h = 48.0
			elif "DEFEAT" in text.to_upper():
				tex_path = "res://Assets/UI/defeat_banner_240x48.png"
				banner_w = 240.0
				banner_h = 48.0
			
			if FileAccess.file_exists(tex_path):
				banner_bg.texture = load(tex_path)
				banner_bg.custom_minimum_size = Vector2(banner_w, banner_h)
				# Center the banner behind the feedback label
				banner_bg.position = feedback_label.position + (feedback_label.size / 2.0) - Vector2(banner_w / 2.0, banner_h / 2.0)
				banner_bg.visible = true
				banner_bg.modulate.a = 0.0
				
		feedback_label.scale = Vector2(0.7, 0.7)
		feedback_label.modulate.a = 0.0
		
		tween.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
		if banner_bg and banner_bg.visible:
			var tween_bg = create_tween()
			tween_bg.tween_property(banner_bg, "modulate:a", 1.0, 0.1)
			
		tween.tween_property(feedback_label, "scale", Vector2(1.4, 1.4), 0.1)
		tween.tween_interval(0.5)
		tween.tween_property(feedback_label, "modulate:a", 0.8, 0.1)
		if banner_bg and banner_bg.visible:
			var tween_bg2 = create_tween()
			tween_bg2.tween_property(banner_bg, "modulate:a", 0.0, 0.15)
			
		tween.tween_property(feedback_label, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(feedback_label, "modulate:a", 0.0, 0.15)
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

func _style_action_button(btn: Button) -> void:
	if not btn: return
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.95, 0.93, 0.88, 0.9) # Warm beige
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.65, 0.25, 0.15, 0.8) # Sienna border
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	
	var hover = normal.duplicate()
	hover.bg_color = Color(1.0, 0.98, 0.94, 1.0)
	
	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.85, 0.83, 0.78, 1.0)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", normal)
	
	# Fix text color for contrast
	btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.12, 0.12, 0.15, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.12, 0.15, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1.0))

# Creates the Slay the Spire style Energy Orb programmatically.
func _create_energy_orb() -> void:
	energy_orb = Panel.new()
	energy_orb.custom_minimum_size = Vector2(96, 96)
	energy_orb.position = Vector2(40, 480) # Moved up by 20 pixels
	var global_theme = Theme.new()
	var main_font = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")
	if main_font:
		global_theme.default_font = main_font
	energy_orb.theme = global_theme # Inherit universal font
	
	var orb_tex = StyleBoxTexture.new()
	if FileAccess.file_exists("res://Assets/UI/energy_orb_48x48.png"):
		orb_tex.texture = load("res://Assets/UI/energy_orb_48x48.png")
	energy_orb.add_theme_stylebox_override("panel", orb_tex)
	$UI.add_child(energy_orb)
	
	energy_orb_label = Label.new()
	energy_orb_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	energy_orb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_orb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_orb_label.text = "3/3"
	energy_orb_label.add_theme_font_size_override("font_size", 36)
	energy_orb_label.add_theme_color_override("font_color", Color.WHITE)
	energy_orb_label.add_theme_color_override("font_outline_color", Color.BLACK)
	energy_orb_label.add_theme_constant_override("outline_size", 4)
	energy_orb.add_child(energy_orb_label)

# Triggered when n.n.'s introduction dialogue completes.
# Sets up step 1 of the guided tutorial.
func _on_intro_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_intro_dialogue_finished)
	if enemy_name == "Castle Boss" and not GlobalState.has_flag("tutorial_done"):
		tutorial_step = 1
		var intent_val = active_enemies[0]["intent_value"] if active_enemies.size() > 0 else 6
		DialogueSystem.start_dialogue({
			"start": {
				"text": "Look at your cards at the bottom. Strike deals damage, and Defend blocks enemy attacks. Notice the Castle Boss intends to attack you for %d damage this turn!" % intent_val,
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
			"text": "Perfect! You have %d energy left. You cannot play any more cards because both Strike and Defend cost 1 energy. Press 'End Turn' to let the enemy act." % player_energy,
			"speaker": "n.n.",
			"next": ""
		}
	}, "start")

# Welcomes the player to turn 2 and explains advanced actions.
func _trigger_tutorial_turn_2() -> void:
	DialogueSystem.start_dialogue({
		"start": {
			"text": "Good job! Your block absorbed the damage. You also have a 'Reroll' button to replace your hand for free once per round, and a 'Retain' button to save a card for next turn.",
			"speaker": "n.n.",
			"next": "tut_intents"
		},
		"tut_intents": {
			"text": "Pay close attention to Enemy Intents above their head. It tells you exactly what they will do this turn so you can plan accordingly.",
			"speaker": "n.n.",
			"next": "tut_ultimate"
		},
		"tut_ultimate": {
			"text": "Finally, see that gauge on the left? Playing cards charges your Ultimate Attack! When it's fully charged, unleash a devastating blow!",
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
	# RATIONALE: Bounds-check before accessing stages_data to prevent
	# the out-of-bounds crash when _transition_to_next_wave is called
	# after the final wave (index == stages_data.size()).
	if stage_idx >= stages_data.size():
		push_error("_start_wave: stage_idx %d is out of bounds (size %d)" % [stage_idx, stages_data.size()])
		return
	current_stage_idx = stage_idx
	
	if stage_idx == 0 and enemy_name == "Castle Boss":
		# EventBus.play_sound.emit("gears_loop")
		pass
	
	# Clean up any existing nodes from a previous wave stage.
	for enemy in active_enemies:
		if enemy.get("template") and is_instance_valid(enemy["template"]):
			enemy["template"].queue_free()
		# Fallbacks for any dynamically added visual nodes that might not be in template
		if enemy.get("intent_hbox") and is_instance_valid(enemy["intent_hbox"]):
			enemy["intent_hbox"].queue_free()
			
	active_enemies.clear()
	
	var wave_enemies = stages_data[stage_idx]
	var enemy_count = wave_enemies.size()
	
	# Determine X coordinates on the screen based on total enemy count to space them out side-by-side.
	var x_coords = []
	if enemy_count == 1:
		x_coords = [850]
	elif enemy_count == 2:
		x_coords = [720, 980] # Widened to prevent overlapping HUDs
	elif enemy_count == 3:
		x_coords = [600, 820, 1040] # Widened to completely prevent overlapping HUDs
		
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
			"template": null,
			"sprite": null,
			"panel": null,
			"target_btn": null,
			"arrow": null
		}
		
		# Duplicate the EnemyTemplate which contains Sprite, Panel, Arrow, and TargetButton
		var template = $UI/EnemyTemplate.duplicate()
		template.visible = true
		template.name = "EnemyTemplate_%d" % i
		template.position = Vector2(x_coords[i], 310) # Base position is character level
		$UI.add_child(template)
		enemy_data["template"] = template
		
		var sprite = template.get_node("EnemySprite")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Map conf["name"] to correct custom texture path
		var texture_path = "res://Assets/Sprites/Monster1-Sheet_8x1.png"
		var portrait_path = "res://Assets/Sprites/Monster1.png"
		var name_lower = conf["name"].to_lower()
		if "sentry" in name_lower:
			texture_path = "res://Assets/Sprites/Monster2-Sheet_8x1.png"
			portrait_path = "res://Assets/Sprites/Monster2.png"
		elif "pack leader" in name_lower:
			texture_path = "res://Assets/Sprites/PACKLEADER.png"
			portrait_path = "res://Assets/Sprites/PACKLEADER.png"
		elif "wolf" in name_lower:
			texture_path = "res://Assets/Sprites/PACKLEADER 2.png"
			portrait_path = "res://Assets/Sprites/PACKLEADER 2.png"
		elif "castle boss" in name_lower:
			texture_path = "res://Assets/Sprites/Monster1-Sheet_8x1.png"
			portrait_path = "res://Assets/Sprites/Monster1.png"
			
		if FileAccess.file_exists(texture_path):
			sprite.texture = load(texture_path)
		else:
			if FileAccess.file_exists("res://Assets/Sprites/Monster1-Sheet_8x1.png"):
				sprite.texture = load("res://Assets/Sprites/Monster1-Sheet_8x1.png")
			
		# RATIONALE: All monster sprites are 256x256 real pixels.
		var base_scale = Vector2(0.7, 0.7)
		if "pack leader" in name_lower or "boss" in name_lower:
			base_scale = Vector2(1.0, 1.0)
		sprite.scale = base_scale
		if "Sheet" in texture_path or "Monster" in texture_path:
			sprite.hframes = 8
			sprite.vframes = 1
			var anim_tw = create_tween().set_loops()
			for frame_idx in range(8):
				anim_tw.tween_callback(func():
					if is_instance_valid(sprite):
						sprite.frame = frame_idx
				)
				anim_tw.tween_interval(0.12)
			
		enemy_data["sprite"] = sprite
		# Setup panel
		var panel = template.get_node("EnemyPanel")
		var portrait = panel.get_node_or_null("Portrait")
		if portrait and FileAccess.file_exists(portrait_path):
			portrait.texture = load(portrait_path)
		enemy_data["panel"] = panel
		
		# Setup arrow
		var arrow = template.get_node("TargetArrow")
		enemy_data["arrow"] = arrow
		
		# Setup target button
		var target_btn = template.get_node("TargetButton")
		var idx_closure = i
		
		target_btn.mouse_entered.connect(func():
			if current_state == State.PLAYER_ACTION and is_instance_valid(sprite) and active_enemies[idx_closure]["hp"] > 0:
				sprite.modulate = Color(1.5, 1.5, 1.5)
				sprite.scale = base_scale * 1.1 # Scale accurately from base_scale!
				if is_instance_valid(arrow):
					if arrow.has_meta("tween") and is_instance_valid(arrow.get_meta("tween")):
						arrow.get_meta("tween").kill()
					arrow.visible = true
					arrow.position.y = -150.0 # Relative to template
					var tween = create_tween().set_loops()
					tween.tween_property(arrow, "position:y", -135.0, 0.4).set_trans(Tween.TRANS_SINE)
					tween.tween_property(arrow, "position:y", -150.0, 0.4).set_trans(Tween.TRANS_SINE)
					arrow.set_meta("tween", tween)
		)
		target_btn.mouse_exited.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate = Color(1.0, 1.0, 1.0)
				sprite.scale = base_scale # Return to original base scale!
			if is_instance_valid(arrow):
				arrow.visible = false
				if arrow.has_meta("tween") and is_instance_valid(arrow.get_meta("tween")):
					arrow.get_meta("tween").kill()
		)
		
		target_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		target_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		enemy_data["target_btn"] = target_btn
		
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
	# RATIONALE: An empty active_enemies array is not a victory condition.
	# It occurs during scene init before _start_wave has populated enemies.
	# Returning false here prevents spurious wave-advance calls on load.
	if active_enemies.is_empty():
		return false
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
	deck_booklet_btn.text = ""
	deck_booklet_btn.position = Vector2(20, 580) # Extreme bottom left corner
	deck_booklet_btn.size = Vector2(48, 48)
	
	var btn_style_normal = StyleBoxTexture.new()
	var icon_path = "res://Assets/UI/card_pile_icon_32x32.png"
	if FileAccess.file_exists(icon_path):
		btn_style_normal.texture = load(icon_path)
	var btn_style_hover = btn_style_normal.duplicate()
	btn_style_hover.modulate_color = Color(1.2, 1.2, 1.2, 1.0)
	var btn_style_pressed = btn_style_normal.duplicate()
	btn_style_pressed.modulate_color = Color(0.8, 0.8, 0.8, 1.0)
	
	deck_booklet_btn.add_theme_stylebox_override("normal", btn_style_normal)
	deck_booklet_btn.add_theme_stylebox_override("hover", btn_style_hover)
	deck_booklet_btn.add_theme_stylebox_override("pressed", btn_style_pressed)
	deck_booklet_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	deck_booklet_btn.pressed.connect(_toggle_deck_viewer)
	$UI.add_child(deck_booklet_btn)

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
	var global_theme = Theme.new()
	var main_font = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")
	if main_font:
		global_theme.default_font = main_font
	deck_viewer_panel.theme = global_theme
	
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
	deck_grid.columns = 6
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
		
	var card_font_main = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")
	
	for card in pile:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(98, 140)
		btn.size = Vector2(98, 140)
		btn.text = "" 
		
		var card_img_name = card.card_name.to_lower().replace(" ", "_")
		var illustration_path = "res://Assets/Cards/" + card_img_name + ".png"
		
		var style_normal = StyleBoxTexture.new()
		if FileAccess.file_exists(illustration_path):
			style_normal.texture = load(illustration_path)
		else:
			var style_fallback = StyleBoxFlat.new()
			style_fallback.bg_color = Color(0.95, 0.93, 0.88, 0.95)
			style_fallback.border_width_left = 2
			style_fallback.border_width_top = 2
			style_fallback.border_width_right = 2
			style_fallback.border_width_bottom = 2
			style_fallback.border_color = Color(0.12, 0.12, 0.15, 0.25)
			style_normal = style_fallback
			
		var style_hover = style_normal.duplicate()
		if style_hover is StyleBoxTexture:
			style_hover.modulate_color = Color(1.1, 1.1, 1.1, 1.0)
		else:
			style_hover.bg_color = Color(0.99, 0.98, 0.95, 1.0)
			
		var style_pressed = style_normal.duplicate()
		if style_pressed is StyleBoxTexture:
			style_pressed.modulate_color = Color(0.85, 0.85, 0.85, 1.0)
		else:
			style_pressed.bg_color = Color(0.85, 0.83, 0.78, 1.0)
			
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		# Add title text to top of booklet cards
		var title_lbl = Label.new()
		title_lbl.text = card.card_name
		if card_font_main:
			title_lbl.add_theme_font_override("font", card_font_main)
		title_lbl.add_theme_font_size_override("font_size", 10)
		title_lbl.add_theme_color_override("font_color", Color.WHITE)
		title_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.position = Vector2(0, 8)
		title_lbl.size = Vector2(98, 20)
		btn.add_child(title_lbl)
		
		# Booklet cards show their effect via tooltip
		btn.tooltip_text = card.description
		
		deck_grid.add_child(btn)

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
	EventBus.play_sound.emit("block_break")
	active_enemies[idx]["block"] = 0
	animate_feedback("Heavy Slash breaks through the defense of " + active_enemies[idx]["name"] + "!")
	update_stats_pulsed(false, true)

func _process(delta: float) -> void:
	if not has_meta("_anim_timer"):
		set_meta("_anim_timer", 0.0)
	var t = get_meta("_anim_timer") + delta
	if t > 0.15:
		t = 0.0
		if player_sprite and player_sprite.hframes > 1:
			player_sprite.frame = (player_sprite.frame + 1) % player_sprite.hframes
		for enemy in active_enemies:
			if typeof(enemy) == TYPE_DICTIONARY and enemy.has("sprite") and is_instance_valid(enemy["sprite"]):
				var es = enemy["sprite"]
				if es.hframes > 1:
					es.frame = (es.frame + 1) % es.hframes
	set_meta("_anim_timer", t)
