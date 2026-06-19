extends Node2D
# Level script for the Hallway scene (S_hall).
# Triggers the passive panic attack sequence and shifts to S_dream1.

# Panic attack narrative dialogue tree.
var panic_dialogue: Dictionary = {
	"start": {
		"text": "Living in fiction is fun, isn't it? When it's too loud, just treat it like a game.",
		"next": "panic_step2"
	},
	"panic_step2": {
		"text": "Live your life a little...",
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
		
		# Play memory dialogue.
		DialogueSystem.start_dialogue(panic_dialogue, "start")
		
		# Connect to dialogue finish to perform transition.
		if not EventBus.dialogue_finished.is_connected(_on_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_dialogue_finished)

# Bound listener callback to avoid signal reference leaks.
func _on_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_dialogue_finished)
	GlobalState.set_flag("shift_1_done", true)
	SceneManager.transition_to_state("S_dream1")

