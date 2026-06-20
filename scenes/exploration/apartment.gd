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
		"text": "The alarm screams. It feels like a drilling machine boring into your skull. Sink back into the warm, heavy dark? Or face the grey morning?",
		"options": [
			{"text": "Close your eyes. Just five more minutes.", "next": "bed_yes_1"},
			{"text": "Force yourself up. Drag your bones out of bed.", "next": "bed_no_1"}
		]
	},
	"bed_yes_1": {
		"text": "You pull the blanket over your head. The fabric smells faintly of old rain and copper.",
		"next": "bed_yes_1_nn"
	},
	"bed_yes_1_nn": {
		"text": "n.n.: If you close your eyes, I can stay. Please... don't let the light wash me away.",
		"next": "bed_yes_2"
	},
	"bed_yes_2": {
		"text": "You drift. The dream is a warm city of gold and clockwork, but when you gasp awake, the room is freezing, the clock shows 8:45 AM, and your limbs feel like lead.",
		"next": "bed_yes_sys"
	},
	"bed_yes_sys": {
		"text": "[System]: The extra sleep restores your physical reserves (+10 Max HP), but you wake up late and sluggish (-1 starting Energy on turn 1).",
		"next": ""
	},
	"bed_no_1": {
		"text": "You kick the blanket off. Staring at the ceiling, your chest feels hollow, like someone scooped out the center of you while you slept.",
		"next": "bed_no_2"
	},
	"bed_no_2": {
		"text": "Hilbert: I'm awake. I'm still here. I have to stay awake.",
		"next": "bed_no_sys"
	},
	"bed_no_sys": {
		"text": "[System]: You force yourself into alertness (+1 starting Energy on turn 1), but the sudden shock drains your physical resilience (-5 Max HP).",
		"next": ""
	}
}

var desk_dialogue: Dictionary = {
	"start": {
		"text": "A wooden desk covered in a thin film of grey dust. A blunt pencil lies next to a worn drawing notebook.",
		"options": [
			{"text": "Open the drawer.", "next": "open_drawer_1"},
			{"text": "Leave it alone.", "next": "close_drawer"}
		]
	},
	"open_drawer_1": {
		"text": "The drawer screeches open. Inside is a framed photograph of two boys laughing in front of a half-finished mechanical project.",
		"next": "open_drawer_1_photo"
	},
	"open_drawer_1_photo": {
		"text": "You look at the boy on the right. His face is... gone. Not faded. It looks as if someone took a box cutter and aggressively carved his face out of the photo, leaving a jagged, white hole.",
		"next": "open_drawer_2"
	},
	"open_drawer_2": {
		"text": "Hilbert: Why did I scratch it? Did I do this? I... I can't remember what he looked like. My chest hurts. Why can't I remember his name?",
		"next": "open_drawer_sys"
	},
	"open_drawer_sys": {
		"text": "[System]: Inventions Notebook acquired -> The pencil sharpens into a Sword (Double Strike added to deck). The notebook thickens into a Spellbook (Fireball added to deck).",
		"next": ""
	},
	"close_drawer": {
		"text": "You pull your hand back. The dust on the wood looks like ashes. Some memories are better left buried.",
		"next": ""
	}
}

var guitar_dialogue: Dictionary = {
	"start": {
		"text": "An acoustic guitar rests in the corner, three of its strings snapped and curled like dead spiders. Touch the wood?",
		"options": [
			{"text": "Pluck the remaining strings.", "next": "guitar_yes_1"},
			{"text": "Ignore the dust.", "next": "guitar_no"}
		]
	},
	"guitar_yes_1": {
		"text": "You pluck a chord. The sound is flat, out of tune, yet it echoes through the apartment like a deep, vibrating bell.",
		"next": "guitar_yes_1_whistle"
	},
	"guitar_yes_1_whistle": {
		"text": "For a split second, you hear a second instrument harmonizing with you—a bright, mechanical whistle, humming a melody you used to know by heart.",
		"next": "guitar_yes_2"
	},
	"guitar_yes_2": {
		"text": "Hilbert: That tune... we used to play it in the backyard when it rained. Who was... who was whistling?",
		"next": "guitar_yes_sys"
	},
	"guitar_yes_sys": {
		"text": "[System]: Faint melody recalled -> Your spirits lift (HP fully restored), and memories of battle take shape (Heavy Slash and Thunder added to deck).",
		"next": ""
	},
	"guitar_no": {
		"text": "You turn away. The silence of the room is louder than any chord you could play.",
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
