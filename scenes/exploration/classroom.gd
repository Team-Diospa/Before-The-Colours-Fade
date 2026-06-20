extends Node2D
# Level script for the Classroom scene (S_class).
# Implements interactables for Orang 1, Orang 2, Locker (collect buff), and Desk (starts the quiz and shifts to S_dream2).
# Also handles returning from combat with a fragment to use on the Paper Monster.

# Dialogue trees for the classroom actors with split beats and isolated system notices.
var peer1_dialogue: Dictionary = {
	"start": {
		"text": "Peer 1: Hilbert? You look like a ghost. Did you... forget again?",
		"options": [
			{"text": "\"Forget what?\"", "next": "forget_what"},
			{"text": "\"I'm just stressed about the quiz.\"", "next": "stressed"}
		]
	},
	"forget_what": {
		"text": "Hilbert: Forget what?",
		"next": "forget_what_2"
	},
	"forget_what_2": {
		"text": "Peer 1: Your notebook. You left it in the workshop. The one on 4th street.",
		"next": "forget_what_3"
	},
	"forget_what_3": {
		"text": "Hilbert: The workshop? I haven't been there in months.",
		"next": "forget_what_4"
	},
	"forget_what_4": {
		"text": "Peer 1: Really? I could have sworn I saw the lights on yesterday. Anyway, take care.",
		"next": "peer1_healed_sys"
	},
	"stressed": {
		"text": "Hilbert: I'm just stressed about the quiz.",
		"next": "stressed_2"
	},
	"stressed_2": {
		"text": "Peer 1: Don't worry, it's just a quiz. Take it slow, Hilbert.",
		"next": "peer1_healed_sys"
	},
	"peer1_healed_sys": {
		# RATIONALE: Peer1's concern is not a physical healing event.
		# Their words open something - the player listens more carefully.
		# A draw modifier (listening = attention = more options) is more grounded than HP restoration.
		"text": "[System]: Someone noticed. You feel a little more present. (+1 card drawn on turn 1).",
		"next": ""
	}
}

var peer2_dialogue: Dictionary = {
	"start": {
		"text": "Peer 2: Hilbert, are you reciting formulas or what? You keep humming that same chord under your breath.",
		"options": [
			{"text": "\"Sorry, just spaced out.\"", "next": "apologize"},
			{"text": "Ignore them.", "next": "ignore"}
		]
	},
	"apologize": {
		"text": "Hilbert: Sorry, just spaced out.",
		"next": "apologize_2"
	},
	"apologize_2": {
		"text": "You swallow your pride to defuse the tension.",
		"next": "apologize_sys"
	},
	"apologize_sys": {
		"text": "[System]: Defusing tension clears your head (+5 starting Block on turn 1 of combat).",
		"next": ""
	},
	"ignore": {
		"text": "You ignore the comment and turn away.",
		"next": "ignore_2"
	},
	"ignore_2": {
		"text": "You focus inward, blocking out the classroom noise.",
		"next": "ignore_sys"
	},
	"ignore_sys": {
		"text": "[System]: Inward focus improves concentration (Draw +1 card on turn 1 of combat).",
		"next": ""
	}
}

var locker_dialogue: Dictionary = {
	"start": {
		"text": "You open the locker. Inside is an old notebook covered in brave drawings of inventions.",
		"next": "locker_2"
	},
	"locker_2": {
		# RATIONALE: The metaphor chain must be clear.
		# Frame/load-bearing calculations -> Fortress (structural defense).
		# Gear-brake margin note -> Counter Stance (converting momentum into resistance).
		"text": "Hilbert: Old blueprints for a solar-powered bicycle. The frame design... load-bearing calculations in the margins. And a note: 'gear-brake converts momentum into resistance.' The handwriting is barely readable.",
		"next": "locker_sys"
	},
	"locker_sys": {
		"text": "[System]: Locker -> Courage (Fortress and Counter Stance added to deck. Courage Buff active).",
		"next": ""
	}
}

var locker_empty_dialogue: Dictionary = {
	"start": {
		"text": "The locker is empty.",
		"next": ""
	}
}

var desk_dialogue: Dictionary = {
	"start": {
		"text": "Start the quiz?",
		"options": [
			{"text": "Yes", "next": "quiz_yes"},
			{"text": "No", "next": "quiz_no"}
		]
	},
	"quiz_yes": {
		"text": "Professor: This quiz is worth 50% of your grade. No phones, pull out your stationery.",
		"next": "quiz_fade"
	},
	"quiz_fade": {
		"text": "You stare blankly at the paper. Jumbled words... Headache... Panic starts creeping in...",
		"next": ""
	},
	"quiz_no": {
		"text": "Better prepare myself first.",
		"next": ""
	}
}

