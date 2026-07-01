extends Node
# Autoload singleton for the pause overlay.
# Listens for the ui_cancel (Escape) action globally and shows/hides a pause panel.
# RATIONALE: The pause system must be a singleton so it persists across all scene loads.
# It must NOT activate during dialogue (DialogueSystem.is_active) to avoid conflicting
# with E/Space dialogue advancement consuming the Escape event.

# Programmatic pause UI elements.
var _canvas_layer: CanvasLayer
var _overlay: Panel
var _is_paused: bool = false

# Settings menu and save/load variables
const SETTINGS_PATH: String = "user://settings.json"
var _vbox: VBoxContainer
var _settings_vbox: VBoxContainer
var _volume_slider: HSlider
var _status_lbl: Label
var _load_game_btn: Button
var _save_game_btn: Button

func _ready() -> void:
	# RATIONALE: PROCESS_MODE_ALWAYS is required so _input continues to fire after
	# get_tree().paused = true. Without it, this autoload inherits the paused state
	# and the Resume/Main Menu/Quit buttons become unresponsive.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Apply volume settings on start.
	_apply_saved_volume()
	
	# Build the pause overlay programmatically.
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 95 # Above gameplay (80-90), below SceneManager fade (100)
	add_child(_canvas_layer)
	
	_overlay = Panel.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Block all clicks when visible
	_overlay.visible = false
	_canvas_layer.add_child(_overlay)
	
	# Semi-transparent dark overlay background.
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.0, 0.0, 0.0, 0.55) # Heavy vignette tint
	overlay_style.corner_radius_top_left = 0
	overlay_style.corner_radius_top_right = 0
	overlay_style.corner_radius_bottom_left = 0
	overlay_style.corner_radius_bottom_right = 0
	overlay_style.border_width_left = 0
	overlay_style.border_width_top = 0
	overlay_style.border_width_right = 0
	overlay_style.border_width_bottom = 0
	_overlay.add_theme_stylebox_override("panel", overlay_style)
	
	# Centered inner panel. Expanded height to 280 to comfortably hold settings.
	var inner = Panel.new()
	inner.anchor_left = 0.5
	inner.anchor_top = 0.5
	inner.anchor_right = 0.5
	inner.anchor_bottom = 0.5
	inner.offset_left = -140.0
	inner.offset_top = -140.0
	inner.offset_right = 140.0
	inner.offset_bottom = 140.0
	
	# RATIONALE: Use StyleBoxTexture for non-stretching modular panel borders.
	# Slicing margins set to 12px, axis stretch mode set to TILE_FIT to keep pixel art crisp.
	var inner_style = StyleBoxTexture.new()
	inner_style.texture = load("res://Assets/Menu and Settings/UI/9-patch_slice_menu.png")
	inner_style.texture_margin_left = 12
	inner_style.texture_margin_right = 12
	inner_style.texture_margin_top = 12
	inner_style.texture_margin_bottom = 12
	inner_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	inner_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	inner.add_theme_stylebox_override("panel", inner_style)
	_overlay.add_child(inner)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	inner.add_child(margin)
	
	# ----------------- MAIN PAUSE VBOX -----------------
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_vbox)
	
	var font_retro = load("res://Assets/Fonts/VT323-Regular.ttf")
	var font_main = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")
	
	var title_lbl = Label.new()
	title_lbl.text = "Paused"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_retro:
		title_lbl.add_theme_font_override("font", font_retro)
		title_lbl.add_theme_font_size_override("font_size", 24)
	else:
		title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	_vbox.add_child(title_lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 15
	_vbox.add_child(spacer)
	
	var resume_btn = _make_pause_button("Resume")
	resume_btn.pressed.connect(_on_resume_pressed)
	_vbox.add_child(resume_btn)
	
	var gap = Control.new()
	gap.custom_minimum_size.y = 8
	_vbox.add_child(gap)
	
	var settings_btn = _make_pause_button("Settings")
	settings_btn.pressed.connect(_show_settings)
	_vbox.add_child(settings_btn)
	
	var gap_s = Control.new()
	gap_s.custom_minimum_size.y = 8
	_vbox.add_child(gap_s)
	
	var menu_btn = _make_pause_button("Main Menu")
	menu_btn.pressed.connect(_on_menu_pressed)
	_vbox.add_child(menu_btn)
	
	var gap2 = Control.new()
	gap2.custom_minimum_size.y = 8
	_vbox.add_child(gap2)
	
	var quit_btn = _make_pause_button("Quit to Desktop")
	quit_btn.pressed.connect(_on_quit_pressed)
	_vbox.add_child(quit_btn)

	# ----------------- SETTINGS VBOX -----------------
	_settings_vbox = VBoxContainer.new()
	_settings_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_settings_vbox.visible = false
	margin.add_child(_settings_vbox)
	
	var s_title_lbl = Label.new()
	s_title_lbl.text = "Settings"
	s_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_retro:
		s_title_lbl.add_theme_font_override("font", font_retro)
		s_title_lbl.add_theme_font_size_override("font_size", 24)
	else:
		s_title_lbl.add_theme_font_size_override("font_size", 18)
	s_title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	_settings_vbox.add_child(s_title_lbl)
	
	var s_spacer = Control.new()
	s_spacer.custom_minimum_size.y = 10
	_settings_vbox.add_child(s_spacer)
	
	# Volume Control Container
	var vol_hbox = HBoxContainer.new()
	vol_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_settings_vbox.add_child(vol_hbox)
	
	var vol_lbl = Label.new()
	vol_lbl.text = "Vol: "
	vol_lbl.add_theme_font_size_override("font_size", 13)
	vol_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	vol_hbox.add_child(vol_lbl)
	
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.custom_minimum_size = Vector2(130, 20)
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.value_changed.connect(_on_volume_changed)
	
	# RATIONALE: Style volume slider using custom slider textures.
	var knob_tex = load("res://Assets/Menu and Settings/UI/slider_knob.png")
	var track_empty_tex = load("res://Assets/Menu and Settings/UI/slider_track_empty.png")
	var track_full_tex = load("res://Assets/Menu and Settings/UI/slider_track_full.png")
	
	if knob_tex:
		_volume_slider.add_theme_icon_override("grabber", knob_tex)
		_volume_slider.add_theme_icon_override("grabber_highlight", knob_tex)
		
	if track_empty_tex:
		var style_empty = StyleBoxTexture.new()
		style_empty.texture = track_empty_tex
		style_empty.texture_margin_left = 3
		style_empty.texture_margin_right = 3
		style_empty.texture_margin_top = 3
		style_empty.texture_margin_bottom = 3
		style_empty.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		style_empty.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		_volume_slider.add_theme_stylebox_override("slider", style_empty)
		
	if track_full_tex:
		var style_full = StyleBoxTexture.new()
		style_full.texture = track_full_tex
		style_full.texture_margin_left = 3
		style_full.texture_margin_right = 3
		style_full.texture_margin_top = 3
		style_full.texture_margin_bottom = 3
		style_full.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		style_full.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		_volume_slider.add_theme_stylebox_override("area", style_full)
		
	vol_hbox.add_child(_volume_slider)
	
	var vol_gap = Control.new()
	vol_gap.custom_minimum_size.y = 8
	_settings_vbox.add_child(vol_gap)
	
	_save_game_btn = _make_pause_button("Save Game")
	_save_game_btn.pressed.connect(_on_save_pressed)
	_settings_vbox.add_child(_save_game_btn)
	
	var s_gap = Control.new()
	s_gap.custom_minimum_size.y = 8
	_settings_vbox.add_child(s_gap)
	
	_load_game_btn = _make_pause_button("Load Game")
	_load_game_btn.pressed.connect(_on_load_pressed)
	_settings_vbox.add_child(_load_game_btn)
	
	var back_gap = Control.new()
	back_gap.custom_minimum_size.y = 8
	_settings_vbox.add_child(back_gap)
	
	var back_btn = _make_pause_button("Back")
	back_btn.pressed.connect(_show_main_menu)
	_settings_vbox.add_child(back_btn)
	
	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 10)
	_status_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
	_settings_vbox.add_child(_status_lbl)

