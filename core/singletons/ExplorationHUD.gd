extends Node
# Autoload singleton for rendering the Exploration HUD (heads-up display).
# Displays player stats, current story objectives, and control helpers.
# Built programmatically to avoid scene file corruption and maintain low entropy.

var canvas_layer: CanvasLayer
var root_control: Control
var arrow_node: Control

var objective_panel: Panel
var objective_label: Label
var controls_panel: Panel
var controls_label: Label
var journal_button: Button

# Journal Overlay UI
var deck_overlay_panel: Panel
var deck_list_container: VBoxContainer
var fragments_container: VBoxContainer

var is_visible: bool = false
var is_deck_overlay_open: bool = false
var _current_objective_text: String = "Explore."
var _objective_target_id: String = ""
var _time: float = 0.0

var custom_font: Font

func _ready() -> void:
	if FileAccess.file_exists("res://Assets/Fonts/VT323-Regular.ttf"):
		custom_font = load("res://Assets/Fonts/VT323-Regular.ttf")
	else:
		custom_font = ThemeDB.get_fallback_font()
		
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 80
	add_child(canvas_layer)
	
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.visible = false
	canvas_layer.add_child(root_control)
	
	arrow_node = Control.new()
	arrow_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrow_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_node.draw.connect(_on_arrow_draw)
	canvas_layer.add_child(arrow_node)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.08, 0.5)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(1.0, 1.0, 1.0, 0.15)
	style_box.anti_aliasing = false
	
	# Objective Panel (Top-Left)
	objective_panel = Panel.new()
	objective_panel.position = Vector2(20, 20)
	objective_panel.custom_minimum_size = Vector2(350, 50)
	objective_panel.add_theme_stylebox_override("panel", style_box)
	root_control.add_child(objective_panel)
	
	objective_label = Label.new()
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_override("font", custom_font)
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_panel.add_child(objective_label)
	
	# Controls Panel (Top-Right)
	controls_panel = Panel.new()
	controls_panel.anchor_left = 1.0
	controls_panel.anchor_right = 1.0
	controls_panel.offset_left = -220
	controls_panel.offset_top = 20
	controls_panel.offset_right = -20
	controls_panel.offset_bottom = 70
	controls_panel.add_theme_stylebox_override("panel", style_box)
	root_control.add_child(controls_panel)
	
	controls_label = Label.new()
	controls_label.text = "A/D: Move | E: Interact"
	controls_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_override("font", custom_font)
	controls_label.add_theme_font_size_override("font_size", 16)
	controls_panel.add_child(controls_label)
	
	# Journal Button (Bottom-Right)
	journal_button = Button.new()
	journal_button.text = "JOURNAL [TAB]"
	journal_button.anchor_left = 1.0
	journal_button.anchor_top = 1.0
	journal_button.anchor_right = 1.0
	journal_button.anchor_bottom = 1.0
	journal_button.offset_left = -160
	journal_button.offset_top = -60
	journal_button.offset_right = -20
	journal_button.offset_bottom = -20
	journal_button.add_theme_font_override("font", custom_font)
	journal_button.add_theme_font_size_override("font_size", 18)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.96, 0.95, 0.92, 0.9)
	btn_style.border_color = Color(0.12, 0.12, 0.15, 0.5)
	btn_style.border_width_bottom = 4
	btn_style.corner_radius_bottom_left = 2
	btn_style.corner_radius_bottom_right = 2
	btn_style.corner_radius_top_left = 2
	btn_style.corner_radius_top_right = 2
	
	journal_button.add_theme_stylebox_override("normal", btn_style)
	journal_button.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	journal_button.pressed.connect(toggle_deck_overlay)
	root_control.add_child(journal_button)
	
	# Journal Overlay (Booklet Style)
	deck_overlay_panel = Panel.new()
	deck_overlay_panel.anchor_left = 0.1
	deck_overlay_panel.anchor_right = 0.9
	deck_overlay_panel.anchor_top = 0.1
	deck_overlay_panel.anchor_bottom = 0.9
	
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.96, 0.95, 0.92, 0.98) # Light beige paper
	overlay_style.border_color = Color(0.12, 0.12, 0.15, 0.3)
	overlay_style.border_width_left = 4
	overlay_style.border_width_right = 4
	overlay_style.corner_radius_top_left = 8
	overlay_style.corner_radius_top_right = 8
	overlay_style.corner_radius_bottom_left = 8
	overlay_style.corner_radius_bottom_right = 8
	overlay_style.shadow_color = Color(0, 0, 0, 0.25)
	overlay_style.shadow_size = 10
	deck_overlay_panel.add_theme_stylebox_override("panel", overlay_style)
	deck_overlay_panel.visible = false
	canvas_layer.add_child(deck_overlay_panel)
	
	var overlay_margin = MarginContainer.new()
	overlay_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", 30)
	overlay_margin.add_theme_constant_override("margin_right", 30)
	overlay_margin.add_theme_constant_override("margin_top", 20)
	overlay_margin.add_theme_constant_override("margin_bottom", 20)
	deck_overlay_panel.add_child(overlay_margin)
	
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_margin.add_child(content_hbox)
	
	# Left Page: Deck
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(left_vbox)
	
	var deck_title = Label.new()
	deck_title.text = "Cards & Repertoire"
	deck_title.add_theme_font_override("font", custom_font)
	deck_title.add_theme_font_size_override("font_size", 24)
	deck_title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1.0))
	left_vbox.add_child(deck_title)
	
	var deck_scroll = ScrollContainer.new()
	deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(deck_scroll)
	
	deck_list_container = VBoxContainer.new()
	deck_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_scroll.add_child(deck_list_container)
	
	# Middle Spine
	var spine = ColorRect.new()
	spine.custom_minimum_size.x = 2
	spine.color = Color(0.1, 0.1, 0.15, 0.2)
	content_hbox.add_child(spine)
	
	# Right Page: Memories
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.custom_minimum_size.x = 280
	content_hbox.add_child(right_vbox)
	
	var mem_title = Label.new()
	mem_title.text = "Memories & Fragments"
	mem_title.add_theme_font_override("font", custom_font)
	mem_title.add_theme_font_size_override("font_size", 24)
	mem_title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1.0))
	right_vbox.add_child(mem_title)
	
	var mem_scroll = ScrollContainer.new()
	mem_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(mem_scroll)
	
	fragments_container = VBoxContainer.new()
	fragments_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mem_scroll.add_child(fragments_container)
	
	var close_btn = Button.new()
	close_btn.text = "Close Journal [TAB]"
	close_btn.add_theme_font_override("font", custom_font)
	close_btn.add_theme_color_override("font_color", Color(0.3, 0.2, 0.2, 1.0))
	close_btn.pressed.connect(toggle_deck_overlay)
	right_vbox.add_child(close_btn)
	
	EventBus.player_interacted.connect(func(_id): update_hud())
	EventBus.dialogue_finished.connect(update_hud)

