extends Node
# Autoload singleton to handle scene transitions and fade animations.
# This ensures deterministic loading of scenes according to game states.

# CanvasLayer for scene transition overlays (e.g., fade-to-black).
var overlay_layer: CanvasLayer
var fade_rect: ColorRect

# Centralized AudioStreamPlayers for background music (OST) and environmental ambience
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var looping_sfx_players: Array[AudioStreamPlayer] = []
var active_sfx_players: Dictionary = {}

# Persistent tracking of the last exploration scene visited.
# RATIONALE: Used during saving/loading to ensure that saving mid-combat
# restores the game to the exploration scene prior to the battle.
var last_exploration_scene_path: String = "res://scenes/exploration/apartment.tscn"
var previous_scene_name: String = ""

func _ready() -> void:
	# Programmatically construct overlay UI to avoid scene dependencies.
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 100 # Keep on top of all other layers
	add_child(overlay_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(fade_rect)
	
	# Ensure Music and SFX buses exist programmatically.
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		
	# Initialize audio stream player nodes for central soundtrack and background hums
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Master"
	add_child(ambient_player)
	
	# Connect global sound effect trigger signal
	EventBus.play_sound.connect(play_sfx)
	EventBus.stop_sound.connect(stop_sfx)
	
	# Show the HUD initially since we load in the Apartment scene.
	call_deferred("_init_hud_on_start")
	
	# Check and start playing initial music based on the loaded start scene
	call_deferred("_start_initial_music")

func _init_hud_on_start() -> void:
	# RATIONALE: Do not show the HUD when the game launches into the main menu.
	# The HUD is only shown when transitioning into an exploration scene.
	if has_node("/root/ExplorationHUD"):
		var current = get_tree().current_scene
		if current and current.scene_file_path != "res://scenes/ui/main_menu.tscn":
			get_node("/root/ExplorationHUD").show_hud()

# Helper to automatically kickstart music/loops depending on the current active scene at startup
func _start_initial_music() -> void:
	var current = get_tree().current_scene
	if current:
		var path = current.scene_file_path
		if "main_menu" in path:
			play_music("res://Assets/OST/Title Screen - OST 000.ogg", -2.0)
			stop_ambient()
		elif "apartment" in path:
			play_music("res://Assets/OST/Home - OST 001.ogg", -2.0)
			play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_bird_chirp_bedroom_ambience_please loop.mp3", -8.0)
		elif "hallway" in path:
			play_music("res://Assets/OST/College - OST 002.ogg", -2.0)
			play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_college_hallway.mp3", -6.0)
		elif "classroom" in path:
			play_music("res://Assets/OST/College - OST 002.ogg", -2.0)
			play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_classroom.mp3", -6.0)
		elif "grassy_field" in path or "burning_village" in path:
			play_music("res://Assets/OST/Dreamworld - OST 003.mp3", -3.0)
			stop_ambient()

# Helper to play and swap background tracks safely, avoiding loading if already playing
func play_music(track_path: String, volume_db: float = 0.0) -> void:
	if not music_player:
		return
	if music_player.stream and music_player.stream.resource_path == track_path:
		music_player.volume_db = volume_db
		if not music_player.playing:
			music_player.play()
		return
	
	music_player.stop()
	var stream = load(track_path)
	if stream:
			if "loop" in stream:
				stream.loop = true
			elif "loop_mode" in stream:
				stream.loop_mode = 1 # AudioStreamWAV.LOOP_FORWARD
			music_player.stream = stream
			music_player.volume_db = volume_db
			music_player.play()

# Helper to load and loop environmental ambient noises
func play_ambient(track_path: String, volume_db: float = 0.0) -> void:
	if not ambient_player:
		return
	if ambient_player.stream and ambient_player.stream.resource_path == track_path:
		ambient_player.volume_db = volume_db
		if not ambient_player.playing:
			ambient_player.play()
		return
		
	ambient_player.stop()
	var stream = load(track_path)
	if stream:
			if "loop" in stream:
				stream.loop = true
			elif "loop_mode" in stream:
				stream.loop_mode = 1 # AudioStreamWAV.LOOP_FORWARD
			ambient_player.stream = stream
			ambient_player.volume_db = volume_db
			ambient_player.play()

# Helper to stop ambient noise when loading a quiet or combat scene
func stop_ambient() -> void:
	if ambient_player and ambient_player.playing:
		ambient_player.stop()
	
	# Also stop any looping sfx players when stopping ambience (e.g. changing scenes)
	for p in looping_sfx_players:
		if is_instance_valid(p):
			p.stop()
			p.queue_free()
	looping_sfx_players.clear()

func stop_all_oneshot_sfx() -> void:
	for sound_name in active_sfx_players.keys():
		stop_sfx(sound_name)

# Central dispatcher for one-shot sound effects in response to gameplay triggers.
# RATIONALE: Key names here are the canonical "sound_cue_id" strings emitted via EventBus.play_sound.
# The actual file path is resolved here. Any mismatch between emit site and this match block
# means silence. Keep this list in sync with the design doc naming table.
func play_sfx(sound_name: String) -> void:
	var sfx_path = ""
	var volume_db = 0.0
	var cancel_duplicates = false
	
	match sound_name:
		# ---- REALITY WORLD SFX ----
		# Triggered once at opening narration start, not looped.
		"sfx_alarm_buzz", "alarm":
			# ACTUAL FILE: sfx_alarm_buzz (just use once please, don't loop or repeat).mp3
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_alarm_buzz (just use once please, don't loop or repeat).mp3"
			volume_db = -4.0
			cancel_duplicates = true
		# Triggered when player interacts with the bed.
		"sfx_bed_creak", "bed_creak":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_bed_creak.mp3"
			volume_db = 0.0
		# Triggered during shower interaction in apartment.
		"sfx_shower_run", "shower":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_shower_running.mp3"
			volume_db = -4.0
		# Clock tick - looped via filename check. Only valid in apartment/classroom.
		"sfx_clock_tick", "clock":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_clock_ticking_please loop.mp3"
			volume_db = -6.0
			cancel_duplicates = true
		# Locker metal sound for classroom interactable.
		"sfx_locker_open", "locker_open":
			# ASSET NOT YET ON DISK - add sfx_locker_open.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_locker_open.wav"
			volume_db = 0.0
		# Chalk drawing on blackboard.
		"sfx_chalk_formula", "chalk_formula":
			# ASSET NOT YET ON DISK - add sfx_chalk_formula.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_chalk_formula.wav"
			volume_db = 0.0
		# Toilet flush in apartment.
		"sfx_toilet_flush", "toilet_flush":
			# ASSET NOT YET ON DISK - add sfx_toilet_flush.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_toilet_flush.wav"
			volume_db = 0.0
		# Kettle boil in apartment kitchen.
		"sfx_kettle_boil", "kettle_boil":
			# ASSET NOT YET ON DISK - add sfx_kettle_boil.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_kettle_boil.wav"
			volume_db = 0.0
		# Desk/wardrobe wooden drawer pull.
		"sfx_wood_drawer", "wood_drawer":
			# ASSET NOT YET ON DISK - add sfx_wood_drawer.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_wood_drawer.wav"
			volume_db = 0.0
		# Papers shuffle on desk.
		"sfx_paper_rustle", "paper_rustle":
			# ASSET NOT YET ON DISK - add sfx_paper_rustle.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_paper_rustle.wav"
			volume_db = 0.0
		# School bell trigger at classroom entry.
		"sfx_school_bell", "bell":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_school_bell (a bit loud, lower the volume).mp3"
			volume_db = -16.0
			cancel_duplicates = true
		# Footstep - single one-shot.
		"sfx_footsteps_heavy", "footstep":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_one_footstep.mp3"
			volume_db = -4.0
		# Fluorescent/light-flicker in classroom.
		"sfx_light_flicker", "fluorescent_light":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_fluorescent_light.mp3"
			volume_db = -6.0
		# Pencil scratching during quiz/classroom.
		"sfx_pen_scratch", "pen_scratch":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_pen_scratch.mp3"
			volume_db = -4.0
		# Low 20hz bass used in moments of dread/tension.
		"sfx_memory_hum", "bass":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/amb_20hz_bass (too loud, lower the volume a lot please).mp3"
			volume_db = -24.0
		# Single heartbeat.
		"sfx_heartbeat", "heartbeat":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_single_heartbeat.mp3"
			volume_db = -2.0
		# Glass shatter for dream-world transition.
		"sfx_glass_shatter", "glass_break":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_glass_break.mp3"
			volume_db = -2.0
		# Lighter click.
		"sfx_lighter", "lighter":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_lighter.mp3"
			volume_db = -4.0
		# Murmur crowd fade - this is a special ambient tween, handled here.
		"murmur_fade_out":
			# Gradually damp the ambient volume before silencing, representing onset of panic.
			var tween = create_tween()
			tween.tween_property(ambient_player, "volume_db", -80.0, 2.0)
			await tween.finished
			ambient_player.stop()
			return
			
		# ---- DREAM WORLD SFX ----
		# Guitar chord - plays ONCE after guitar interaction resolves. Stop it explicitly on scene leave.
		"amb_guitar_chords", "guitar":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/guitar_chord.mp3"
			volume_db = 0.0
			cancel_duplicates = true
			
			# RATIONALE: Duck the OST when the guitar chord is playing so they don't clash.
			var orig_vol = music_player.volume_db
			var tween = create_tween()
			tween.tween_property(music_player, "volume_db", -80.0, 0.5)
			
			# Hook into the finished signal of this specific SFX instance via active_sfx_players
			# after it's created, but since we create it below, we pass a deferred function call.
			call_deferred("_connect_guitar_ducking", orig_vol)
		
		# ---- UI / MENU SFX ----
		# Typewriter click for dialogue text scroll.
		"ui_typewriter_click", "typewriter":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_ui_typewriter_click (one).mp3"
			volume_db = -33.0
			cancel_duplicates = true
		# Dialogue skip button click.
		"ui_dialogue_skip":
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_dialogue_skip.mp3"
			volume_db = -14.0
			cancel_duplicates = true
		# Generic hover tick for buttons (menus, pause, settings).
		"ui_hover_tick", "hover", "click":
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_ui_hover_tick.mp3"
			volume_db = -8.0
			cancel_duplicates = true
		# Pause booklet open/close.
		"ui_booklet_open":
			# ASSET NOT YET ON DISK - add ui_booklet_open.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/ui_booklet_open.wav"
			volume_db = 0.0
		# Victory and defeat stings.
		"ui_victory_chord", "victory_chord":
			# ASSET NOT YET ON DISK - add ui_victory_chord.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/ui_victory_chord.wav"
			volume_db = 0.0
		"ui_defeat_strike", "defeat_strike":
			# ASSET NOT YET ON DISK - add ui_defeat_strike.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/ui_defeat_strike.wav"
			volume_db = 0.0

		# ---- DECKBUILDER / CARD UI SFX ----
		# Retain and reroll confirmation click.
		"ui_pencil_check":
			# ACTUAL FILE: ui_pencil_check.mp3
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_pencil_check.mp3"
			volume_db = -2.0
		# Card drawn from pile.
		"ui_card_draw", "card_draw":
			# ACTUAL FILE: ui_card_draw.mp3
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_card_draw.mp3"
			volume_db = -2.0
			cancel_duplicates = true
		# Card hover highlight.
		"ui_card_hover", "card_hover":
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_card_hover.mp3"
			volume_db = -4.0
			cancel_duplicates = true
		# Card picked up from hand.
		"ui_card_lift", "card_lift":
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_card_lift.mp3"
			volume_db = -4.0
			cancel_duplicates = true
		# Deck shuffled when draw pile empty.
		"ui_deck_shuffle", "card_shuffle":
			# ACTUAL FILE: ui_card_shuffle.mp3 (design doc calls it ui_deck_shuffle but file is ui_card_shuffle)
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_card_shuffle.mp3"
			volume_db = -4.0
			cancel_duplicates = true
		# End turn button click.
		"ui_end_turn_click", "end_turn":
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_end_turn_click.mp3"
			volume_db = -2.0
			cancel_duplicates = true
		# Invalid action / not enough energy.
		"ui_error_thud", "error":
			# ACTUAL FILE: ui_error_thud.mp3
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_error_thud.mp3"
			volume_db = 0.0
			cancel_duplicates = true
		# Shift gauge full chime.
		"ui_shift_ready_chime", "shift_ready":
			# ACTUAL FILE: ui_shift_ready_chime.mp3
			sfx_path = "res://Assets/Sound Effects/Card Sounds/ui_shift_ready_chime.mp3"
			volume_db = 0.0
			cancel_duplicates = true

		# ---- COMBAT DECK CARD SFX ----
		# Strike: canvas tear impact.
		"canvas_tear", "sfx_canvas_tear":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/canvas_tear.mp3"
			volume_db = -2.0
		# Defend: wood block thud.
		"wood_impact", "sfx_wood_impact":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/wood_impact.mp3"
			volume_db = -2.0
		# Double Strike: two quick slice sounds.
		"double_slice", "sfx_double_slice":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/double_slice.mp3"
			volume_db = -4.0
		# Fireball: bass rumble boom.
		"bass_rumble", "fireball", "sfx_bass_rumble":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/fireball.mp3"
			volume_db = -4.0
		# Fortress: metal clamp lock.
		"metal_clamp", "sfx_metal_clamp":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/metal_clamp.mp3"
			volume_db = -4.0
		# Heavy Slash: metal crash.
		"crash_metal", "metal_crash", "sfx_crash_metal":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/metal_crash.mp3"
			volume_db = -4.0
		# Counter Stance: mechanical gear click.
		"gear_click", "sfx_gear_click":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/gear_click.mp3"
			volume_db = -4.0
		# Thunder: thunderclap. Also used for card_play alias.
		"thunderclap", "thunder", "card_play", "sfx_thunderclap":
			sfx_path = "res://Assets/Sound Effects/Combat Deck/thunder (volume this down a bit).mp3"
			volume_db = -10.0
		# Fireball burn cancelling enemy defend.
		"burn_tick":
			# ASSET NOT YET ON DISK - add sfx_burn_tick.wav to Combat Deck folder
			sfx_path = "res://Assets/Sound Effects/Combat Deck/sfx_burn_tick.wav"
			volume_db = 0.0
		# Heavy Slash clearing enemy block.
		"block_break":
			# ASSET NOT YET ON DISK - add sfx_block_break.wav to Combat Deck folder
			sfx_path = "res://Assets/Sound Effects/Combat Deck/sfx_block_break.wav"
			volume_db = 0.0
		# Player taking damage.
		"sfx_player_hit", "player_hit":
			# ASSET NOT YET ON DISK - add sfx_player_hit.wav to World, Ambient, and UI folder
			sfx_path = "res://Assets/Sound Effects/World, Ambient, and UI/sfx_player_hit.wav"
			volume_db = 0.0

		# ---- ENEMY / BOSS SFX ----
		# Castle Boss ground slam.
		"enm_boss_slam", "boss_slam":
			sfx_path = "res://Assets/Sound Effects/Enemies/enm_boss_slam.mp3"
			volume_db = -4.0
		# Claw enemy swipe.
		"enm_claw_swipe", "claw_swipe":
			sfx_path = "res://Assets/Sound Effects/Enemies/enm_claw swipe.mp3"
			volume_db = -4.0
		# Wolf growl.
		"enm_wolf_growl", "wolf_growl":
			sfx_path = "res://Assets/Sound Effects/Enemies/enm_wolf_growl.mp3"
			volume_db = -4.0
		# Steam puff.
		"enm_steam_puff", "steam_puff":
			sfx_path = "res://Assets/Sound Effects/Enemies/emn_steam_puff.mp3"
			volume_db = -4.0
		# Paper flutter - enemy with papers ability.
		"enm_paper_flutter", "paper_flutter":
			sfx_path = "res://Assets/Sound Effects/Enemies/enm_paper_flutter (volume too low).mp3"
			volume_db = 8.0
		# Gears loop - Castle Boss background. Looped via filename.
		"enm_gears_loop", "gears_loop":
			sfx_path = "res://Assets/Sound Effects/Enemies/enm_gears_loop.mp3"
			volume_db = -6.0
		# n.n. propeller hum - looped via filename.
		"amb_nn_propeller":
			# ASSET NOT YET ON DISK - add amb_nn_propeller.wav to Enemies folder
			sfx_path = "res://Assets/Sound Effects/Enemies/amb_nn_propeller.wav"
			volume_db = -4.0
			
	# Spawn a temporary audio player to support multiple overlapping sound effects
	if sfx_path != "":
		if cancel_duplicates and active_sfx_players.has(sound_name):
			var old_player = active_sfx_players[sound_name]
			if is_instance_valid(old_player) and old_player.playing:
				old_player.stop()
				old_player.queue_free()
				
		var stream = load(sfx_path)
		if stream:
			var temp_player = AudioStreamPlayer.new()
			
			# Explicit whitelist of looping SFX keys instead of filename heuristic.
			# This prevents files like "alarm... don't loop" from accidentally looping.
			var looping_keys = ["sfx_clock_tick", "clock", "enm_gears_loop", "gears_loop", "amb_nn_propeller", "sfx_shower_run", "shower", "sfx_kettle_boil", "kettle_boil"]
			var is_looping = sound_name in looping_keys
			if is_looping:
				if "loop" in stream:
					stream.loop = true
				elif "loop_mode" in stream:
					stream.loop_mode = 1
			
			temp_player.stream = stream
			temp_player.volume_db = volume_db
			temp_player.bus = "SFX"
			add_child(temp_player)
			
			active_sfx_players[sound_name] = temp_player
			temp_player.finished.connect(_on_sfx_finished.bind(temp_player, sound_name))
			temp_player.play()
			
			if is_looping:
				looping_sfx_players.append(temp_player)

func _on_sfx_finished(player: AudioStreamPlayer, sound_name: String) -> void:
	if active_sfx_players.has(sound_name) and active_sfx_players[sound_name] == player:
		active_sfx_players.erase(sound_name)
	player.queue_free()

func _connect_guitar_ducking(orig_vol: float) -> void:
	if active_sfx_players.has("amb_guitar_chords"):
		active_sfx_players["amb_guitar_chords"].finished.connect(func():
			var restore_tw = create_tween()
			restore_tw.tween_property(music_player, "volume_db", orig_vol, 1.0)
		)

# Stop a playing sound effect by name
func stop_sfx(sound_name: String) -> void:
	if active_sfx_players.has(sound_name):
		var p = active_sfx_players[sound_name]
		if is_instance_valid(p) and p.playing:
			p.stop()
			p.queue_free()
		active_sfx_players.erase(sound_name)

# Transition to a target state by path mapping.
func transition_to_state(target_state: String) -> void:
	var target_scene_path: String = ""
	match target_state:
		"S_intro":
			target_scene_path = "res://scenes/exploration/intro_cutscene.tscn"
			stop_all_oneshot_sfx()
		"S_bathroom":
			target_scene_path = "res://scenes/exploration/bathroom.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
			stop_all_oneshot_sfx()
		"S_apt":
			target_scene_path = "res://scenes/exploration/apartment.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
			# Stop any leftover SFX from combat or other scenes before starting apartment music.
			stop_all_oneshot_sfx()
			play_music("res://Assets/OST/Home - OST 001.ogg", -2.0)
			play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_bird_chirp_bedroom_ambience_please loop.mp3", -8.0)
		"S_hall":
			target_scene_path = "res://scenes/exploration/hallway.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
			# Stop clock and any apartment SFX when moving to hallway.
			stop_sfx("sfx_clock_tick")
			stop_sfx("clock")
			stop_all_oneshot_sfx()
			play_music("res://Assets/OST/College - OST 002.ogg", -2.0)
			play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_college_hallway.mp3", -6.0)
		"S_dream1":
			target_scene_path = "res://scenes/combat/grassy_field.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
			# Stop all SFX (clock, guitar, shower, etc.) before combat music takes over.
			stop_all_oneshot_sfx()
			play_music("res://Assets/OST/Dreamworld - OST 003.mp3", -3.0)
			stop_ambient()
		"S_class":
			target_scene_path = "res://scenes/exploration/classroom.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").show_hud()
			# Stop apartment SFX (guitar, bed, etc.) before classroom ambience starts.
			stop_sfx("amb_guitar_chords")
			stop_sfx("guitar")
			stop_all_oneshot_sfx()
			play_music("res://Assets/OST/College - OST 002.ogg", -2.0)
			play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_classroom.mp3", -6.0)
		"S_dream2", "S_dream2_resume":
			target_scene_path = "res://scenes/combat/burning_village.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
			# Stop classroom SFX (clock, pen scratch, bell, etc.) before combat music.
			stop_all_oneshot_sfx()
			play_music("res://Assets/OST/Castle Boss - OST 004.ogg", -7.0)
			stop_ambient()
		"S_ending":
			target_scene_path = "res://scenes/ui/ending_screen.tscn"
			if has_node("/root/ExplorationHUD"):
				get_node("/root/ExplorationHUD").hide_hud()
			stop_all_oneshot_sfx()
			play_music("res://Assets/OST/Title Screen - OST 000.ogg", -2.0)
			stop_ambient()
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
			
	# Trigger proper music loop based on which scene path we load
	if "apartment" in scene_path:
		play_music("res://Assets/OST/Home - OST 001.mp3", -2.0)
		play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_bird_chirp_bedroom_ambience_please loop.mp3", -8.0)
	elif "hallway" in scene_path:
		play_music("res://Assets/OST/College - OST 003.mp3", -2.0)
		play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_college_hallway.mp3", -6.0)
	elif "classroom" in scene_path:
		play_music("res://Assets/OST/College - OST 003.mp3", -2.0)
		play_ambient("res://Assets/Sound Effects/World, Ambient, and UI/amb_classroom.mp3", -6.0)
	elif "grassy_field" in scene_path or "burning_village" in scene_path:
		play_music("res://Assets/OST/Dream World - OST 002.mp3", -3.0)
		stop_ambient()
		
	_change_scene_with_fade(scene_path)

# Return to the main menu. Called by PauseManager when the player selects Main Menu.
func transition_to_state_menu() -> void:
	if has_node("/root/ExplorationHUD"):
		get_node("/root/ExplorationHUD").hide_hud()
	# Stop everything before returning to the menu.
	stop_all_oneshot_sfx()
	play_music("res://Assets/OST/Title Screen - OST 000.mp3", -2.0)
	stop_ambient()
	_change_scene_with_fade("res://scenes/ui/main_menu.tscn")

# Perform fade-out, scene change, and fade-in.
func _change_scene_with_fade(scene_path: String) -> void:
	# Keep track of exploration scenes for the save-load system.
	if scene_path.contains("scenes/exploration/"):
		last_exploration_scene_path = scene_path

	if get_tree() and get_tree().current_scene:
		previous_scene_name = get_tree().current_scene.scene_file_path.get_file().get_basename()

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
	
	# Fade back to transparent.
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	await tween_in.finished
	
	# Release input blocking.
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