func _make_pause_button(label_text: String) -> Button:
	# RATIONALE: Style button using StyleBoxTexture to prevent pixel art distortion.
	# Uses the modular reality button frames with tiled stretch mode (4px margin).
	var btn = Button.new()
	btn.text = label_text
	
	var font_retro = load("res://Assets/Fonts/VT323-Regular.ttf")
	if font_retro:
		btn.add_theme_font_override("font", font_retro)
		btn.add_theme_font_size_override("font_size", 16)
	else:
		btn.add_theme_font_size_override("font_size", 13)
	
	var style_normal = StyleBoxTexture.new()
	style_normal.texture = load("res://Assets/UI/reality_button_32x12_default.png")
	style_normal.texture_margin_left = 4
	style_normal.texture_margin_right = 4
	style_normal.texture_margin_top = 4
	style_normal.texture_margin_bottom = 4
	style_normal.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style_normal.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	
	var style_hover = StyleBoxTexture.new()
	style_hover.texture = load("res://Assets/UI/reality_button_32x12_hover.png")
	style_hover.texture_margin_left = 4
	style_hover.texture_margin_right = 4
	style_hover.texture_margin_top = 4
	style_hover.texture_margin_bottom = 4
	style_hover.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style_hover.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	
	var style_pressed = StyleBoxTexture.new()
	style_pressed.texture = load("res://Assets/UI/reality_button_32x12_pressed.png")
	style_pressed.texture_margin_left = 4
	style_pressed.texture_margin_right = 4
	style_pressed.texture_margin_top = 4
	style_pressed.texture_margin_bottom = 4
	style_pressed.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style_pressed.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	
	var style_disabled = style_normal.duplicate()
	style_disabled.modulate_color = Color(0.5, 0.5, 0.5, 0.5)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.75, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.45, 0.6))
	
	return btn

