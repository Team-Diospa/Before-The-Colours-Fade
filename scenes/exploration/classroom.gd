extends Node2D
# Level script for the Classroom scene (S_class).
# Implements interactables for Orang 1, Orang 2, Locker (collect buff), and Desk (starts the quiz and shifts to S_dream2).
# Also handles returning from combat with a fragment to use on the Paper Monster.

# Dialogue trees for the classroom actors with split beats and isolated system notices.
var peer1_dialogue: Dictionary = {
	"start": {
		"text": "Marcus: Hilbert? Whoa, dude. You look like you got ran over by a steamroller. Did you forget your medication again?",
		"options": [
			{"text": "\"I'm fine. Just forgot where I put things.\"", "next": "forget_what"},
			{"text": "\"Just exam panic. I'll survive.\"", "next": "stressed"}
		]
	},
	"forget_what": {
		"text": "Hilbert: I'm fine. Just forgot where I put things.",
		"next": "forget_what_2"
	},
	"forget_what_2": {
		"text": "Marcus: Right. Well, I found this notebook under the bleachers yesterday. It's full of those weird clockwork drawings you and... well, you know. I left it in your locker. You should grab it.",
		"next": "forget_what_3"
	},
	"forget_what_3": {
		"text": "Hilbert: Me and... who?",
		"next": "forget_what_4"
	},
	"forget_what_4": {
		"text": "Marcus stares at you, his nervous grin slowly dying. A look of profound, uncomfortable pity crosses his face. 'Hilbert. That's... not funny. Seriously. Go check your locker.'",
		"next": "peer1_healed_sys"
	},
	"stressed": {
		"text": "Hilbert: Just exam panic. I'll survive.",
		"next": "stressed_2"
	},
	"stressed_2": {
		"text": "Marcus: Yeah, this professor is a monster. Tell you what, take my lucky green pen. Don't die out there, man.",
		"next": "peer1_healed_sys"
	},
	"peer1_healed_sys": {
		"text": "[System]: A classmate's small concern warms the cold fog in your chest (Health restored by 15 HP).",
		"next": ""
	}
}

var peer2_dialogue: Dictionary = {
	"start": {
		"text": "Chloe: Hilbert, seriously? You've been staring at the wall and whispering to yourself for ten minutes. It's distracting and, honestly, kinda freaking me out.",
		"options": [
			{"text": "\"Sorry, Chloe. Spaced out.\"", "next": "apologize"},
			{"text": "Ignore her.", "next": "ignore"}
		]
	},
	"apologize": {
		"text": "Hilbert: Sorry, Chloe. Spaced out.",
		"next": "apologize_2"
	},
	"apologize_2": {
		"text": "Chloe rolls her eyes but sighs. 'Whatever. Just don't start muttering during the quiz, okay? I need to focus.' You force a polite nod, pushing down the prickling anxiety.",
		"next": "apologize_sys"
	},
	"apologize_sys": {
		"text": "[System]: De-escalating the friction clears the static in your head (+5 starting Block on turn 1 of combat).",
		"next": ""
	},
	"ignore": {
		"text": "You ignore the comment, focusing your gaze right through her onto the hum of the classroom fluorescent lights.",
		"next": "ignore_2"
	},
	"ignore_2": {
		"text": "Chloe: 'Creepy.' She mutters under her breath and aggressively turns her desk away. You block her out. The noise of the world recedes into a dull, distant murmur.",
		"next": "ignore_sys"
	},
	"ignore_sys": {
		"text": "[System]: Uncompromising isolation sharpens your cognitive focus (Draw +1 card on turn 1 of combat).",
		"next": ""
	}
}

var locker_dialogue: Dictionary = {
	"start": {
		"text": "You open the metal locker. Taped to the door is a hand-drawn sketch of a flying clockwork machine with a smiling face and a tiny propeller. The initials at the bottom read: 'H.H. & L.G.'",
		"next": "locker_2"
	},
	"locker_2": {
		"text": "Hilbert: H.H. is me... Hilbert Hickman. But L.G.? Who is L.G.? The drawings feel warm, filled with a childhood hope that feels entirely foreign to this grey morning. You pull the sketch down.",
		"next": "locker_sys"
	},
	"locker_sys": {
		"text": "[System]: Childhood Blueprint retrieved -> The memory of courage manifests (Fortress and Counter Stance cards added. Courage Buff active).",
		"next": ""
	}
}

var locker_empty_dialogue: Dictionary = {
	"start": {
		"text": "The locker is empty. Only dust and scratched metal remain.",
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
		"text": "Paper Monster: IF YOU ERASE THE PAIN, YOU ERASE HIM. WAKE UP, HILBERT!",
		"next": "use_yes_3"
	},
	"use_yes_3": {
		"text": "The monster shatters into fading light. You feel a sudden, numb lightness in your chest.",
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
		# RATIONALE: Compassion heals Hilbert's current HP by 15.
		GlobalState.player_current_hp = min(GlobalState.player_current_hp + 15, GlobalState.player_max_hp)

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


