extends Node2D
# Level script for the Classroom scene (S_class).
# Implements interactables for Orang 1, Orang 2, Locker (collect buff), and Desk (starts the quiz and shifts to S_dream2).
# Also handles returning from combat with a fragment to use on the Paper Monster.

# Dialogue trees for the classroom actors.
var peer1_dialogue: Dictionary = {
	"start": {
		"text": "Orang 1: Uhh... You okay?",
		"next": ""
	}
}

var peer2_dialogue: Dictionary = {
	"start": {
		"text": "Orang 2: Stop looking at me! Weirdo.",
		"next": ""
	}
}

var locker_dialogue: Dictionary = {
	"start": {
		"text": "You open the locker. Found a Courage Buff card!",
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
		"text": "You place the fragment onto the Paper Monster. It shatters into glowing dust! You feel lighter and stronger. (Confidence Buff Active)",
		"next": ""
	},
	"use_no": {
		"text": "You decide to hold on to the fragment.",
		"next": ""
	}
}

var is_locker_searched: bool = false
var is_paper_monster_defeated: bool = false

func _ready() -> void:
	# Connect to local interactable node signals.
	$Orang1.interacted.connect(_on_orang1_interacted)
	$Orang2.interacted.connect(_on_orang2_interacted)
	$Locker.interacted.connect(_on_locker_interacted)
	$Desk.interacted.connect(_on_desk_interacted)
	
	# Configure the Paper Monster depending on whether we are mid-combat.
	# We can use the Desk interactable as the Paper Monster when returning.
	if ShiftManager.cached_combat_exists and GlobalState.acquired_fragments > 0:
		$Desk.prompt_message = "Press E to use Fragment on Paper Monster"
		$Desk.interaction_id = "paper_monster"

func _on_orang1_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(peer1_dialogue, "start")

func _on_orang2_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(peer2_dialogue, "start")

func _on_locker_interacted(_id: String) -> void:
	if not is_locker_searched:
		is_locker_searched = true
		GlobalState.set_flag("buff_courage_active", true)
		DialogueSystem.start_dialogue(locker_dialogue, "start")
	else:
		DialogueSystem.start_dialogue(locker_empty_dialogue, "start")

func _on_desk_interacted(id: String) -> void:
	if id == "paper_monster":
		DialogueSystem.start_dialogue(paper_monster_dialogue, "start")
		# Connect class method to dialogue finish to consume fragment and resume.
		if not EventBus.dialogue_finished.is_connected(_on_paper_monster_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_paper_monster_dialogue_finished)
	else:
		DialogueSystem.start_dialogue(desk_dialogue, "start")
		# Connect class method to dialogue finish to start quiz and transition.
		if not EventBus.dialogue_finished.is_connected(_on_desk_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_desk_dialogue_finished)

# Bound listener callback to avoid signal reference leaks.
func _on_paper_monster_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_paper_monster_dialogue_finished)
	if DialogueSystem.dialogue_tree == paper_monster_dialogue and DialogueSystem.current_node_id == "use_yes":
		GlobalState.acquired_fragments -= 1
		GlobalState.set_flag("buff_confidence_active", true)
		# Warp back to S_dream2 to resume combat.
		SceneManager.transition_to_state("S_dream2_resume")

# Bound listener callback to avoid signal reference leaks.
func _on_desk_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_desk_dialogue_finished)
	if DialogueSystem.dialogue_tree == desk_dialogue and DialogueSystem.current_node_id == "quiz_fade":
		GlobalState.set_flag("quiz_started", true)
		# Transition to S_dream2 (Burning Village combat).
		SceneManager.transition_to_state("S_dream2")