func _input(event: InputEvent) -> void:
	# RATIONALE: Do not pause during dialogue - Escape would conflict with the dialogue system.
	# Do not pause when already on the main menu (no gameplay to pause).
	if event.is_action_pressed("ui_cancel"):
		var current_scene = get_tree().current_scene
		if current_scene == null:
			return
		# Prevent pause from triggering on the main menu itself.
		if current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn":
			return
		# Prevent pause from conflicting with active dialogue.
		if DialogueSystem.is_active:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	_is_paused = not _is_paused
	_overlay.visible = _is_paused
	# RATIONALE: get_tree().paused freezes all _process and _physics_process calls
	# for nodes that do not have process_mode = ALWAYS. The autoloads (PauseManager,
	# DialogueSystem etc.) run at ALWAYS by default so they continue to receive input.
	get_tree().paused = _is_paused
	if _is_paused:
		_show_main_menu()
		EventBus.lock_player_ui.emit()
	else:
		EventBus.unlock_player_ui.emit()

func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_menu_pressed() -> void:
	# Unpause before transitioning to prevent a permanently frozen tree.
	get_tree().paused = false
	_is_paused = false
	_overlay.visible = false
	SceneManager.transition_to_state_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()

# ----------------- SETTINGS & SAVE/LOAD HANDLERS -----------------

# Applies the saved volume configuration to the Master bus on game startup.
func _apply_saved_volume() -> void:
	var vol = 0.8 # Default volume
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				vol = float(json.data.get("volume", 0.8))
			file.close()
	
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(vol))

# Handles slider volume changes and writes them immediately to the settings file.
func _on_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
		
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"volume": value}))
		file.close()

# Switches panel visibility to settings and updates elements state.
func _show_settings() -> void:
	_vbox.visible = false
	_settings_vbox.visible = true
	_status_lbl.text = ""
	
	# Fetch volume
	var vol = 0.8
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				vol = float(json.data.get("volume", 0.8))
			file.close()
	_volume_slider.value = vol
	
	# Enable load button if save exists
	_load_game_btn.disabled = not SaveManager.has_save()

# Switches panel visibility back to the main pause options.
func _show_main_menu() -> void:
	_settings_vbox.visible = false
	_vbox.visible = true

# Handles saving progress, resolving combat checkpoints to the previous exploration area.
func _on_save_pressed() -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		_status_lbl.text = "Failed: No active scene"
		_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7, 1.0))
		return
		
	var scene_path = current_scene.scene_file_path
	# RATIONALE: Saving mid-combat redirects resume points to the prior exploration scene.
	if scene_path.contains("scenes/combat/"):
		scene_path = SceneManager.last_exploration_scene_path
		
	if SaveManager.save_game(scene_path):
		_status_lbl.text = "Game Saved Successfully"
		_status_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
		_load_game_btn.disabled = false
	else:
		_status_lbl.text = "Save Failed"
		_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7, 1.0))

# Handles loading progress, resuming exploration state.
func _on_load_pressed() -> void:
	if not SaveManager.has_save():
		_status_lbl.text = "No Save Found"
		_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7, 1.0))
		return
		
	# Unpause first to prevent a frozen state in the loaded scene.
	_toggle_pause()
	
	if not SaveManager.load_game():
		_status_lbl.text = "Load Failed"
		_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7, 1.0))
		# Re-show pause if load fails
		_toggle_pause()
		_show_settings()
