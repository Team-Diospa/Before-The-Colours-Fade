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

# HUD visibility tracking.
var is_visible: bool = false

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
	
	# 3. Controls Hint Panel (Top-Right).
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
	controls_label.add_theme_font_size_override("font_size", 13)
	controls_panel.add_child(controls_label)
	
	# Connect to Global Event Bus to refresh HUD stats on interaction.
	EventBus.player_interacted.connect(func(_id): update_hud())
	EventBus.dialogue_finished.connect(update_hud)

# Show the HUD and run a refresh.
func show_hud() -> void:
	is_visible = true
	root_control.visible = true
	update_hud()

# Hide the HUD in combat arenas.
func hide_hud() -> void:
	is_visible = false
	root_control.visible = false

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
