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

func _ready() -> void:
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
	
	# Centered inner panel.
	var inner = Panel.new()
	inner.anchor_left = 0.5
	inner.anchor_top = 0.5
	inner.anchor_right = 0.5
	inner.anchor_bottom = 0.5
	inner.offset_left = -140.0
	inner.offset_top = -110.0
	inner.offset_right = 140.0
	inner.offset_bottom = 110.0
	
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color(0.06, 0.06, 0.09, 0.88)
	inner_style.border_width_left = 1
	inner_style.border_width_top = 1
	inner_style.border_width_right = 1
	inner_style.border_width_bottom = 1
	inner_style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	inner_style.corner_radius_top_left = 0
	inner_style.corner_radius_top_right = 0
	inner_style.corner_radius_bottom_left = 0
	inner_style.corner_radius_bottom_right = 0
	inner_style.anti_aliasing = false
	inner.add_theme_stylebox_override("panel", inner_style)
	_overlay.add_child(inner)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	inner.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "Paused"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	vbox.add_child(title_lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	var resume_btn = _make_pause_button("Resume")
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)
	
	var gap = Control.new()
	gap.custom_minimum_size.y = 8
	vbox.add_child(gap)
	
	var menu_btn = _make_pause_button("Main Menu")
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)
	
	var gap2 = Control.new()
	gap2.custom_minimum_size.y = 8
	vbox.add_child(gap2)
	
	var quit_btn = _make_pause_button("Quit to Desktop")
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

func _make_pause_button(label_text: String) -> Button:
	# Consistent button style with DialogueSystem and main_menu.
	var btn = Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 13)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.14, 0.6)
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color(1.0, 1.0, 1.0, 0.15)
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.anti_aliasing = false
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.18, 0.18, 0.24, 0.7)
	style_hover.border_color = Color(0.8, 0.8, 0.8, 0.4)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.05, 0.05, 0.07, 0.8)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.75, 1.0))
	
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
