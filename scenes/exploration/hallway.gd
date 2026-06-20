extends Node2D
# Level script for the Hallway scene (S_hall).
# Triggers the passive panic attack sequence and shifts to S_dream1.
# RATIONALE: The hallway is the threshold between reality and dream. It must feel claustrophobic
# and mentally pressured before the world dissolves. The sequence follows the script beat-for-beat:
# crowd murmur, chest tightening, the recalled quote from "someone", and then the fall inward.

# Panic attack and dimension 1 trigger dialogue.
# RATIONALE: The quote is attributed to "someone" - not named, per the low-salience design rule.
# The player infers who "someone" might be from the nine puzzle pieces, not from this scene.
var panic_dialogue: Dictionary = {
	"start": {
		"text": "The hallway is long. Too long. The crowd noise bounces off the walls like static.",
		"next": "panic_step2"
	},
	"panic_step2": {
		"text": "Your breathing is off. You count the tiles underfoot without meaning to.",
		"next": "panic_step3"
	},
	"panic_step3": {
		"text": "Chest. Tight. The quiz is in ten minutes and your notes feel like someone else's handwriting.",
		"next": "panic_step4"
	},
	"panic_step4": {
		# RATIONALE: The quote surfaces here as a memory, not attributed to anyone.
		# It is a tool the player uses, not an explanation the game gives.
		"text": "Then something surfaces. A voice, somewhere. Someone once said:",
		"next": "panic_step5"
	},
	"panic_step5": {
		"text": "Living in fiction is fun, isn't it? When it's too loud, just treat it like a game. Live your life a little.",
		"next": "panic_step6"
	},
	"panic_step6": {
		"text": "You close your eyes. The murmur on the background is suddenly gone.",
		"next": "panic_step7"
	},
	"panic_step7": {
		"text": "Only silence. Only darkness. No, not darkness.",
		"next": "panic_step8"
	},
	"panic_step8": {
		"text": "Calmness.",
		"next": ""
	}
}

# Reference to the panic Area2D trigger node.
@onready var trigger_area = $PanicTrigger
var is_triggered: bool = false

func _ready() -> void:
	# Connect collision entry signal.
	trigger_area.body_entered.connect(_on_panic_trigger_body_entered)

func _on_panic_trigger_body_entered(body: Node2D) -> void:
	if is_triggered:
		return
		
	if body is ExplorationPlayer:
		is_triggered = true
		
		# Lock UI and fade background sound.
		EventBus.lock_player_ui.emit()
		EventBus.play_sound.emit("murmur_fade_out")
		
		# Play the full atmospheric panic and memory sequence.
		DialogueSystem.start_dialogue(panic_dialogue, "start")
		
		# Connect to dialogue finish to perform transition.
		if not EventBus.dialogue_finished.is_connected(_on_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_dialogue_finished)

# Bound listener callback to avoid signal reference leaks.
func _on_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_dialogue_finished)
	GlobalState.set_flag("shift_1_done", true)
	SceneManager.transition_to_state("S_dream1")
