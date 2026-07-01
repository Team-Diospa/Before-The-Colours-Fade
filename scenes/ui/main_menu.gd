extends Node
# Main menu scene script.
# Entry point of the game. Handles Start (new game) and Quit actions.
# RATIONALE: All styling is done in code, consistent with the rest of the codebase
# which builds UI programmatically to avoid broken scene references.

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Full-screen dark background.
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.06, 1.0) # Very dark near-black
	canvas.add_child(bg)
	
	# Faint horizontal light strip at mid-screen for depth.
	var light_strip = ColorRect.new()
	light_strip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light_strip.anchor_top = 0.35
	light_strip.anchor_bottom = 0.65
	light_strip.color = Color(1.0, 0.97, 0.93, 0.015) # Extremely faint warm white
	canvas.add_child(light_strip)
	
	# Centered panel container.
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200.0
	panel.offset_top = -160.0
	panel.offset_right = 200.0
	panel.offset_bottom = 160.0
	
	# RATIONALE: Use StyleBoxTexture for non-stretching modular panel borders.
	# Slicing margins set to 12px, axis stretch mode set to TILE_FIT to keep pixel art crisp.
	var panel_style = StyleBoxTexture.new()
	panel_style.texture = load("res://Assets/Menu and Settings/UI/9-patch_slice_menu.png")
	panel_style.texture_margin_left = 12
	panel_style.texture_margin_right = 12
	panel_style.texture_margin_top = 12
	panel_style.texture_margin_bottom = 12
	panel_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	panel_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)
	
	# Margin inside panel.
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_bottom", 35)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Load retro pixel-art fonts.
	var font_retro = load("res://Assets/Fonts/VT323-Regular.ttf")
	var font_main = load("res://Assets/Fonts/PixelifySans-VariableFont_wght.ttf")

	# Game title label with VT323 retro font and scaled size.
	var title = Label.new()
	title.text = "Before the Colours Fade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_retro:
		title.add_theme_font_override("font", font_retro)
		title.add_theme_font_size_override("font_size", 32)
	else:
		title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	vbox.add_child(title)
	
	# Subtitle / mood line with PixelifySans font.
	var subtitle = Label.new()
	subtitle.text = "The night before is a memory."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_main:
		subtitle.add_theme_font_override("font", font_main)
		subtitle.add_theme_font_size_override("font_size", 12)
	else:
		subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.7))
	vbox.add_child(subtitle)
	
	# Spacer.
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 30
	vbox.add_child(spacer)
	
	# Start button.
	var start_btn = _make_button("Start")
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)
	
	# Small gap.
	var gap_c = Control.new()
	gap_c.custom_minimum_size.y = 8
	vbox.add_child(gap_c)
	
	# Continue button (disabled if no save is present).
	var continue_btn = _make_button("Continue")
	continue_btn.disabled = not SaveManager.has_save()
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)
	
	# Small gap between buttons.
	var btn_gap = Control.new()
	btn_gap.custom_minimum_size.y = 8
	vbox.add_child(btn_gap)
	
	# Quit button.
	var quit_btn = _make_button("Quit")
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)
	
func _make_button(label_text: String) -> Button:
	# RATIONALE: Style button using StyleBoxTexture to prevent pixel art distortion.
	# Uses the modular reality button frames with tiled stretch mode (4px margin).
	var btn = Button.new()
	btn.text = label_text
	
	var font_retro = load("res://Assets/Fonts/VT323-Regular.ttf")
	if font_retro:
		btn.add_theme_font_override("font", font_retro)
		btn.add_theme_font_size_override("font_size", 18)
	else:
		btn.add_theme_font_size_override("font_size", 14)
		
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
	
	# Subtle scale micro-animation on hover.
	btn.pivot_offset = Vector2(100, 15)
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			var tw = btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.1)
	)
	btn.mouse_exited.connect(func():
		if not btn.disabled:
			var tw = btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	return btn

func _on_start_pressed() -> void:
	# RATIONALE: Reset all persistent state to guarantee a clean run.
	GlobalState.reset_state()
	SceneManager.transition_to_state("S_apt")

func _on_continue_pressed() -> void:
	# RATIONALE: Load the saved game state and restore gameplay.
	if SaveManager.has_save():
		SaveManager.load_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