func _on_arrow_draw() -> void:
	if not is_visible or _objective_target_id == "":
		return
		
	var target = Interactable.all_interactables.get(_objective_target_id)
	if not target or not is_instance_valid(target):
		return
		
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
		
	var screen_pos = target.get_global_transform_with_canvas().origin
	var screen_rect = get_viewport().get_visible_rect()
	
	var margin = 40.0
	var is_on_screen = screen_rect.grow(-margin).has_point(screen_pos)
	
	var arrow_col = Color(0.85, 0.75, 0.2, 0.95)
	var outline_col = Color(0.05, 0.05, 0.05, 0.9)
	
	if is_on_screen:
		if _objective_target_id.begins_with("door"):
			# Bouncing arrow pointing horizontally to the door
			var bounce_x = sin(_time * 6.0) * 8.0
			var draw_pos = screen_pos + Vector2(-40 + bounce_x, 0)
			var pts = PackedVector2Array([
				draw_pos + Vector2(-12, -10),
				draw_pos + Vector2(-12, 10),
				draw_pos + Vector2(4, 0)
			])
			
			var out_pts = PackedVector2Array([
				draw_pos + Vector2(-15, -13),
				draw_pos + Vector2(-15, 13),
				draw_pos + Vector2(8, 0)
			])
			arrow_node.draw_polygon(out_pts, PackedColorArray([outline_col]))
			arrow_node.draw_polygon(pts, PackedColorArray([arrow_col]))
		else:
			# Bouncing arrow above target vertically
			var bounce_y = sin(_time * 6.0) * 8.0
			var draw_pos = screen_pos + Vector2(0, -50 + bounce_y)
			var pts = PackedVector2Array([
				draw_pos + Vector2(-10, -12),
				draw_pos + Vector2(10, -12),
				draw_pos + Vector2(0, 4)
			])
			
			# Outline
			var out_pts = PackedVector2Array([
				draw_pos + Vector2(-13, -15),
				draw_pos + Vector2(13, -15),
				draw_pos + Vector2(0, 8)
			])
			arrow_node.draw_polygon(out_pts, PackedColorArray([outline_col]))
			arrow_node.draw_polygon(pts, PackedColorArray([arrow_col]))
	else:
		# Directional pointer at edge of screen
		var center = screen_rect.size / 2.0
		var dir = (screen_pos - center).normalized()
		
		# Project to edge roughly
		var max_x = screen_rect.size.x / 2.0 - margin
		var max_y = screen_rect.size.y / 2.0 - margin
		
		var t_x = max_x / abs(dir.x) if dir.x != 0 else 9999
		var t_y = max_y / abs(dir.y) if dir.y != 0 else 9999
		var t = min(t_x, t_y)
		
		var edge_pos = center + dir * t
		
		var tip = edge_pos + dir * 15.0
		var base1 = edge_pos - dir * 10.0 + dir.orthogonal() * 10.0
		var base2 = edge_pos - dir * 10.0 - dir.orthogonal() * 10.0
		
		var pts = PackedVector2Array([tip, base1, base2])
		
		var o_tip = tip + dir * 3.0
		var o_base1 = base1 - dir * 3.0 + dir.orthogonal() * 3.0
		var o_base2 = base2 - dir * 3.0 - dir.orthogonal() * 3.0
		var out_pts = PackedVector2Array([o_tip, o_base1, o_base2])
		
		arrow_node.draw_polygon(out_pts, PackedColorArray([outline_col]))
		arrow_node.draw_polygon(pts, PackedColorArray([arrow_col]))