# Dialogue for using the fragment on the Paper Monster.
var paper_monster_dialogue: Dictionary = {
	"start": {
		"text": "A creepy monster made of exam papers stands frozen in front of the class. Use the Dream Fragment on it?",
		"options": [
			{"text": "Yes", "next": "use_yes"},
			{"text": "No", "next": "use_no"}
		]
	},
	"use_yes": {
		"text": "You place the glowing fragment onto the Paper Monster.",
		"next": "use_yes_2"
	},
	"use_yes_2": {
		# RATIONALE: Physical sensation beats per the script - the world paused, lighter, stronger.
		"text": "The world around you is still. Grey. Paused. But something has shifted inside it.",
		"next": "use_yes_3"
	},
	"use_yes_3": {
		"text": "You feel lighter. Like something that was pressing on your chest has receded, just enough.",
		"next": "use_yes_4"
	},
	"use_yes_4": {
		"text": "Paper Monster: REDUCE TO SIMPLEST TERMS. ELIMINATE THE FRACTIONS. ERASE THE REMAINDER.",
		"next": "use_yes_5"
	},
	"use_yes_5": {
		"text": "The monster shatters into fading light. The writing on its pages looks like your own handwriting.",
		"next": "use_yes_sys"
	},
	"use_yes_sys": {
		"text": "[System]: Reality countered (Confidence Buff active, attacks deal 2.0x damage).",
		"next": ""
	},
	"use_no": {
		"text": "You decide to hold on to the fragment.",
		"next": ""
	}
}

func _ready() -> void:
	# Connect to local interactable node signals.
	$Orang1.interacted.connect(_on_orang1_interacted)
	$Orang2.interacted.connect(_on_orang2_interacted)
	$Locker.interacted.connect(_on_locker_interacted)
	$Desk.interacted.connect(_on_desk_interacted)
	
	# Configure the Paper Monster depending on whether we are mid-combat.
	if ShiftManager.cached_combat_exists and GlobalState.acquired_fragments > 0:
		$Desk.prompt_message = "Press E to use Fragment on Paper Monster"
		$Desk.interaction_id = "paper_monster"

func _on_orang1_interacted(_id: String) -> void:
	if GlobalState.has_flag("peer1_talked"):
		DialogueSystem.start_dialogue({"start": {"text": "Peer 1 is quiet, reviewing notes.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(peer1_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_peer1_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_peer1_dialogue_finished)

func _on_peer1_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_peer1_dialogue_finished)
	if DialogueSystem.dialogue_tree == peer1_dialogue and DialogueSystem.current_node_id == "peer1_healed_sys":
		GlobalState.set_flag("peer1_talked", true)
		# RATIONALE: Listening to someone's concern opens attention - draw 1 extra card on turn 1.
		# This is more narratively grounded than HP restoration from a conversation.
		GlobalState.starting_draw_modifier = max(GlobalState.starting_draw_modifier, 1)

func _on_orang2_interacted(_id: String) -> void:
	if GlobalState.has_flag("peer2_talked"):
		DialogueSystem.start_dialogue({"start": {"text": "Peer 2 ignores you, annoyed.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(peer2_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_peer2_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_peer2_dialogue_finished)

func _on_peer2_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_peer2_dialogue_finished)
	if DialogueSystem.dialogue_tree == peer2_dialogue:
		if DialogueSystem.current_node_id == "apologize_sys":
			GlobalState.set_flag("peer2_talked", true)
			# RATIONALE: Defusing tension grants defensive starting block.
			GlobalState.starting_block_modifier = 5
		elif DialogueSystem.current_node_id == "ignore_sys":
			GlobalState.set_flag("peer2_talked", true)
			# RATIONALE: Inward focus grants starting card draw.
			GlobalState.starting_draw_modifier = 1

func _on_locker_interacted(_id: String) -> void:
	# RATIONALE: locker searched flag is stored globally, preventing the locker re-loot exploit after shifting.
	if not GlobalState.has_flag("locker_searched"):
		DialogueSystem.start_dialogue(locker_dialogue, "start")
		if not EventBus.dialogue_finished.is_connected(_on_locker_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_locker_dialogue_finished)
	else:
		DialogueSystem.start_dialogue(locker_empty_dialogue, "start")

func _on_locker_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_locker_dialogue_finished)
	if DialogueSystem.dialogue_tree == locker_dialogue and DialogueSystem.current_node_id == "locker_sys":
		GlobalState.set_flag("locker_searched", true)
		GlobalState.set_flag("buff_courage_active", true)
		
		# Adds Fortress and Counter Stance to master deck
		var fortress_res = load("res://data/cards/fortress.tres")
		var cstance_res = load("res://data/cards/counter_stance.tres")
		if fortress_res and not GlobalState.master_deck.has(fortress_res):
			GlobalState.master_deck.append(fortress_res)
		if cstance_res and not GlobalState.master_deck.has(cstance_res):
			GlobalState.master_deck.append(cstance_res)

func _on_desk_interacted(id: String) -> void:
	if id == "paper_monster":
		DialogueSystem.start_dialogue(paper_monster_dialogue, "start")
		if not EventBus.dialogue_finished.is_connected(_on_paper_monster_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_paper_monster_dialogue_finished)
	else:
		DialogueSystem.start_dialogue(desk_dialogue, "start")
		if not EventBus.dialogue_finished.is_connected(_on_desk_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_desk_dialogue_finished)

func _on_paper_monster_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_paper_monster_dialogue_finished)
	if DialogueSystem.dialogue_tree == paper_monster_dialogue and DialogueSystem.current_node_id == "use_yes_sys":
		GlobalState.acquired_fragments -= 1
		GlobalState.set_flag("buff_confidence_active", true)
		SceneManager.transition_to_state("S_dream2_resume")

func _on_desk_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_desk_dialogue_finished)
	if DialogueSystem.dialogue_tree == desk_dialogue and DialogueSystem.current_node_id == "quiz_fade":
		GlobalState.set_flag("quiz_started", true)
		SceneManager.transition_to_state("S_dream2")


