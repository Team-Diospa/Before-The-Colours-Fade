extends Node2D

var shower_dialogue: Dictionary = {
	"start": {
		# RATIONALE: Visual novel dialogue expansion (28 beats) to create atmospheric attunement (Massumi).
		"text": "A shower.",
		"next": "shower_2"
	},
	"shower_2": {
		"text": "The bathroom door creaks as you push it open. The air inside is cold and damp, smelling faintly of old grout and lime.",
		"next": "shower_3"
	},
	"shower_3": {
		"text": "You turn the shower dial. Behind the wall, the pipes screech in protest, a metal-on-metal grind that makes you wince.",
		"next": "shower_4"
	},
	"shower_4": {
		"text": "You wait. The water takes a full two minutes to heat up, running clear and freezing into the plastic drain.",
		"next": "shower_5"
	},
	"shower_5": {
		"text": "You step into the cold stream anyway. The shock is immediate, a freezing needle-prick that makes you gasp.",
		"next": "shower_6"
	},
	"shower_6": {
		"text": "The cold water runs down your back, stealing the remaining warmth from your sleep.",
		"next": "shower_7"
	},
	"shower_7": {
		"text": "Slowly, the water begins to turn lukewarm. A thin veil of steam rises, clinging to the cold tiles.",
		"next": "shower_8"
	},
	"shower_8": {
		"text": "The steam fogs up the small, square mirror above the sink, hiding your reflection behind a white mist.",
		"next": "shower_9"
	},
	"shower_9": {
		"text": "You step out of the stream for a moment and walk to the sink. You run your hand across the glass, clearing a circle.",
		"next": "shower_10"
	},
	"shower_10": {
		"text": "Your reflection looks back. Pale skin. Dark circles under your eyes. Wet hair plastered to your forehead.",
		"next": "shower_11"
	},
	"shower_11": {
		"text": "You look like a stranger. A drawing of someone you used to know, sketched with a soft graphite pencil that has begun to smudge.",
		"next": "shower_12"
	},
	"shower_12": {
		"text": "You trace your finger on the steam-covered glass. You write the letter 'H'. Then a space. Then you stop.",
		"next": "shower_13"
	},
	"shower_13": {
		"text": "You want to write his initials next to yours, like you used to do on the dusty windows of the workshop.",
		"next": "shower_14"
	},
	"shower_14": {
		"text": "But you cannot bring yourself to do it. The space remains empty. A silent gap on the glass.",
		"next": "shower_15"
	},
	"shower_15": {
		"text": "You watch the condensation collect on the letters. A single drop runs down, melting the 'H' into a long, wet streak.",
		"next": "shower_16"
	},
	"shower_16": {
		"text": "You return to the shower. The water is warmer now, but the heat feels distant, like it is warming someone else's skin.",
		"next": "shower_17"
	},
	"shower_17": {
		"text": "You stare blankly at the drain. The water swirls in a slow circle, carrying away grey suds and dust.",
		"next": "shower_18"
	},
	"shower_18": {
		# RATIONALE: Focus on physical steam blanket and sound isolation.
		# Blocks out external noises to highlight isolation without explicit suicidal thoughts.
		"text": "The steam grows thicker, wrapping around you like a heavy blanket. The sound of the rushing water blocks out the rest of the world, masking the ticking clock and the dripping ceiling.",
		"next": "shower_19"
	},
	"shower_19": {
		# RATIONALE: Physical contact with cold environment to contrast the lukewarm water.
		"text": "You press your forehead against the cold tiles, letting the stream hit the back of your neck. The water is losing its warmth, turning slowly back to lukewarm, then cold.",
		"next": "shower_20"
	},
	"shower_20": {
		# RATIONALE: Focus on spatial disorientation and mist masking clutter.
		"text": "The mist makes the boundaries of the small stall disappear. For a few seconds, there are no walls, no clutter, no books - just the white noise of water hitting plastic.",
		"next": "shower_21"
	},
	"shower_21": {
		"text": "The phone rings from the bathroom shelf, a sharp, electronic chirp that cuts through the steam. The quiz is in an hour.",
		"next": "shower_22"
	},
	"shower_22": {
		"text": "You sigh, blinking water from your eyes. You lather the soap, your movements mechanical and slow.",
		"next": "shower_23"
	},
	"shower_23": {
		"text": "You continue to stare at the wall, not realizing you have swallowed a mouthful of soap foam.",
		"next": "shower_24"
	},
	"shower_24": {
		"text": "The taste is bitter, chemical. You spit it out, but the soapy residue remains on your tongue, a sharp reminder of your distraction.",
		"next": "shower_25"
	},
	"shower_25": {
		"text": "You know you should care about the chemical taste, about your health, about the test. But the spark is simply gone.",
		"next": "shower_26"
	},
	"shower_26": {
		"text": "Standing there with a numb mind, on the edge of something you cannot name, the only thing you feel is an empty, heavy silence.",
		"next": "shower_27"
	},
	"shower_27": {
		"text": "Mechanically, you turn the dial off. The water stops. The silence that follows is louder than the shower.",
		"next": "shower_28"
	},
	"shower_28": {
		"text": "You grab your towel, holding onto whatever fractured piece of peace is still left in the damp room.",
		"next": ""
	}
}