# Build the right-side 'Memories' column for the Tab overlay.
# Shows all 9 narrative puzzle pieces with found/unknown status.
# Check for Tab key input to toggle inventory deck view.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if is_visible:
			# Prevent overlay opening if the player is in the middle of active dialogue.
			if not DialogueSystem.is_active:
				toggle_deck_overlay()

# Toggle visibility of the inventory overlay panel and freeze player movement.
func toggle_deck_overlay() -> void:
	is_deck_overlay_open = not is_deck_overlay_open
	deck_overlay_panel.visible = is_deck_overlay_open
	
	if is_deck_overlay_open:
		EventBus.lock_player_ui.emit()
		update_deck_overlay()
	else:
		EventBus.unlock_player_ui.emit()

# Build the scrollable deck list and populate status labels.
func update_deck_overlay() -> void:
	for child in deck_list_container.get_children():
		child.queue_free()
		
	var card_counts = {}
	for card in GlobalState.master_deck:
		if card:
			var name = card.card_name
			if not card_counts.has(name):
				card_counts[name] = {"count": 0, "card": card}
			card_counts[name]["count"] += 1
			
	# Top: Stats
	var stats_lbl = Label.new()
	var active_buffs = []
	if GlobalState.has_flag("buff_courage_active"): active_buffs.append("Courage (1.5x Dmg)")
	if GlobalState.has_flag("buff_confidence_active"): active_buffs.append("Confidence (2.0x Dmg)")
	var buffs_str = ", ".join(active_buffs) if not active_buffs.is_empty() else "None"
	
	stats_lbl.text = "HP: %d/%d  |  Buffs: %s\nModifiers: %s%d Energy | +%d Block | %s%d Draw\n--------------------------------------------" % [
		GlobalState.player_current_hp,
		GlobalState.player_max_hp,
		buffs_str,
		"+" if GlobalState.starting_energy_modifier >= 0 else "", GlobalState.starting_energy_modifier,
		GlobalState.starting_block_modifier,
		"+" if GlobalState.starting_draw_modifier >= 0 else "", GlobalState.starting_draw_modifier
	]
	stats_lbl.add_theme_font_override("font", custom_font)
	stats_lbl.add_theme_font_size_override("font_size", 16)
	stats_lbl.add_theme_color_override("font_color", Color(0.12, 0.12, 0.18, 1.0))
	deck_list_container.add_child(stats_lbl)
	
	var stat_sep = Control.new()
	stat_sep.custom_minimum_size.y = 10
	deck_list_container.add_child(stat_sep)
			
	if card_counts.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Your repertoire is empty."
		empty_lbl.add_theme_font_override("font", custom_font)
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1.0))
		deck_list_container.add_child(empty_lbl)
	else:
		for name in card_counts:
			var info = card_counts[name]
			var c = info["card"]
			
			var card_lbl = Label.new()
			card_lbl.text = "- %s (x%d)
  [Cost: %d] %s" % [c.card_name, info["count"], c.energy_cost, c.description]
			card_lbl.add_theme_font_override("font", custom_font)
			card_lbl.add_theme_font_size_override("font_size", 18)
			card_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1.0))
			card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			deck_list_container.add_child(card_lbl)
			
			var sep = Control.new()
			sep.custom_minimum_size.y = 8
			deck_list_container.add_child(sep)
			
	_update_fragments_column()

