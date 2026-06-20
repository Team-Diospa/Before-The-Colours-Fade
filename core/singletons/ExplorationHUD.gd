extends Node
# Autoload singleton for rendering the Exploration HUD (heads-up display).
# Displays player stats, current story objectives, and control helpers.
# Built programmatically to avoid scene file corruption and maintain low entropy.

var canvas_layer: CanvasLayer
var root_control: Control

# UI widgets.
var stats_panel: Panel
var hp_label: Label
var fragments_label: Label
var buffs_label: Label

var objective_panel: Panel
var objective_label: Label

var controls_panel: Panel
var controls_label: Label

# RATIONALE: UI widgets for the programmatic Deck List & Guide Overlay.
var deck_overlay_panel: Panel
var deck_list_container: VBoxContainer
var stats_detail_label: Label
var guide_label: Label

# HUD visibility and deck state tracking.
var is_visible: bool = false
var is_deck_overlay_open: bool = false

func _ready() -> void:
	# Build the HUD interface overlay.
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 80 # Display on top of exploration scenes
	add_child(canvas_layer)
	
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.visible = false
	canvas_layer.add_child(root_control)
	
	# Premium dark styling.
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.1, 0.75)
	style_box.corner_radius_bottom_left = 6
	style_box.corner_radius_bottom_right = 6
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.2, 0.25, 0.35, 0.5)
	
	# 1. Stats Panel (Top-Left).
	stats_panel = Panel.new()
	stats_panel.position = Vector2(20, 20)
	stats_panel.custom_minimum_size = Vector2(220, 100)
	stats_panel.add_theme_stylebox_override("panel", style_box)
	root_control.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats_vbox.offset_left = 15
	stats_vbox.offset_top = 10
	stats_vbox.offset_right = -15
	stats_vbox.offset_bottom = -10
	stats_panel.add_child(stats_vbox)
	
	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 13)
	stats_vbox.add_child(hp_label)
	
	fragments_label = Label.new()
	fragments_label.add_theme_font_size_override("font_size", 13)
	stats_vbox.add_child(fragments_label)
	
	buffs_label = Label.new()
	buffs_label.add_theme_font_size_override("font_size", 13)
	stats_vbox.add_child(buffs_label)
	
	# 2. Objective Panel (Top-Center).
	objective_panel = Panel.new()
	objective_panel.anchor_left = 0.5
	objective_panel.anchor_right = 0.5
	objective_panel.offset_left = -225
	objective_panel.offset_top = 20
	objective_panel.offset_right = 225
	objective_panel.offset_bottom = 70
	objective_panel.add_theme_stylebox_override("panel", style_box)
	root_control.add_child(objective_panel)
	
	objective_label = Label.new()
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 13)
	objective_panel.add_child(objective_label)
	
	# 3. Controls Hint Panel (Top-Right) - Enlarged to display Deck hotkey.
	controls_panel = Panel.new()
	controls_panel.anchor_left = 1.0
	controls_panel.anchor_right = 1.0
	controls_panel.offset_left = -280
	controls_panel.offset_top = 20
	controls_panel.offset_right = -20
	controls_panel.offset_bottom = 70
	controls_panel.add_theme_stylebox_override("panel", style_box)
	root_control.add_child(controls_panel)
	
	controls_label = Label.new()
	controls_label.text = "A/D: Move | E: Interact | Tab: Deck & Guide"
	controls_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_panel.add_child(controls_label)
	
	# 4. Programmatic Deck Overlay & Narrative Guide Panel.
	deck_overlay_panel = Panel.new()
	deck_overlay_panel.anchor_left = 0.1
	deck_overlay_panel.anchor_right = 0.9
	deck_overlay_panel.anchor_top = 0.1
	deck_overlay_panel.anchor_bottom = 0.9
	deck_overlay_panel.offset_left = 0
	deck_overlay_panel.offset_top = 0
	deck_overlay_panel.offset_right = 0
	deck_overlay_panel.offset_bottom = 0
	
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.05, 0.05, 0.07, 0.95)
	overlay_style.corner_radius_top_left = 12
	overlay_style.corner_radius_top_right = 12
	overlay_style.corner_radius_bottom_left = 12
	overlay_style.corner_radius_bottom_right = 12
	overlay_style.border_width_left = 2
	overlay_style.border_width_top = 2
	overlay_style.border_width_right = 2
	overlay_style.border_width_bottom = 2
	overlay_style.border_color = Color(0.3, 0.45, 0.6, 0.8) # Premium sky-blue border
	deck_overlay_panel.add_theme_stylebox_override("panel", overlay_style)
	deck_overlay_panel.visible = false
	root_control.add_child(deck_overlay_panel)
	
	var overlay_margin = MarginContainer.new()
	overlay_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", 20)
	overlay_margin.add_theme_constant_override("margin_right", 20)
	overlay_margin.add_theme_constant_override("margin_top", 15)
	overlay_margin.add_theme_constant_override("margin_bottom", 15)
	deck_overlay_panel.add_child(overlay_margin)
	
	var main_vbox = VBoxContainer.new()
	overlay_margin.add_child(main_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "PLAYER STATUS & DECK INVENTORY"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.modulate = Color(0.4, 0.7, 1.0, 1.0)
	main_vbox.add_child(title_lbl)
	
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size.y = 8
	main_vbox.add_child(header_spacer)
	
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)
	
	# Left: Master Deck Panel
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(left_vbox)
	
	var deck_title = Label.new()
	deck_title.text = "Master Deck List"
	deck_title.add_theme_font_size_override("font_size", 13)
	deck_title.modulate = Color(0.8, 0.9, 1.0, 1.0)
	left_vbox.add_child(deck_title)
	
	var deck_scroll = ScrollContainer.new()
	deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(deck_scroll)
	
	deck_list_container = VBoxContainer.new()
	deck_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_scroll.add_child(deck_list_container)
	
	# Right: Stats, Buffs & Narrative Guide
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.custom_minimum_size.x = 280
	content_hbox.add_child(right_vbox)
	
	var status_title = Label.new()
	status_title.text = "Next Battle Starting Status"
	status_title.add_theme_font_size_override("font_size", 13)
	status_title.modulate = Color(0.8, 0.9, 1.0, 1.0)
	right_vbox.add_child(status_title)
	
	stats_detail_label = Label.new()
	stats_detail_label.add_theme_font_size_override("font_size", 11)
	right_vbox.add_child(stats_detail_label)
	
	var right_spacer = Control.new()
	right_spacer.custom_minimum_size.y = 8
	right_vbox.add_child(right_spacer)
	
	var guide_title = Label.new()
	guide_title.text = "How to Play & Narrative Guide"
	guide_title.add_theme_font_size_override("font_size", 13)
	guide_title.modulate = Color(0.8, 0.9, 1.0, 1.0)
	right_vbox.add_child(guide_title)
	
	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.add_theme_font_size_override("font_size", 10.5)
	# Explain the gameplay loop and narrative connection to alleviate user confusion.
	guide_label.text = "You are Hilbert Hickman. Your friend Leo recently passed away. Hilbert's mind is blocking out the grief, creating a vibrant dream world to cope.\n\nGameplay Loop:\n1. Explore reality (Grey morning) to find items, talk to peers, and uncover memories. These choices grant starting buffs or add powerful cards to your deck.\n2. In combat, you can Dimension Shift back to reality once your shift charge is ready, allowing you to search reality for solutions mid-battle.\n3. Be Warned: Escaping the stress through delusion will help you win, but the more you shift, the more you erase Leo's memory..."
	guide_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(guide_label)
	
	# Close footer hint
	var footer_lbl = Label.new()
	footer_lbl.text = "[Press TAB to close stats overlay]"
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_font_size_override("font_size", 11)
	footer_lbl.modulate = Color(0.6, 0.6, 0.6, 1.0)
	main_vbox.add_child(footer_lbl)
	
	# Connect to Global Event Bus to refresh HUD stats on interaction.
	EventBus.player_interacted.connect(func(_id): update_hud())
	EventBus.dialogue_finished.connect(update_hud)

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
	# Clear old list.
	for child in deck_list_container.get_children():
		child.queue_free()
		
	# Count occurrences of cards in the deck to group them.
	var card_counts = {}
	for card in GlobalState.master_deck:
		if card:
			var name = card.card_name
			if not card_counts.has(name):
				card_counts[name] = {"count": 0, "card": card}
			card_counts[name]["count"] += 1
			
	# Render the grouped list.
	if card_counts.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No cards in deck."
		empty_lbl.add_theme_font_size_override("font_size", 11)
		deck_list_container.add_child(empty_lbl)
	else:
		for name in card_counts:
			var info = card_counts[name]
			var card_res = info["card"]
			var count = info["count"]
			
			var card_lbl = Label.new()
			card_lbl.text = "%s (x%d) - Cost: %d energy\n  Type: %s | %s" % [
				card_res.card_name,
				count,
				card_res.energy_cost,
				card_res.card_type,
				card_res.description
			]
			card_lbl.add_theme_font_size_override("font_size", 11)
			card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			deck_list_container.add_child(card_lbl)
			
			var item_spacer = Control.new()
			item_spacer.custom_minimum_size.y = 5
			deck_list_container.add_child(item_spacer)
			
	# Update status details.
	var active_buffs = []
	if GlobalState.has_flag("buff_courage_active"):
		active_buffs.append("Courage (1.5x Dmg)")
	if GlobalState.has_flag("buff_confidence_active"):
		active_buffs.append("Confidence (2.0x Dmg)")
	var buffs_str = ", ".join(active_buffs) if not active_buffs.is_empty() else "None"
	
	# Display next combat turn 1 stats.
	stats_detail_label.text = "Current HP: %d/%d\nActive Buffs: %s\n\nFirst Turn Modifiers:\n- Energy: %s%d\n- Block: +%d\n- Draw size: %s%d" % [
		GlobalState.player_current_hp,
		GlobalState.player_max_hp,
		buffs_str,
		"+" if GlobalState.starting_energy_modifier >= 0 else "",
		GlobalState.starting_energy_modifier,
		GlobalState.starting_block_modifier,
		"+" if GlobalState.starting_draw_modifier >= 0 else "",
		GlobalState.starting_draw_modifier
	]

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
	if not is_visible:
		return
		
	# 1. Update stats indicators.
	hp_label.text = "HP: " + str(GlobalState.player_current_hp) + "/" + str(GlobalState.player_max_hp)
	fragments_label.text = "Dream Fragments: " + str(GlobalState.acquired_fragments)
	
	var active_buffs = []
	if GlobalState.has_flag("buff_courage_active"):
		active_buffs.append("Courage (1.5x Dmg)")
	if GlobalState.has_flag("buff_confidence_active"):
		active_buffs.append("Confidence (2.0x Dmg)")
		
	if active_buffs.is_empty():
		buffs_label.text = "Active Buffs: None"
	else:
		buffs_label.text = "Active Buffs: " + ", ".join(active_buffs)
		
	# 2. Update dynamic objectives depending on the scene tree.
	var current_scene_name = get_tree().current_scene.name
	var objective_text = "Objective: Explore."
	
	match current_scene_name:
		"Apartment":
			var apt_node = get_tree().current_scene
			if apt_node and not apt_node.has_showered:
				objective_text = "Objective: Interact with the shower to prepare for the Monday quiz."
			else:
				objective_text = "Objective: Walk to the door and exit the apartment to attend class."
		"Hallway":
			objective_text = "Objective: Head down the faculty building hallway to your quiz."
		"Classroom":
			if ShiftManager.cached_combat_exists:
				objective_text = "Objective: A strange Paper Monster has appeared! Use your Dream Fragment on it."
			else:
				objective_text = "Objective: Search the lockers for buffs, then sit at your desk to start the quiz."
				
	objective_label.text = objective_text
