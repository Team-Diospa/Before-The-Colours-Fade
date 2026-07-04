extends Node2D

var cutscene_phase1 = {
	"start": {
		"text": "Hahahahahh...",
		"speaker": "",
		"next": "step2"
	},
	"step2": {
		"text": "Hahahhahhahh...",
		"speaker": "",
		"next": "step3"
	},
	"step3": {
		"text": "Promise me we'll always be at each other side.",
		"speaker": "",
		"next": "step4"
	},
	"step4": {
		"text": "I promise.",
		"speaker": "",
		"next": "step5"
	},
	"step5": {
		"text": "You can always count on me, you know. Just say the word, and i'll be there to help you.",
		"speaker": "",
		"next": "step6"
	},
	"step6": {
		"text": "Hahhaha...I know. Thanks,---",
		"speaker": "",
		"next": ""
	}
}

var cutscene_phase2 = {
	"start": {
		"text": "...",
		"speaker": "",
		"next": ""
	}
}

var cutscene_phase3 = {
	"start": {
		"text": "...",
		"speaker": "",
		"next": ""
	}
}

@onready var image_display = $ImageDisplay
var current_phase = 1

func _ready() -> void:
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	image_display.texture = null
	
	# Full black screen dialog
	DialogueSystem.start_dialogue(cutscene_phase1, "start", true)
	
	# Creepy ambient noise
	SceneManager.play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_20hz_bass (too loud, lower the volume a lot please).mp3", -8.0)
	
	# Start heartbeat loop
	_play_heartbeat()

func _play_heartbeat() -> void:
	if not is_inside_tree(): return
	EventBus.play_sound.emit("sfx_single_heartbeat")
	await get_tree().create_timer(1.8).timeout
	if is_inside_tree():
		_play_heartbeat()

func _on_dialogue_finished() -> void:
	if current_phase == 1:
		current_phase = 2
		# Dialogue hidden. Show first image (normal smile)
		image_display.texture = load("res://Assets/Cutscenes/intro_4.png")
		
		# Wait 3 seconds
		await get_tree().create_timer(3.0).timeout
		
		# Show second image (smile with no face)
		image_display.texture = load("res://Assets/Cutscenes/intro_3.png")
		
		# Wait 3 seconds
		await get_tree().create_timer(3.0).timeout
		
		# Move to Phase 2: Show dead photo and start dialogue (NORMAL mode, not fullscreen)
		image_display.texture = load("res://Assets/Cutscenes/intro_2.png")
		DialogueSystem.start_dialogue(cutscene_phase2, "start", false)
		
	elif current_phase == 2:
		current_phase = 3
		# Move to Phase 3: Show sad with suit and start dialogue (NORMAL mode, not fullscreen)
		image_display.texture = load("res://Assets/Cutscenes/intro_1.png")
		DialogueSystem.start_dialogue(cutscene_phase3, "start", false)
		
	elif current_phase == 3:
		# Finished
		EventBus.dialogue_finished.disconnect(_on_dialogue_finished)
		SceneManager.stop_ambient()
		SceneManager.transition_to_state("S_apt")