var toilet_dialogue: Dictionary = {
	"start": {
		"text": "Just a toilet. Nothing much.",
		"next": ""
	}
}

var apt_door_dialogue = {
	"start": {
		"text": "Return to the bedroom?",
		"options": [
			{"text": "Yes", "next": "exit"},
			{"text": "No", "next": ""}
		]
	},
	"exit": {
		"text": "You push the door open.",
		"next": ""
	}
}

func _ready() -> void:
	$Shower.interacted.connect(_on_shower_interacted)
	$Toilet.interacted.connect(_on_toilet_interacted)
	$AptDoor.interacted.connect(_on_apt_door_interacted)
	
	# Ensure CanvasModulate exists for the shower depression effect
	if not has_node("CanvasModulate"):
		var cm = CanvasModulate.new()
		cm.name = "CanvasModulate"
		cm.color = Color(1, 1, 1, 1)
		add_child(cm)
		
	if SceneManager.previous_scene_name == "apartment" and has_node("Player"):
		$Player.global_position.x = 941

func _on_shower_interacted(_id: String) -> void:
	if GlobalState.has_flag("has_showered"):
		DialogueSystem.start_dialogue({"start": {"text": "You've already showered. The water has run cold.", "next": ""}}, "start")
		return
		
	# Play the shower running water sound effect
	EventBus.play_sound.emit("shower")
	
	# Shower tints the room dark as per script alur.md atmosphere note.
	var tween = create_tween()
	tween.tween_property($CanvasModulate, "color", Color(0.4, 0.4, 0.6), 5.0)
	
	GlobalState.set_flag("has_showered", true)
	
	# Pass true to trigger the sensory-based shower monologue sequence in fullscreen cutscene mode.
	DialogueSystem.start_dialogue(shower_dialogue, "start", true)
	if not EventBus.dialogue_finished.is_connected(_on_shower_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_shower_dialogue_finished)

func _on_shower_dialogue_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_shower_dialogue_finished)
	if DialogueSystem.dialogue_tree == shower_dialogue:
		EventBus.stop_sound.emit("shower")
		EventBus.stop_sound.emit("sfx_shower_run")
		
		# Advance objective directly via HUD if it exists
		if has_node("/root/ExplorationHUD"):
			get_node("/root/ExplorationHUD").set_objective("Leave the apartment.")
			# Keep the local state roughly in sync just in case
			GlobalState.set_flag("objective_exit", true)

func _on_toilet_interacted(_id: String) -> void:
	EventBus.play_sound.emit("toilet_flush")
	DialogueSystem.start_dialogue(toilet_dialogue, "start")

func _on_apt_door_interacted(_id: String) -> void:
	DialogueSystem.start_dialogue(apt_door_dialogue, "start")
	if not EventBus.dialogue_finished.is_connected(_on_apt_door_finished):
		EventBus.dialogue_finished.connect(_on_apt_door_finished)

func _on_apt_door_finished() -> void:
	EventBus.dialogue_finished.disconnect(_on_apt_door_finished)
	if DialogueSystem.current_node_id == "exit":
		SceneManager.transition_to_state("S_apt")