extends Node2D
# Level script for the Apartment scene (S_apt).
# Implements interactions, linear color interpolation of CanvasModulate, and transition to S_hall.

@onready var CanvasModulateNode = $CanvasModulate
@onready var PlayerNode = $Player

# Theme colors for the room atmosphere.
const COLOR_MORNING = Color(1.0, 0.95, 0.9, 1.0) # Warm morning sun
const COLOR_DEPRESSION = Color(0.3, 0.3, 0.4, 1.0) # Cold, dark, and gloomy

# Tracking progress flag.
var has_showered: bool = false

# Dictionary representing dialogue structures with split beats and isolated system notices.
var bed_dialogue: Dictionary = {
	"start": {
		"text": "Close my eyes and escape back to the dark? Or face the grey morning?",
		"options": [
			{"text": "Sleep again (Avoid pain)", "next": "bed_yes_1"},
			{"text": "Get up (Force alertness)", "next": "bed_no_1"}
		]
	},
	"bed_yes_1": {
		"text": "n.n.: Hilbert, did you remember to water the plastic plant?",
		"next": "bed_yes_2"
	},
	"bed_yes_2": {
		"text": "You drift back into a light slumber, waking up late and rushed.",
		"next": "bed_yes_sys"
	},
	"bed_yes_sys": {
		"text": "[System]: You feel physically rested (+10 Max HP), but start combat late (-1 starting Energy on turn 1).",
		"next": ""
	},
	"bed_no_1": {
		"text": "Hilbert: No. I need to stay awake. I think there is a test today.",
		"next": "bed_no_sys"
	},
	"bed_no_sys": {
		"text": "[System]: You force yourself out of bed. (+1 starting Energy on turn 1, but -5 Max HP).",
		"next": ""
	}
}

var desk_dialogue: Dictionary = {
	"start": {
		"text": "A dusty drawing notebook and a pencil. Pick them up?",
		"options": [
			{"text": "Yes", "next": "open_drawer_1"},
			{"text": "No", "next": "close_drawer"}
		]
	},
	"open_drawer_1": {
		"text": "Sketches of old childhood inventions... and a framed photograph of a boy holding a giant cabbage.",
		"next": "open_drawer_2"
	},
	"open_drawer_2": {
		"text": "Hilbert: Why did we take a picture with a cabbage? And why is the cabbage wearing a tie?",
		"next": "open_drawer_sys"
	},
	"open_drawer_sys": {
		"text": "[System]: Pencil -> Sword (Double Strike added to deck). Notebook -> Spellbook (Fireball added to deck).",
		"next": ""
	},
	"close_drawer": {
		"text": "You leave the drawings untouched on the desk. The memories are too painful.",
		"next": ""
	}
}

var guitar_dialogue: Dictionary = {
	"start": {
		"text": "An old guitar. Play a chord?",
		"options": [
			{"text": "Yes", "next": "guitar_yes_1"},
			{"text": "No", "next": "guitar_no"}
		]
	},
	"guitar_yes_1": {
		"text": "A soft chord hums in the room. You try to play the intro to an old cartoon theme song.",
		"next": "guitar_yes_2"
	},
	"guitar_yes_2": {
		"text": "Hilbert: I forgot the third chord. It always went... boing? Or was it plink?",
		"next": "guitar_yes_sys"
	},
	"guitar_yes_sys": {
		"text": "[System]: Guitar -> Hope (Health fully restored, Heavy Slash and Thunder added to deck).",
		"next": ""
	},
	"guitar_no": {
		"text": "You don't feel like playing. The silence in the apartment is too heavy.",
		"next": ""
	}
}

var toilet_dialogue: Dictionary = {
	"start": {
		"text": "Just a dirty toilet. Empty, like everything else here.",
		"next": ""
	}
}

var shower_dialogue: Dictionary = {
	"start": {
		"text": "A shower...",
		"next": "shower_step2"
	},
	"shower_step2": {
		"text": "The water turns freezing cold. You stand blankly contemplating...",
		"next": "shower_step3"
	},
	"shower_step3": {
		"text": "wouldn't it be nice to feel the silence forever, not worried about everything, finally in peace surrounded by darkness...",
		"next": "shower_step4"
	},
	"shower_step4": {
		"text": "But the alarm rings again from your phone, reminding you of the quiz today.",
		"next": "shower_step5"
	},
	"shower_step5": {
		"text": "You finish your shower, holding onto a fractured peace.",
		"next": ""
	}
}

var door_dialogue: Dictionary = {
	"start": {
		"text": "Exit to the faculty building hallway?",
		"options": [
			{"text": "Yes", "next": "exit_yes"},
			{"text": "No", "next": "exit_no"}
		]
	},
	"exit_yes": {
		"text": "You exit the apartment.",
		"next": ""
	},
	"exit_no": {
		"text": "You decide to stay inside for now.",
		"next": ""
	}
}

