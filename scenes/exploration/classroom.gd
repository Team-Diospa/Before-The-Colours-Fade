extends Node2D
# Level script for the Classroom scene (S_class).
# Implements interactables for Orang 1, Orang 2, Locker (collect buff), and Desk (starts the quiz and shifts to S_dream2).
# Also handles returning from combat with a fragment to use on the Paper Monster.

# Dialogue trees for the classroom actors with split beats and isolated system notices.
var peer1_dialogue: Dictionary = {
	"start": {
		"text": "Peer 1: Uhh... You okay?",
		"options": [
			{"text": "\"Uhh, yeah. Why?\"", "next": "look_ghost"},
			{"text": "\"I'm just stressed about the quiz.\"", "next": "stressed"}
		]
	},
	"look_ghost": {
		"text": "Peer 1: You look like a ghost. Did you... forget again?",
		"options": [
			{"text": "\"Forget what?\"", "next": "forget_what"},
			{"text": "\"No, I'm fine.\"", "next": "stressed"}
		]
	},
	"forget_what": {
		"text": "Peer 1: Your notebook. You left it in the workshop. The one on 4th street.",
		"next": "forget_what_2"
	},
	"forget_what_2": {
		"speaker": "Hilbert",
		"text": "The workshop? I haven't been there in months.",
		"next": "forget_what_3"
	},
	"forget_what_3": {
		"text": "Peer 1: Really? I could have sworn I saw the lights on yesterday. Anyway, take care.",
		"next": "peer1_healed_sys"
	},
	"stressed": {
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
		"text": "Peer 2: Stop looking at me! Weirdo.",
		"options": [
			{"text": "\"Sorry, just spaced out.\"", "next": "apologize"},
			{"text": "\"I wasn't looking at you.\"", "next": "reciting"}
		]
	},
	"reciting": {
		"text": "Peer 2: Right. Hilbert, are you reciting formulas or what? You keep humming that same chord under your breath.",
		"options": [
			{"text": "\"Sorry.\"", "next": "apologize"},
			{"text": "Ignore them.", "next": "ignore"}
		]
	},
	"apologize": {
		"text": "You swallow your pride to defuse the tension.",
		"next": "apologize_sys"
	},
	"apologize_sys": {
		"text": "[System]: Defusing tension clears your head (+5 starting Block on turn 1 of combat).",
		"next": ""
	},
	"ignore": {
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
		# RATIONALE: Ground the cards (Fortress and Counter Stance) in matching physical designs.
		# A braced shelter blueprint justifies Fortress (defense), and a spring-loaded recoil gear justifies Counter Stance.
		"text": "Hilbert: Old blueprints for a reinforced storm shelter we wanted to build in the backyard. The framing is double-braced. And a second sheet shows a spring-loaded recoil gear designed to redirect force. The margin says: 'converts impact into return pressure.' The handwriting is his.",
		"next": "locker_sys"
	},
	"locker_sys": {
		"text": "[System]: Locker -> Courage (Fortress and Counter Stance added to deck. Courage Buff active).",
		"next": ""
	}
}

# Dialogue tree for the blackboard inspection.
# RATIONALE: Grounds the blackboard in the information-gap theory. The hand-drawn gear axle
# is a retrieval cue for the dream world, connecting back to the drawings and L.G.'s cursive.
var blackboard_dialogue: Dictionary = {
	"start": {
		"text": "The blackboard is covered in complex, chalk-written mechanics equations. Bending moments, shear diagrams, deflection formulas.",
		"next": "board_2"
	},
	"board_2": {
		"text": "In the corner, squeezed between two massive integrals, is a small, hand-drawn sketch of a gear axle. It does not belong to the lecture. It matches the propeller cart schematic exactly.",
		"next": "board_3"
	},
	"board_3": {
		"text": "A tiny note is written underneath in a neat, familiar cursive: 'Keep moving, Hil. The calculations are already done.'",
		"next": "board_sys"
	},
	"board_sys": {
		"text": "[System]: The familiar sketch settles your focus (+5 starting Block on turn 1 of combat).",
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
		# RATIONALE: Full professor speech verbatim from the script docs.
		"text": "Professor: Alright sit down everyone. Like I said last week, we are going to have a quiz, mind you, this quiz is worth 50% of your grade, so I want you all to be in your best shape and mind.",
		"next": "quiz_yes_2"
	},
	"quiz_yes_2": {
		"text": "Professor: Do it slowly, but surely. If you don't know the answer skip it, and answer other questions. This quiz starts in 5 minutes, be sure to put all your phone and gadgets in the bag and pull out your stationery.",
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
	
	# Programmatically spawn the blackboard interactable to keep scene files clean.
	var blackboard_scene = load("res://core/components/interactable.tscn")
	if blackboard_scene:
		var blackboard = blackboard_scene.instantiate()
		blackboard.name = "Blackboard"
		blackboard.interaction_id = "blackboard"
		blackboard.prompt_message = "Press E to look at Blackboard"
		blackboard.position = Vector2(150, 500)
		blackboard.interacted.connect(_on_blackboard_interacted)
		add_child(blackboard)
		
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

# Routes blackboard interactions.
func _on_blackboard_interacted(_id: String) -> void:
	if GlobalState.has_flag("blackboard_inspected"):
		DialogueSystem.start_dialogue({"start": {"text": "The chalk equations are dusty. The little gear sketch remains in the corner.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(blackboard_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_blackboard_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_blackboard_dialogue_finished)

# Applies starting block modifier once the blackboard dialogue completes successfully.
func _on_blackboard_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_blackboard_dialogue_finished)
	if DialogueSystem.dialogue_tree == blackboard_dialogue and DialogueSystem.current_node_id == "board_sys":
		GlobalState.set_flag("blackboard_inspected", true)
		GlobalState.starting_block_modifier += 5


