extends Node
# Autoload singleton to handle scene transitions and fade animations.
# This ensures deterministic loading of scenes according to game states.

# CanvasLayer for scene transition overlays (e.g., fade-to-black).
var overlay_layer: CanvasLayer
var fade_rect: ColorRect

# Centralized audio players for looping tracks and ambience.
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var current_music_path: String = ""
var current_ambient_path: String = ""

# Persistent tracking of the last exploration scene visited.
# RATIONALE: Used during saving/loading to ensure that saving mid-combat
# restores the game to the exploration scene prior to the battle.
var last_exploration_scene_path: String = "res://scenes/exploration/apartment.tscn"

func _ready() -> void:
	# RATIONALE: PROCESS_MODE_ALWAYS is required so _input continues to fire after
	# get_tree().paused = true. Without it, this autoload inherits the paused state
	# and the Resume/Main Menu/Quit buttons become unresponsive.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Instantiate centralized audio streams as children.
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambience"
	add_child(ambient_player)

	# Programmatically construct overlay UI to avoid scene dependencies.
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100 # Keep on top of all other layers
	add_child(overlay_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(fade_rect)
	
	# Show the HUD initially since we load in the Apartment scene.
	call_deferred("_init_hud_on_start")
	
	# Detect startup scene to trigger correct audio.
	await get_tree().process_frame
	var current = get_tree().current_scene
	if current:
		_update_scene_audio(current.scene_file_path)

func _init_hud_on_start() -> void:
	# RATIONALE: Do not show the HUD when the game launches into the main menu.
	# The HUD is only shown when transitioning into an exploration scene.
	if has_node("/root/ExplorationHUD"):
		var current = get_tree().current_scene
		if current and current.scene_file_path != "res://scenes/ui/main_menu.tscn":
			get_node("/root/ExplorationHUD").show_hud()

# Transition to a target state by path mapping.
func transition_to_state(target_state: String) -> void:
	var target_scene_path: String = ""
	match target_state:
		"S_apt":
			target_scene_path = "res://scenes/exploration/apartment.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
		"S_hall":
			target_scene_path = "res://scenes/exploration/hallway.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
		"S_dream1":
			target_scene_path = "res://scenes/combat/grassy_field.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
		"S_class":
			target_scene_path = "res://scenes/exploration/classroom.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
		"S_dream2", "S_dream2_resume":
			target_scene_path = "res://scenes/combat/burning_village.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
		"S_ending":
			# Transition to the custom ending screen that handles visual novel ending feedback.
			target_scene_path = "res://scenes/ui/ending_screen.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
		_:
			push_error("SceneManager: Unknown target state: " + target_state)
			return
			
	# Trigger the transition process with fade effect.
	_change_scene_with_fade(target_scene_path)

# Transition directly to a scene path, used during loading to bypass match-state mapping.
func transition_to_scene_path(scene_path: String) -> void:
	if has_node("/root/ExplorationHUD"):
		if scene_path.contains("scenes/exploration/"):
			get_node("/root/ExplorationHUD").show_hud()
		else:
			get_node("/root/ExplorationHUD").hide_hud()
	_change_scene_with_fade(scene_path)

# Return to the main menu. Called by PauseManager when the player selects Main Menu.
func transition_to_state_menu() -> void:
	if has_node("/root/ExplorationHUD"):
		get_node("/root/ExplorationHUD").hide_hud()
	_change_scene_with_fade("res://scenes/ui/main_menu.tscn")

# Perform fade-out, scene change, and fade-in.
func _change_scene_with_fade(scene_path: String) -> void:
	# Keep track of exploration scenes for the save-load system.
	if scene_path.contains("scenes/exploration/"):
		last_exploration_scene_path = scene_path

	# Block user input during transition.
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to black.
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 0.5)
	await tween_out.finished
	
	# Perform the actual Godot scene transition.
	var change_result = get_tree().change_scene_to_file(scene_path)
	if change_result != OK:
		push_error("SceneManager: Failed to change scene to " + scene_path)
		
	# Wait one frame for the tree to update.
	await get_tree().process_frame
	
	# Update background music and ambience.
	_update_scene_audio(scene_path)
	
	# Fade back to transparent.
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	await tween_in.finished
	
	# Release input blocking.
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Centralized helper to map levels to active OST/Ambience and handle loops.
func _update_scene_audio(scene_path: String) -> void:
	var target_music = ""
	var target_ambient = ""
	
	# Determine target sound files based on active scene folders.
	if scene_path.contains("ui/main_menu.tscn") or scene_path.contains("ui/ending_screen.tscn"):
		target_music = "res://Assets/OST/Title Screen - OST 000.mp3"
		target_ambient = ""
	elif scene_path.contains("exploration/apartment.tscn"):
		target_music = "res://Assets/OST/Home - OST 001.mp3"
		target_ambient = "res://Assets/Sound Effects/amb_bird_chirp_bedroom_ambience_please loop.m4a"
	elif scene_path.contains("exploration/hallway.tscn"):
		target_music = "res://Assets/OST/College - OST 003.mp3"
		target_ambient = "res://Assets/Sound Effects/amb_college_hallway.wav"
	elif scene_path.contains("exploration/classroom.tscn"):
		target_music = "res://Assets/OST/College - OST 003.mp3"
		target_ambient = "res://Assets/Sound Effects/amb_classroom.wav"
	elif scene_path.contains("combat/grassy_field.tscn") or scene_path.contains("combat/burning_village.tscn"):
		target_music = "res://Assets/OST/Dream World - OST 002.mp3"
		target_ambient = ""
		
	# Play/crossfade music loops.
	if target_music != current_music_path:
		current_music_path = target_music
		if target_music != "":
			var stream = load(target_music)
			if stream:
				if "loop" in stream:
					stream.loop = true
				music_player.stream = stream
				music_player.play()
		else:
			music_player.stop()
			
	# Play/crossfade ambient loops.
	if target_ambient != current_ambient_path:
		current_ambient_path = target_ambient
		if target_ambient != "":
			var stream = load(target_ambient)
			if stream:
				if "loop" in stream:
					stream.loop = true
				ambient_player.stream = stream
				# Reset volume in case it was faded out during panic sequence
				ambient_player.volume_db = 0.0
				ambient_player.play()
		else:
			ambient_player.stop()

# Helper to dynamically play one-shot SFX sounds on demand.
func play_sfx(sfx_path: String) -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)
	var stream = load(sfx_path)
	if stream:
		player.stream = stream
		player.play()
		player.finished.connect(player.queue_free)
	else:
		player.queue_free()

# Fade out the current ambient sound (used when panic attack hallway transition triggers).
func fade_out_ambient(duration: float = 1.0) -> void:
	var tw = create_tween()
	tw.tween_property(ambient_player, "volume_db", -80.0, duration)
	await tw.finished
	ambient_player.stop()
	ambient_player.volume_db = 0.0