var door_locked_dialogue: Dictionary = {
	"start": {
		"text": "I should probably take a shower first before leaving.",
		"next": ""
	}
}

func _ready() -> void:
	# Set baseline color.
	CanvasModulateNode.color = COLOR_MORNING
	
	# Connect local interactable node signals.
	$Bed.interacted.connect(_on_bed_interacted)
	$Guitar.interacted.connect(_on_guitar_interacted)
	$Desk.interacted.connect(_on_desk_interacted)
	$Toilet.interacted.connect(_on_toilet_interacted)
	$Shower.interacted.connect(_on_shower_interacted)
	$ExitDoor.interacted.connect(_on_exit_door_interacted)

func _on_bed_interacted(_id: String) -> void:
	if GlobalState.has_flag("bed_slept"):
		DialogueSystem.start_dialogue({"start": {"text": "You've already made your choice about the bed.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(bed_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_bed_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_bed_dialogue_finished)

func _on_bed_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_bed_dialogue_finished)
	if DialogueSystem.dialogue_tree == bed_dialogue:
		GlobalState.set_flag("bed_slept", true)
		if DialogueSystem.current_node_id == "bed_yes_sys":
			# RATIONALE: Sleeping in adds to max/current health but penalizes energy for a sluggish start.
			GlobalState.player_max_hp += 10
			GlobalState.player_current_hp += 10
			GlobalState.starting_energy_modifier = -1
		elif DialogueSystem.current_node_id == "bed_no_sys":
			# RATIONALE: Rising immediately gives a quick-thinking alert bonus at the cost of physical exhaustion.
			GlobalState.player_max_hp = max(10, GlobalState.player_max_hp - 5)
			GlobalState.player_current_hp = min(GlobalState.player_current_hp, GlobalState.player_max_hp)
			GlobalState.starting_energy_modifier = 1

func _on_guitar_interacted(_id: String) -> void:
	if GlobalState.has_flag("guitar_played"):
		DialogueSystem.start_dialogue({"start": {"text": "You don't feel like playing the guitar again.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(guitar_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_guitar_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_guitar_dialogue_finished)

func _on_guitar_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_guitar_dialogue_finished)
	if DialogueSystem.dialogue_tree == guitar_dialogue and DialogueSystem.current_node_id == "guitar_yes_sys":
		GlobalState.set_flag("guitar_played", true)
		# RATIONALE: Music provides healing (Hope) and unlocks heavy attack cards in Hilbert's dream.
		GlobalState.player_current_hp = GlobalState.player_max_hp
		var hslash_res = load("res://data/cards/heavy_slash.tres")
		var thunder_res = load("res://data/cards/thunder.tres")
		if hslash_res and not GlobalState.master_deck.has(hslash_res):
			GlobalState.master_deck.append(hslash_res)
		if thunder_res and not GlobalState.master_deck.has(thunder_res):
			GlobalState.master_deck.append(thunder_res)

func _on_desk_interacted(_id: String) -> void:
	if GlobalState.has_flag("desk_searched"):
		DialogueSystem.start_dialogue({"start": {"text": "The desk drawer has been cleared.", "next": ""}}, "start")
		return
	DialogueSystem.start_dialogue(desk_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_desk_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_desk_dialogue_finished)

func _on_desk_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_desk_dialogue_finished)
	if DialogueSystem.dialogue_tree == desk_dialogue and DialogueSystem.current_node_id == "open_drawer_sys":
		GlobalState.set_flag("desk_searched", true)
		# RATIONALE: Searching notes adds structural knowledge (Double Strike & Fireball) to the deck.
		var dstrike_res = load("res://data/cards/double_strike.tres")
		var fireball_res = load("res://data/cards/fireball.tres")
		if dstrike_res and not GlobalState.master_deck.has(dstrike_res):
			GlobalState.master_deck.append(dstrike_res)
		if fireball_res and not GlobalState.master_deck.has(fireball_res):
			GlobalState.master_deck.append(fireball_res)

func _on_toilet_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(toilet_dialogue, "start")

func _on_shower_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(shower_dialogue, "start")
	var tween = create_tween()
	tween.tween_property(CanvasModulateNode, "color", COLOR_DEPRESSION, 4.0)
	has_showered = true

func _on_exit_door_interacted(_id: String) -> void:
	if not has_showered:
		DialogueSystem.start_dialogue(door_locked_dialogue, "start")
	else:
		DialogueSystem.start_dialogue(door_dialogue, "start")
		if not EventBus.dialogue_finished.is_connected(_on_door_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_door_dialogue_finished)

func _on_door_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_door_dialogue_finished)
	if DialogueSystem.dialogue_tree == door_dialogue and DialogueSystem.current_node_id == "exit_yes":
		SceneManager.transition_to_state("S_hall")
