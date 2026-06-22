extends Node
# Programmatic ending screen for the Chapter 1 Demo endings.
# RATIONALE: Renders the final narrative results, selected ending path,
# and lists all found memory puzzle pieces with glassmorphism style.
# Avoids scene dependencies by constructing all controls programmatically.

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Full-screen dark background layer.
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.06, 1.0) # Deep dark background
	canvas.add_child(bg)
	
	# Mid-screen decorative light strip.
	var light_strip = ColorRect.new()
	light_strip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light_strip.anchor_top = 0.35
	light_strip.anchor_bottom = 0.65
	light_strip.color = Color(1.0, 0.97, 0.93, 0.015)
	canvas.add_child(light_strip)
	
	# Centered glassmorphic panel.
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300.0
	panel.offset_top = -240.0
	panel.offset_right = 300.0
	panel.offset_bottom = 240.0
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.10, 0.8)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	panel_style.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Game Title.
	var game_title = Label.new()
	game_title.text = "Before the Colours Fade"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_size_override("font_size", 16)
	game_title.add_theme_color_override("font_color", Color(0.65, 0.72, 0.8, 0.7))
	vbox.add_child(game_title)
	
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size.y = 10
	vbox.add_child(spacer_top)
	
	# Determine ending text based on chosen branch.
	# RATIONALE: Set title, color, and description dynamically based on the ending type.
	# The "demo" ending corresponds to the Chapter 1 Demo ending (bittersweet nostalgic cliffhanger).
	# Falling back to the old endings ("dream" or "wake") is preserved for safety,
	# but "demo" is the default for this prototype chapter's resolution.
	var end_title_text = ""
	var end_desc_text = ""
	var end_title_color = Color(1.0, 1.0, 1.0, 1.0)
	
	if GlobalState.chosen_ending == "dream":
		# Sustained Illusion (Dream Ending) from original design.
		end_title_text = "Ending A: Sustained Illusion (Dream Ending)"
		end_title_color = Color(0.9, 0.7, 0.5, 0.9) # Faded gold
		end_desc_text = "You have chosen to stay in the grassy field, safe behind the walls of your own designs. Here, the blueprints never burn and n.n.'s propeller never stops humming. But as the lines harden around you, the colours fade completely. You remain suspended in the margins of a memory, holding onto a voice that was only ever an echo of yourself."
	elif GlobalState.chosen_ending == "demo":
		# Bittersweet and open-ended cliffhanger demo ending, matching docs/demo_narrative_flow.md.
		# Grounds the resolution in the smudge on the palm and L.G.'s pencil-gear sketch.
		end_title_text = "Before the Colours Fade - Chapter 1 Demo Completed"
		end_title_color = Color(0.85, 0.72, 0.60, 0.95) # Bittersweet warm sienna/gold
		end_desc_text = "You have finished the quiz and stepped out into the rain-slicked Monday. The classroom walls are solid again, and L.G.'s chair remains empty. Yet, in the margin of your test paper, a small propeller gear doodle sits as a silent trace of the dream world. With a pencil smudge on your palm and your friend's voice echoing in your mind, you are left with a choice: will you continue their unfinished designs, or will the dream consume you? The drawings are waiting. The colours, though faint, are yours to write."
	elif GlobalState.chosen_ending == "secret":
		# Secret ending: Puzzle Loop resolved by unlocking the desk drawer.
		# RATIONALE: Fulfills the 9-fragment collection puzzle ending.
		end_title_text = "Ending C: The Colours Return (Secret Ending)"
		end_title_color = Color(0.58, 0.88, 0.68, 0.95) # Faint vibrant mint green
		end_desc_text = "You returned to your room and unlocked the desk drawer with the walkie-talkie key. There, preserved and safe, lies the final blueprint of the propeller cart with L.G.'s dual-wing glider attachment. The pencil lines are clear. The drawings are waiting. The colours, though faint, are yours to write. You have found the resolve to continue."
	else:
		# Fallback to the Weight of the Real (True Ending) from original design.
		end_title_text = "Ending B: The Weight of the Real (True Ending)"
		end_title_color = Color(0.5, 0.7, 0.9, 0.9) # Cold blue
		end_desc_text = "You have chosen to step out of the fiction. The dream shatters, leaving you in the cold, grey silence of the classroom. L.G.'s chair is empty, and the world is heavy with his absence. But the completed paper in your hand is real, and the pencil in your pocket still has lead. You have accepted the weight of the Real, and the colours, though faint, are waiting to return."
	
	# Ending Title Label.
	var end_title = Label.new()
	end_title.text = end_title_text
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_title.add_theme_font_size_override("font_size", 18)
	end_title.add_theme_color_override("font_color", end_title_color)
	vbox.add_child(end_title)
	
	var spacer_mid1 = Control.new()
	spacer_mid1.custom_minimum_size.y = 12
	vbox.add_child(spacer_mid1)
	
	# Ending Description.
	var end_desc = Label.new()
	end_desc.text = end_desc_text
	end_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_desc.add_theme_font_size_override("font_size", 12)
	end_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
	vbox.add_child(end_desc)
	
	var spacer_mid2 = Control.new()
	spacer_mid2.custom_minimum_size.y = 20
	vbox.add_child(spacer_mid2)
	
	# Memory Fragments Header.
	var frag_header = Label.new()
	frag_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frag_header.add_theme_font_size_override("font_size", 13)
	frag_header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7, 0.9))
	vbox.add_child(frag_header)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 130
	vbox.add_child(scroll)
	
	var frag_vbox = VBoxContainer.new()
	frag_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(frag_vbox)
	
	# List of pieces to check.
	var pieces: Array = [
		{"name": "The Blanket",         "flag": "bed_slept",           "hint": "Reluctance has a weight."},
		{"name": "The Smudged Photo",   "flag": "desk_searched",       "hint": "A grey smudge over the kid on the right."},
		{"name": "The Guitar Tuning",   "flag": "guitar_played",       "hint": "Fourth string tuned to open D. Not by me."},
		{"name": "The Workshop Lights", "flag": "peer1_talked",        "hint": "Lights on at the 4th street workshop. Yesterday."},
		{"name": "The Humming Chord",   "flag": "peer2_talked",        "hint": "The same chord, under my breath, without noticing."},
		{"name": "The Marginalia",      "flag": "locker_searched",     "hint": "Handwriting barely readable. Not mine."},
		{"name": "The Exam Monster",    "flag": "quiz_started",        "hint": "It spoke in exam commands. It sounded like a teacher."},
		{"name": "The Completed Paper", "flag": "buff_confidence_active", "hint": "Finished. In my handwriting. I don't remember any of it."},
		{"name": "The Scratch",         "flag": "scratch_found",       "hint": "H.H. + L.G. 2024."}
	]
	
	var found_count: int = 0
	for piece in pieces:
		var found = piece["flag"] != "" and GlobalState.has_flag(piece["flag"])
		if found:
			found_count += 1
		
		var row = HBoxContainer.new()
		
		var dot = Label.new()
		dot.text = "[*] " if found else "[ ] "
		dot.add_theme_font_size_override("font_size", 10)
		if found:
			dot.modulate = Color(0.8, 0.85, 0.9, 1.0)
		else:
			dot.modulate = Color(0.35, 0.35, 0.4, 1.0)
		row.add_child(dot)
		
		var name_lbl = Label.new()
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 10)
		if found:
			name_lbl.text = piece["name"] + " - " + piece["hint"]
			name_lbl.modulate = Color(0.9, 0.9, 0.95, 1.0)
		else:
			name_lbl.text = piece["name"] + " - Locked"
			name_lbl.modulate = Color(0.4, 0.4, 0.45, 1.0)
		row.add_child(name_lbl)
		
		frag_vbox.add_child(row)
		
		var sep = Control.new()
		sep.custom_minimum_size.y = 3
		frag_vbox.add_child(sep)
		
	frag_header.text = "Memory Fragments Recovered: %d / 9" % found_count
	
	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size.y = 15
	vbox.add_child(spacer_bot)
	
	# Main menu button.
	var menu_btn = _make_button("Return to Main Menu")
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)

func _make_button(label_text: String) -> Button:
	# Programmatic button styling matching main menu aesthetics.
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
	style_pressed.bg_color = Color(0.06, 0.06, 0.08, 0.7)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.75, 1.0))
	
	# Scale tween hover animation.
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

func _on_menu_pressed() -> void:
	# RATIONALE: Disconnect final state and return to start.
	GlobalState.reset_state()
	SceneManager.transition_to_state_menu()
