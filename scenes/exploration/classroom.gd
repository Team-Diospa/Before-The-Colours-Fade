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
		# RATIONALE: Ground the discovery in specific childhood plans (flying whales drawn in blue wax crayon)
		# inside L.G.'s old draft binder stuffed behind heavy textbooks.
		"text": "Hilbert: Stuffed behind the heavy college textbooks is L.G.'s old cardboard draft binder. The cover is faded, featuring drawings of giant flying whales in blue wax crayon. I took it from his desk after the service and hid it here, unable to throw it away. Inside are blueprints for a reinforced storm shelter we wanted to build when we were ten. The margin notes are in his handwriting: 'converts impact into return pressure.'",
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

# Dialogue for focusing on the Quiz Paper.
# RATIONALE: Represents the quiz paper as the mundane stressor. Hilbert recalls his friend's designs
# instead of using a magical glowing item, keeping reality grounded.
var paper_monster_dialogue: Dictionary = {
	"start": {
		"text": "The quiz paper on your desk lies frozen. The words are jumbled, vibrating in place. Try to recall his drawings to steady your focus?",
		"options": [
			{"text": "Yes - recall his designs", "next": "use_yes"},
			{"text": "No", "next": "use_no"}
		]
	},
	"use_yes": {
		"text": "You close your eyes and focus on his old drafts.",
		"next": "use_yes_2"
	},
	"use_yes_2": {
		# RATIONALE: Physical sensation beats per the script - the world paused, lighter, stronger.
		"text": "The world around you remains still and grey. But the pressure on your temples begins to ease.",
		"next": "use_yes_3"
	},
	"use_yes_3": {
		"text": "You breathe slowly. The jumbled math equations stop spinning, settling into readable lines.",
		"next": "use_yes_4"
	},
	"use_yes_4": {
		"text": "The margin note comes into focus: 'Reduce to simplest terms. Eliminate the fractions. Erase the remainder.'",
		"next": "use_yes_5"
	},
	"use_yes_5": {
		"text": "The tension in the paper shatters. The handwriting is clean. It matches your own, but the calculations are correct.",
		"next": "use_yes_sys"
	},
	"use_yes_sys": {
		"text": "[System]: Memory recalled (Confidence Buff active, attacks deal 2.0x damage).",
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
		
		# RATIONALE: Programmatically spawn the adjacent empty desk interactable.
		var empty_desk = blackboard_scene.instantiate()
		empty_desk.name = "EmptyDesk"
		empty_desk.interaction_id = "empty_desk"
		empty_desk.prompt_message = "Press E to look at Adjacent Desk"
		empty_desk.position = Vector2(1050, 500)
		empty_desk.interacted.connect(_on_empty_desk_interacted)
		add_child(empty_desk)
		
	# Configure the Quiz Paper stressor depending on whether we are mid-combat.
	# RATIONALE: Focuses on the test sheet rather than a literal fantasy monster.
	if ShiftManager.cached_combat_exists and GlobalState.acquired_fragments > 0:
		$Desk.prompt_message = "Press E to focus on Quiz Paper"
		$Desk.interaction_id = "quiz_paper"

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
	if id == "quiz_paper":
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

# Dialogue tree for adjacent empty desk.
var empty_desk_dialogue: Dictionary = {
	"start": {
		# RATIONALE: Ground the empty desk next to Hilbert with specific sensory details.
		"text": "The desk next to yours is empty. On the wooden surface, there is a dried yellow smear of wood glue from when L.G. tried to assemble a cardboard propeller gear in class.",
		"next": "empty_desk_2"
	},
	"empty_desk_2": {
		"text": "Wedged deep inside the metal hinge of the lifting desktop lid is a crumpled silver-foil strawberry candy wrapper, folded into a tiny spaceship shape.",
		"next": ""
	}
}

func _on_empty_desk_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(empty_desk_dialogue, "start")