# Allow exploration scenes to push a new objective string directly.
func set_objective(text: String, target_id: String = "") -> void:
	_current_objective_text = text
	_objective_target_id = target_id
	update_hud()

# Populate the Memories column with all 9 narrative puzzle pieces.
func _update_fragments_column() -> void:
	if not fragments_container: return
	for child in fragments_container.get_children():
		child.queue_free()
		
	var pieces = [
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
	
	for piece in pieces:
		var found = piece["flag"] != "" and GlobalState.has_flag(piece["flag"])
		var row = HBoxContainer.new()
		
		var dot = Label.new()
		dot.text = "●" if found else "○"
		dot.add_theme_font_override("font", custom_font)
		dot.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1.0) if found else Color(0.6, 0.6, 0.6, 1.0))
		row.add_child(dot)
		
		var name_lbl = Label.new()
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", custom_font)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.text = piece["name"] + ("
  " + piece["hint"] if found else "
  ?????")
		name_lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1.0) if found else Color(0.5, 0.5, 0.5, 1.0))
		row.add_child(name_lbl)
		
		fragments_container.add_child(row)


# Show the HUD and run a refresh.
func show_hud() -> void:
	is_visible = true
	root_control.visible = true
	is_deck_overlay_open = false
	if deck_overlay_panel:
		deck_overlay_panel.visible = false
	update_hud()

# Hide the HUD in combat arenas.
func hide_hud() -> void:
	is_visible = false
	root_control.visible = false
	is_deck_overlay_open = false
	if deck_overlay_panel:
		deck_overlay_panel.visible = false

# Update HUD content depending on state and progress.
func update_hud() -> void:
	if not is_visible: return
		
	var objective_text = "Objective: " + _current_objective_text
	
	if _current_objective_text == "Explore.":
		var current_scene = get_tree().current_scene
		if current_scene:
			match current_scene.name:
				"Hallway":
					objective_text = "Objective: Head down the hallway to your quiz."
					_objective_target_id = "fountain"
				"Classroom":
					if GlobalState.has_flag("shift_1_done") or GlobalState.shift_1_done:
						objective_text = "Objective: Take a breath. Look around."
						_objective_target_id = ""
					else:
						objective_text = "Objective: Search the lockers, then sit at your desk to start the quiz."
						_objective_target_id = "desk"
				
	var old_objective = objective_label.text
	objective_label.text = objective_text
	
	if old_objective != objective_text and old_objective != "":
		objective_label.pivot_offset = objective_label.size / 2
		var pulse_tw = create_tween()
		pulse_tw.tween_property(objective_label, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_SINE)
		pulse_tw.tween_property(objective_label, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	if is_visible and root_control and root_control.visible:
		_time += delta
		
		if objective_panel:
			var obj_offset = cos(_time * 1.5) * 3.0
			objective_panel.position.y = 20.0 + obj_offset
			
		if controls_panel:
			var ctrl_offset = sin(_time * 1.5 + 1.0) * 3.0
			controls_panel.position.y = 20.0 + ctrl_offset
			
	if arrow_node and arrow_node.visible:
		arrow_node.queue_redraw()