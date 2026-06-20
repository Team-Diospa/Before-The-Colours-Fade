extends Node2D
# Level script for the Hallway scene (S_hall).
# Triggers the passive panic attack sequence and shifts to S_dream1.
# Spawns student NPCs and interactive fixtures to extend gameplay depth.
# RATIONALE: The hallway represents a threshold of mounting social and academic anxiety.
# Adding students whispering, a broken support hotline flyer, and a cold water fountain
# grounds the transition in Loewenstein's information-gaps and Bartlett's reconstructive memory theory.

const INTERACTABLE_SCENE = preload("res://core/components/interactable.tscn")

# Panic attack and dimension 1 trigger dialogue.
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

# Dialogue trees for student NPCs.
# RATIONALE: Peer A highlights the gear-brake schematic circled in the notebook margins.
# Peer B whispers gossip about the bridge project accident, establishing the narrative void.
var peer_a_dialogue: Dictionary = {
	"start": {
		"text": "Peer A: I stayed up until 3 AM and I still can't reconcile the math. The frame design... why does it convert momentum? It feels backwards.",
		"next": "peer_a_2"
	},
	"peer_a_2": {
		"speaker": "Hilbert",
		"text": "A gear-brake converts momentum into resistance. It stabilizes structural shear limits.",
		"next": "peer_a_3"
	},
	"peer_a_3": {
		"text": "Peer A: ...How do you know that? We haven't even covered shear limits in this chapter. Did you... get it from the old blueprints?",
		"next": "peer_a_4"
	},
	"peer_a_4": {
		"speaker": "Hilbert",
		"text": "Blueprints. Yes. Something like that.",
		"next": ""
	}
}

var peer_b_dialogue: Dictionary = {
	"start": {
		"text": "You hear whispering as you walk past. You catch fragments of their conversation.",
		"next": "whisper_2"
	},
	"whisper_2": {
		"text": "Peer B: ...Hickman. He looks completely disconnected, doesn't he? Ever since last year's incident on the bridge project, he's like a ghost walking around.",
		"next": "whisper_3"
	},
	"whisper_3": {
		"text": "You pull your collar up. The words stick to your chest, heavy and cold.",
		"next": ""
	}
}

# Dialogue trees for Bulletin Board.
# RATIONALE: Clues like the green scarf tie directly into the wardrobe description in the apartment.
var board_dialogue: Dictionary = {
	"start": {
		"text": "The bulletin board is covered in overlapping notices and flyers.",
		"next": "board_choices"
	},
	"board_choices": {
		"text": "What do you want to read?",
		"options": [
			{"text": "Check exam schedules", "next": "board_exam"},
			{"text": "Check support hotlines", "next": "board_support"},
			{"text": "Look at the lost notice", "next": "board_lost"}
		]
	},
	"board_exam": {
		"text": "Mechanics of Materials Quiz 2: Monday 9:00 AM. Room 304. Weight: 50% of overall grade. No calculators or formula sheets permitted.",
		"next": ""
	},
	"board_support": {
		"text": "Student Welfare Center. 'You don't have to carry the weight alone. Safe space. Confidentiality guaranteed.' The corner with the phone number is torn off.",
		"next": ""
	},
	"board_lost": {
		"text": "Lost: Green knitted scarf. Left in Room 304 last Tuesday. If found, please return to student lobby. It was a gift.",
		"next": ""
	}
}

# Dialogue trees for Water Fountain.
# RATIONALE: Provides a physical choice that interacts directly with turn 1 stats.
var fountain_dialogue: Dictionary = {
	"start": {
		"text": "The metal of the water fountain is cold. A low hum vibrates through the pipework.",
		"next": "fountain_choices"
	},
	"fountain_choices": {
		"text": "Drink some water?",
		"options": [
			{"text": "Yes - wash down the dryness", "next": "fountain_yes"},
			{"text": "No - move on", "next": "fountain_no"}
		]
	},
	"fountain_yes": {
		"text": "The water is freezing cold, bordering on metallic. It shocks your system, forcing you to slow your breathing.",
		"next": "fountain_yes_sys"
	},
	"fountain_yes_sys": {
		"text": "[System]: Cold water settles your breathing. (+5 starting Block on turn 1 of combat).",
		"next": ""
	},
	"fountain_no": {
		"text": "You pass by. The dry taste in your mouth remains.",
		"next": ""
	}
}

# Reference to the panic Area2D trigger node.
@onready var trigger_area = $PanicTrigger
var is_triggered: bool = false

func _ready() -> void:
	# Connect collision entry signal.
	trigger_area.body_entered.connect(_on_panic_trigger_body_entered)

	# Move panic trigger further right to give player more space to explore.
	trigger_area.position.x = 850

	# Programmatically spawn interactables to prevent scene file corruption.
	_spawn_interactable("board", "Press E to read Bulletin Board", Vector2(200, 500))
	_spawn_interactable("peer_a", "Press E to talk to Student", Vector2(350, 500))
	_spawn_interactable("peer_b", "Press E to talk to Student", Vector2(550, 500))
	_spawn_interactable("fountain", "Press E to use Water Fountain", Vector2(700, 500))

# Instantiates and wires an interactable component at the given coordinate.
func _spawn_interactable(id: String, prompt: String, pos: Vector2) -> void:
	var obj = INTERACTABLE_SCENE.instantiate()
	obj.interaction_id = id
	obj.prompt_message = prompt
	obj.position = pos
	obj.interacted.connect(_on_object_interacted)
	add_child(obj)

# Routes interaction signals to their respective dialogue dictionaries.
func _on_object_interacted(id: String) -> void:
	match id:
		"board":
			DialogueSystem.start_dialogue(board_dialogue, "start")
		"peer_a":
			DialogueSystem.start_dialogue(peer_a_dialogue, "start")
		"peer_b":
			DialogueSystem.start_dialogue(peer_b_dialogue, "start")
		"fountain":
			# Gated so player only drinks once.
			if GlobalState.starting_block_modifier > 0:
				DialogueSystem.start_dialogue({"start": {"text": "You have had enough water. Your throat is no longer dry.", "next": ""}}, "start")
				return
			DialogueSystem.start_dialogue(fountain_dialogue, "start")
			if not EventBus.dialogue_finished.is_connected(_on_fountain_dialogue_finished):
				EventBus.dialogue_finished.connect(_on_fountain_dialogue_finished)

# Applies starting stats if the player chose to drink water.
func _on_fountain_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_fountain_dialogue_finished)
	if DialogueSystem.dialogue_tree == fountain_dialogue and DialogueSystem.current_node_id == "fountain_yes_sys":
		# Only overwrite starting block modifier if window didn't already set it, or add it up.
		# Let's stack them so that full exploration rewards the player with a safe first round (+10 block).
		GlobalState.starting_block_modifier += 5

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
