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

# Dictionary representing dialogue structures.
var bed_dialogue: Dictionary = {
	"start": {
		"text": "Sleep Again?",
		"options": [
			{"text": "Yes", "next": "bed_yes"},
			{"text": "No", "next": "bed_no"}
		]
	},
	"bed_yes": {
		"text": "Your alarm rings loudly! Morning call reminder: you must attend the monday lecture quiz today.",
		"next": ""
	},
	"bed_no": {
		"text": "Probably later.",
		"next": ""
	}
}

var desk_dialogue: Dictionary = {
	"start": {
		"text": "Papers... Unfinished... Not Much. Open Drawer?",
		"options": [
			{"text": "Yes", "next": "open_drawer"},
			{"text": "No", "next": "close_drawer"}
		]
	},
	"open_drawer": {
		"text": "A Picture... Not Important.",
		"next": ""
	},
	"close_drawer": {
		"text": "You leave the drawer shut.",
		"next": ""
	}
}

var guitar_dialogue: Dictionary = {
	"start": {
		"text": "Not really in the mood to play.",
		"next": ""
	}
}

var toilet_dialogue: Dictionary = {
	"start": {
		"text": "Just a toilet. Nothing Much.",
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
	DialogueSystem.start_dialogue(bed_dialogue, "start")

func _on_guitar_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(guitar_dialogue, "start")

func _on_desk_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(desk_dialogue, "start")

func _on_toilet_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(toilet_dialogue, "start")

func _on_shower_interacted(_id: String) -> void:
	# Trigger the shower dialogue progression.
	DialogueSystem.start_dialogue(shower_dialogue, "start")
	
	# Linear color transition of the room representing mood shift.
	var tween = create_tween()
	tween.tween_property(CanvasModulateNode, "color", COLOR_DEPRESSION, 4.0)
	
	has_showered = true

func _on_exit_door_interacted(_id: String) -> void:
	if not has_showered:
		# Block leaving.
		DialogueSystem.start_dialogue(door_locked_dialogue, "start")
	else:
		DialogueSystem.start_dialogue(door_dialogue, "start")
		# Connect class method to dialogue finish to perform transition.
		if not EventBus.dialogue_finished.is_connected(_on_door_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_door_dialogue_finished)

# Bound listener callback to avoid signal reference leaks.
func _on_door_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_door_dialogue_finished)
	if DialogueSystem.dialogue_tree == door_dialogue and DialogueSystem.current_node_id == "exit_yes":
		SceneManager.transition_to_state("S_hall")
