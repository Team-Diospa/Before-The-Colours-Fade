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
	
	# Glassmorphism panel style: translucent dark slate, thin white border, no rounded corners.
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.10, 0.75)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.12) # Thin white glass border
	panel_style.anti_aliasing = false
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
	
	# Game title label.
	var title = Label.new()
	title.text = "Before the Colours Fade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	vbox.add_child(title)
	
	# Subtitle / mood line from the prologue.
	var subtitle = Label.new()
	subtitle.text = "The night before is a memory."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	
	# Small gap between buttons.
	var btn_gap = Control.new()
	btn_gap.custom_minimum_size.y = 8
	vbox.add_child(btn_gap)
	
	# Quit button.
	var quit_btn = _make_button("Quit")
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

func _make_button(label_text: String) -> Button:
	# RATIONALE: Consistent with CombatManager and DialogueSystem button styling.
	# Dark translucent background, thin white border, white text, silver on hover.
	var btn = Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 14)
	
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
	style_pressed.bg_color = Color(0.06, 0.06, 0.08, 0.7)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.75, 1.0))
	
	# Subtle scale micro-animation on hover.
	btn.pivot_offset = Vector2(100, 15)
	btn.mouse_entered.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	return btn

func _on_start_pressed() -> void:
	# RATIONALE: Reset all persistent state to guarantee a clean run.
	GlobalState.reset_state()
	SceneManager.transition_to_state("S_apt")

func _on_quit_pressed() -> void:
	get_tree().quit()
