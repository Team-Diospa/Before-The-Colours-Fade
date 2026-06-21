extends Node
# Autoload singleton for loading and rendering branching dialogue trees.
# This programmatically builds its UI overlay to remain self-contained and avoid broken references.

# Current active dialogue tree structure.
var dialogue_tree: Dictionary = {}
# The key of the currently active dialogue node.
var current_node_id: String = ""

# Programmatic UI elements.
var canvas_layer: CanvasLayer
var root_control: Control
var dialogue_panel: Panel
var speaker_label: Label
var text_label: Label
var options_container: VBoxContainer
# Continuation indicator character for classic RPG dialog feel.
var continue_indicator: Label

# Speaker portrait container and assets.
# RATIONALE: Display speaker sprite or custom silhouette on the left side of the bottom panel.
var portrait_container: Panel
var portrait_bg: ColorRect
var portrait_head: ColorRect
var portrait_shoulders: ColorRect
var portrait_texture: TextureRect

# Toast container for non-intrusive system notifications.
var _toast_container: VBoxContainer

# Portrait color per NPC (reused from exploration speech bubble logic).
const PORTRAIT_COLORS: Dictionary = {
	"Landlady": Color(0.62, 0.45, 0.35, 1.0),  # Warm terracotta
	"n.n.":     Color(0.35, 0.52, 0.68, 1.0),  # Steel blue - mechanical entity
	"Peer 1":   Color(0.45, 0.55, 0.45, 1.0),  # Muted sage
	"Peer 2":   Color(0.60, 0.42, 0.45, 1.0),  # Dusty rose
	"Professor":Color(0.42, 0.42, 0.52, 1.0),  # Slate grey authority
	"???":      Color(0.22, 0.22, 0.25, 1.0),  # Dark unknown
	"Peer A":   Color(0.42, 0.52, 0.42, 1.0),  # Darker sage
	"Peer B":   Color(0.55, 0.38, 0.42, 1.0),  # Darker dusty rose
}

# Portrait silhouette shapes (drawn as pixel blocks using ColorRect panels).
const PORTRAIT_SKIN_COLORS: Dictionary = {
	"Landlady": Color(0.85, 0.72, 0.60, 1.0),  # Warm skin tone
	"n.n.":     Color(0.72, 0.82, 0.92, 1.0),  # Cold mechanical sheen
	"Peer 1":   Color(0.82, 0.75, 0.62, 1.0),
	"Peer 2":   Color(0.78, 0.68, 0.60, 1.0),
	"Professor":Color(0.70, 0.70, 0.72, 1.0),
	"???":      Color(0.20, 0.20, 0.22, 1.0),
	"Peer A":   Color(0.80, 0.72, 0.60, 1.0),
	"Peer B":   Color(0.76, 0.65, 0.58, 1.0),
}

# Visual novel mode layout variables.
# RATIONALE: Fullscreen overlay mode dynamically centers text and panels.
var _is_fullscreen_mode: bool = false
var margin_container: MarginContainer
var layout_container: BoxContainer
var text_vbox: VBoxContainer

# Tracks if dialogue is active.
var is_active: bool = false

# Current options mapped to their target nodes.
var active_options: Array = []

# RATIONALE: Keep track of printing state to prevent accidental dialogue skipping.
var _is_typing: bool = false
var _active_tween: Tween
var _continue_tween: Tween   # Reference to manage continue indicator pulsing safely

# Tracks if dialogue is being fast-forwarded (skipped) by player pressing space/E.
var _fast_forward: bool = false

# Tracks the unique ID of the active typing coroutine to prevent race conditions when skipped.
var _typing_session_id: int = 0

# Tracks whether the dialogue is currently drawn in the dream/combat world.
var _is_dream_world: bool = false

# Dynamically updates the dialogue styling depending on whether the scene is dream or reality.
# Ensures seamless visual transitions between the warm beige sketch and cold slate aesthetics.
func _update_ui_style() -> void:
	# RATIONALE: We no longer auto-detect the scene path here to respect per-node overrides.
	# The initial state is set in start_dialogue(), and per-node overrides update the variables.
	var style_box = StyleBoxFlat.new()
	style_box.corner_radius_top_left = 0
	style_box.corner_radius_top_right = 0
	style_box.corner_radius_bottom_left = 0
	style_box.corner_radius_bottom_right = 0
	style_box.anti_aliasing = false
	
	# Dynamically modify panel anchors, borders, and margins based on whether we are in fullscreen cutscene mode.
	if _is_fullscreen_mode:
		style_box.border_width_left = 0
		style_box.border_width_top = 0
		style_box.border_width_right = 0
		style_box.border_width_bottom = 0
		style_box.shadow_size = 0
		
		# Anchor dialogue panel to fill the entire rect.
		dialogue_panel.anchor_top = 0.0
		dialogue_panel.anchor_left = 0.0
		dialogue_panel.anchor_right = 1.0
		dialogue_panel.anchor_bottom = 1.0
		dialogue_panel.offset_top = 0.0
		dialogue_panel.offset_left = 0.0
		dialogue_panel.offset_right = 0.0
		dialogue_panel.offset_bottom = 0.0
		
		# Add generous padding for a centered reading experience.
		margin_container.add_theme_constant_override("margin_left", 180)
		margin_container.add_theme_constant_override("margin_right", 180)
		margin_container.add_theme_constant_override("margin_top", 120)
		margin_container.add_theme_constant_override("margin_bottom", 120)
		
		# Center-align text and speaker labels.
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Stack options vertically beneath the text.
		layout_container.vertical = true
		layout_container.alignment = BoxContainer.ALIGNMENT_CENTER
		layout_container.add_theme_constant_override("separation", 20)
		
		# Position continue indicator in the lower-middle portion of the screen.
		continue_indicator.anchor_left = 0.5
		continue_indicator.anchor_top = 0.9
		continue_indicator.anchor_right = 0.5
		continue_indicator.anchor_bottom = 0.9
		continue_indicator.offset_left = -10.0
		continue_indicator.offset_top = -10.0
		continue_indicator.offset_right = 10.0
		continue_indicator.offset_bottom = 10.0
		
		# Configure solid background color depending on dream vs reality.
		if _is_dream_world:
			style_box.bg_color = Color(0.94, 0.92, 0.88, 0.98) # High-opacity warm sketch paper
			text_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
			speaker_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Brick red speaker badge
			continue_indicator.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
		else:
			style_box.bg_color = Color(0.02, 0.02, 0.03, 0.98) # Cinematic near-black reality overlay
			text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			speaker_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0)) # Silver speaker badge
			continue_indicator.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
	else:
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.shadow_offset = Vector2(2, 2)
		
		# Reset anchors to bottom docked panel (160px height).
		dialogue_panel.anchor_top = 1.0
		dialogue_panel.anchor_left = 0.0
		dialogue_panel.anchor_right = 1.0
		dialogue_panel.anchor_bottom = 1.0
		dialogue_panel.offset_top = -160.0
		dialogue_panel.offset_left = 0.0
		dialogue_panel.offset_right = 0.0
		dialogue_panel.offset_bottom = 0.0
		
		# Reset standard small margins.
		margin_container.add_theme_constant_override("margin_left", 30)
		margin_container.add_theme_constant_override("margin_right", 30)
		margin_container.add_theme_constant_override("margin_top", 20)
		margin_container.add_theme_constant_override("margin_bottom", 20)
		
		# Reset text alignment to top-left.
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Reset container layout to horizontal.
		layout_container.vertical = false
		layout_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		layout_container.add_theme_constant_override("separation", 10)
		
		# Reset continue indicator to bottom-right corner of the panel.
		continue_indicator.anchor_left = 1.0
		continue_indicator.anchor_top = 1.0
		continue_indicator.anchor_right = 1.0
		continue_indicator.anchor_bottom = 1.0
		continue_indicator.offset_left = -30.0
		continue_indicator.offset_top = -25.0
		continue_indicator.offset_right = -15.0
		continue_indicator.offset_bottom = -10.0
		
		# Configure semi-transparent colors.
		if _is_dream_world:
			style_box.bg_color = Color(0.96, 0.95, 0.92, 0.65) # Warm beige translucent paper glass
			style_box.border_color = Color(0.12, 0.12, 0.15, 0.15) # Soft translucent charcoal border
			style_box.shadow_color = Color(0, 0, 0, 0.1) # Soft muted shadow
			style_box.shadow_size = 2
			
			text_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
			speaker_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Brick red badge
			continue_indicator.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
		else:
			style_box.bg_color = Color(0.06, 0.08, 0.12, 0.5) # Dark slate translucent glass
			style_box.border_color = Color(1.0, 1.0, 1.0, 0.15) # Thin white glass shine border
			style_box.shadow_color = Color(0, 0, 0, 0.25) # Soft subtle shadow
			style_box.shadow_size = 4
			
			text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			speaker_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0)) # Soft silver speaker badge
			continue_indicator.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1.0))
		
	dialogue_panel.add_theme_stylebox_override("panel", style_box)

func _ready() -> void:
	# Build dialogue overlay UI programmatically.
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 90 # Below scene transition layer
	add_child(canvas_layer)
	
	# Root control node covering full viewport.
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Set mouse filter to ignore so clicks pass through empty spaces.
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.visible = false # Hidden initially
	canvas_layer.add_child(root_control)
	
	# Main dialog container panel.
	dialogue_panel = Panel.new()
	dialogue_panel.visible = false
	dialogue_panel.modulate.a = 0.0 # Start transparent for fade-in
	root_control.add_child(dialogue_panel)
	
	# Position panel at the bottom of the screen.
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_right = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_top = -160.0
	dialogue_panel.offset_right = 0.0
	dialogue_panel.offset_bottom = 0.0
	dialogue_panel.offset_left = 0.0
	
	
	# MarginContainer for padding.
	# RATIONALE: We make this a class member to dynamically override margins for fullscreen cutscene layouts.
	margin_container = MarginContainer.new()
	margin_container.anchor_right = 1.0
	margin_container.anchor_bottom = 1.0
	margin_container.offset_right = 0.0
	margin_container.offset_bottom = 0.0
	margin_container.offset_left = 0.0
	margin_container.offset_top = 0.0
	margin_container.add_theme_constant_override("margin_left", 30)
	margin_container.add_theme_constant_override("margin_right", 30)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	dialogue_panel.add_child(margin_container)
	
	# BoxContainer to support dynamic switching between horizontal and vertical layouts.
	layout_container = BoxContainer.new()
	margin_container.add_child(layout_container)
	
	# Speaker portrait container and assets.
	# RATIONALE: Create a dedicated portrait panel placed on the left side of layout_container.
	portrait_container = Panel.new()
	portrait_container.custom_minimum_size = Vector2(80, 100)
	portrait_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var portrait_style = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.0, 0.0, 0.0, 0.2)
	portrait_style.border_width_left = 1
	portrait_style.border_width_top = 1
	portrait_style.border_width_right = 1
	portrait_style.border_width_bottom = 1
	portrait_style.border_color = Color(1.0, 1.0, 1.0, 0.1)
	portrait_style.corner_radius_top_left = 2
	portrait_style.corner_radius_top_right = 2
	portrait_style.corner_radius_bottom_left = 2
	portrait_style.corner_radius_bottom_right = 2
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	layout_container.add_child(portrait_container)
	
	portrait_bg = ColorRect.new()
	portrait_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_bg.color = Color(0.25, 0.25, 0.3, 1.0)
	portrait_container.add_child(portrait_bg)
	
	portrait_head = ColorRect.new()
	portrait_head.anchor_left   = 0.25
	portrait_head.anchor_right  = 0.75
	portrait_head.anchor_top    = 0.10
	portrait_head.anchor_bottom = 0.48
	portrait_head.color = Color(0.85, 0.72, 0.60, 1.0)
	portrait_container.add_child(portrait_head)
	
	portrait_shoulders = ColorRect.new()
	portrait_shoulders.anchor_left   = 0.10
	portrait_shoulders.anchor_right  = 0.90
	portrait_shoulders.anchor_top    = 0.55
	portrait_shoulders.anchor_bottom = 1.00
	portrait_shoulders.color = Color(0.55, 0.45, 0.38, 1.0)
	portrait_container.add_child(portrait_shoulders)
	
	portrait_texture = TextureRect.new()
	portrait_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_texture.visible = false
	portrait_container.add_child(portrait_texture)
	
	# RATIONALE: Nesting labels inside a VBox container to show speaker badge above dialogue text.
	text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	layout_container.add_child(text_vbox)
	
	# Speaker label widget.
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.modulate = Color(0.4, 0.7, 1.0, 1.0) # Sky blue highlight for speakers
	speaker_label.text = ""
	text_vbox.add_child(speaker_label)
	
	# Label to render the text.
	text_label = Label.new()
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 16)
	text_vbox.add_child(text_label)
	
	# VBoxContainer to render branch choice buttons.
	options_container = VBoxContainer.new()
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_container.custom_minimum_size.x = 220
	layout_container.add_child(options_container)
	
	# Continuation indicator (pulsing upside-down triangle).
	continue_indicator = Label.new()
	continue_indicator.text = "▼"
	continue_indicator.add_theme_font_size_override("font_size", 12)
	continue_indicator.modulate = Color(0.6, 0.7, 0.8, 1.0)
	continue_indicator.anchor_left = 1.0
	continue_indicator.anchor_top = 1.0
	continue_indicator.anchor_right = 1.0
	continue_indicator.anchor_bottom = 1.0
	continue_indicator.offset_left = -30.0
	continue_indicator.offset_top = -25.0
	continue_indicator.offset_right = -15.0
	continue_indicator.offset_bottom = -10.0
	continue_indicator.visible = false
	dialogue_panel.add_child(continue_indicator)
	
	# Dynamically apply initial dialogue styling based on current scene state.
	_update_ui_style()
	
	# Connect to EventBus signals.
	EventBus.dialogue_option_selected.connect(select_option)
	
	# Toast Notification Container.
	# RATIONALE: Set up a VBoxContainer anchored at top-center to manage toast notifications.
	_toast_container = VBoxContainer.new()
	_toast_container.anchor_left = 0.5
	_toast_container.anchor_top = 0.0
	_toast_container.anchor_right = 0.5
	_toast_container.anchor_bottom = 0.0
	_toast_container.offset_left = -250.0
	_toast_container.offset_right = 250.0
	_toast_container.offset_top = 40.0
	_toast_container.offset_bottom = 400.0
	_toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_container.add_theme_constant_override("separation", 10)
	canvas_layer.add_child(_toast_container)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Advance dialogue when E or Space is pressed, if there are no branching options.
	if (event.is_action_pressed("e") or event.is_action_pressed("space")):
		# RATIONALE: If dialogue is still drawing, first press stops typewriter animation.
		# A subsequent press is required to advance nodes, preventing skipping.
		if _is_typing:
			_is_typing = false # Will break the typing coroutine
			_fast_forward = true
			# RATIONALE: All NPC dialogues are now routed to the bottom panel; speech bubbles are bypassed.
			text_label.visible_characters = -1 # Show all text
			if continue_indicator:
				continue_indicator.visible = true
				if _continue_tween and _continue_tween.is_valid():
					_continue_tween.kill()
				_continue_tween = continue_indicator.create_tween().set_loops()
				_continue_tween.tween_property(continue_indicator, "modulate:a", 0.2, 0.4)
				_continue_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.4)
			get_viewport().set_input_as_handled()
			return
			
		if active_options.is_empty():
			# Hide continuation indicator when advancing.
			if _continue_tween and _continue_tween.is_valid():
				_continue_tween.kill()
			continue_indicator.visible = false
			BubbleManager.show_continue_indicator(false)
			# Fetch next node from current node data.
			var node_data = dialogue_tree.get(current_node_id, {})
			var next_node_id = node_data.get("next", "")
			
			if next_node_id != "":
				var next_node_data = dialogue_tree.get(next_node_id, {})
				var current_fade = node_data.get("fade_out", false)
				var will_layout_change = false
				
				# Check layout change
				if next_node_data.has("fullscreen"):
					if next_node_data["fullscreen"] != _is_fullscreen_mode:
						will_layout_change = true
				# Check dream world style change
				if next_node_data.has("dream_world"):
					if next_node_data["dream_world"] != _is_dream_world:
						will_layout_change = true
						
				if current_fade or will_layout_change:
					# RATIONALE: Fade out dialogue panel to hide visual snaps during layout/state shifts.
					var fade_tw = create_tween()
					fade_tw.tween_property(dialogue_panel, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
					await fade_tw.finished
					
				_play_node(next_node_id)
			else:
				# End of dialogue tree reached.
				close_dialogue()
			get_viewport().set_input_as_handled()

# Load and start a dialogue sequence from a Dictionary.
# RATIONALE: Optional is_fullscreen_narration boolean allows displaying long narrative sequences
# in a visual-novel cinematic format with centered text and stacked choices.
func start_dialogue(tree: Dictionary, start_node: String = "start", is_fullscreen_narration: bool = false) -> void:
	dialogue_tree = tree
	is_active = true
	_is_fullscreen_mode = is_fullscreen_narration
	
	# RATIONALE: Initialize default dream world state from scene file path.
	_is_dream_world = false
	if get_tree() and get_tree().current_scene:
		var path = get_tree().current_scene.scene_file_path
		if path != "" and ("combat" in path or "field" in path or "village" in path):
			_is_dream_world = true
			
	# Check if the start node is a system node.
	# RATIONALE: Skip showing the main dialogue box if the conversation starts with a system notification.
	var is_first_node_system = false
	if dialogue_tree.has(start_node):
		var node_data = dialogue_tree[start_node]
		var raw_text = node_data.get("text", "")
		var speaker = node_data.get("speaker", "")
		if speaker == "":
			if ": " in raw_text:
				var parts = raw_text.split(": ", false, 1)
				if parts[0].length() < 16:
					speaker = parts[0]
		is_first_node_system = (speaker == "System") or raw_text.begins_with("[System]") or raw_text.begins_with("[System]:")
		
	if not is_first_node_system:
		root_control.visible = true # Enable full overlay control node
		dialogue_panel.visible = true
		dialogue_panel.modulate.a = 0.0
		
		# Dynamically update styling to adapt to the active world mode (dream vs. reality) and fullscreen state.
		_update_ui_style()
		
		# Smooth fade-in
		var tw = create_tween()
		tw.tween_property(dialogue_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	else:
		root_control.visible = false
		dialogue_panel.visible = false
		dialogue_panel.modulate.a = 0.0
		_update_ui_style()
	
	EventBus.dialogue_started.emit(start_node)
	_play_node(start_node)

# Helper to play a specific node.
func _play_node(node_id: String) -> void:
	current_node_id = node_id
	if continue_indicator:
		if _continue_tween and _continue_tween.is_valid():
			_continue_tween.kill()
		continue_indicator.visible = false
	BubbleManager.show_continue_indicator(false)
	if not dialogue_tree.has(node_id):
		close_dialogue()
		return
		
	var node_data = dialogue_tree[node_id]
	
	# RATIONALE: Support per-node fullscreen and dream world overrides so a dialogue sequence can transition
	# layouts and background aesthetics dynamically mid-sequence.
	var changed = false
	if node_data.has("fullscreen"):
		var f = node_data["fullscreen"]
		if f != _is_fullscreen_mode:
			_is_fullscreen_mode = f
			changed = true
	if node_data.has("dream_world"):
		var d = node_data["dream_world"]
		if d != _is_dream_world:
			_is_dream_world = d
			changed = true
			
	if changed:
		_update_ui_style()
		
	var raw_text = node_data.get("text", "")
	
	# RATIONALE: Prefer explicit "speaker" field in node data over the split heuristic.
	var speaker = ""
	var body_text = raw_text
	if node_data.has("speaker"):
		speaker = node_data["speaker"]
		body_text = raw_text
	elif ": " in raw_text:
		var parts = raw_text.split(": ", false, 1)
		if parts[0].length() < 16:
			speaker = parts[0]
			body_text = parts[1]
			
	# RATIONALE: Intercept system nodes starting with [System] (using raw_text to bypass splitting side effects) and route them to floating notifications, auto-advancing dialogue.
	var is_system = (speaker == "System") or raw_text.begins_with("[System]") or raw_text.begins_with("[System]:")
	if is_system:
		show_toast(raw_text)
		var next_node_id = node_data.get("next", "")
		if next_node_id != "":
			get_tree().process_frame.connect(func(): _play_node(next_node_id), CONNECT_ONE_SHOT)
		else:
			close_dialogue()
		return
		
	# RATIONALE: Ensure dialogue panel is shown for non-system nodes.
	if not dialogue_panel.visible:
		root_control.visible = true
		dialogue_panel.visible = true
	if dialogue_panel.modulate.a < 1.0:
		var fade_in_tw = create_tween()
		fade_in_tw.tween_property(dialogue_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	
	if speaker != "":
		# RATIONALE: Strip brackets if the name is wrapped in them, and do not add brackets to speaker names.
		if speaker.begins_with("[") and speaker.ends_with("]"):
			speaker_label.text = speaker.substr(1, speaker.length() - 2)
		else:
			speaker_label.text = speaker
	else:
		speaker_label.text = ""
		
	# RATIONALE: Setup the left portrait panel and display actual sprites or procedural silhouettes.
	if _is_fullscreen_mode or speaker == "":
		portrait_container.visible = false
	else:
		portrait_container.visible = true
		if speaker == "Hilbert":
			portrait_texture.visible = true
			portrait_texture.texture = load("res://Assets/Sprites/character3.png")
			portrait_bg.visible = false
			portrait_head.visible = false
			portrait_shoulders.visible = false
		elif speaker == "n.n.":
			portrait_texture.visible = true
			portrait_texture.texture = load("res://Assets/Sprites/Monster.png")
			portrait_bg.visible = false
			portrait_head.visible = false
			portrait_shoulders.visible = false
		else:
			portrait_texture.visible = false
			portrait_bg.visible = true
			portrait_head.visible = true
			portrait_shoulders.visible = true
			
			var bg_col    = PORTRAIT_COLORS.get(speaker,      Color(0.25, 0.25, 0.3, 1.0))
			var skin_col  = PORTRAIT_SKIN_COLORS.get(speaker, Color(0.75, 0.65, 0.55, 1.0))
			var cloth_col = bg_col.darkened(0.25)
			
			portrait_bg.color        = bg_col
			portrait_head.color      = skin_col
			portrait_shoulders.color = cloth_col
	
	# RATIONALE: All NPC dialogues are now routed to the bottom panel; speech bubbles are bypassed.
	var _is_npc_line = false
	BubbleManager.hide_bubble()
	
	speaker_label.visible = speaker != ""
	text_label.text = body_text
	
	# Style-specific text modulations for high contrast and readability.
	if speaker_label.text == "System":
		if _is_dream_world:
			# RATIONALE: Use a neutral graphite/pencil-grey color for the system speaker and system message text
			# to fit cleanly into the warm beige sketch style of the dream world without dirty green/brown tints.
			text_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1.0))
			speaker_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1.0))
		else:
			# RATIONALE: Use a neutral light silver-grey color for the system speaker and system message text
			# to stand out clearly but elegantly in the dark slate reality style without jarring amber highlights.
			text_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1.0))
			speaker_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1.0))
	else:
		if _is_dream_world:
			text_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0)) # Dark slate body in dream
			speaker_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Warm brick-red speaker in dream
		else:
			text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0)) # White body in reality
			speaker_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0)) # Soft silver speaker in reality
	
	# Print to console for editor debugging.
	print("[Dialogue Node ID: ", node_id, "] ", raw_text)
	
	# Clear old buttons.
	for child in options_container.get_children():
		child.queue_free()
		
	active_options.clear()
	
	# Populate options if available, before typing starts so they are ready.
	if node_data.has("options"):
		var options = node_data["options"]
		for i in range(options.size()):
			var opt = options[i]
			var btn = Button.new()
			btn.text = opt.get("text", "")
			
			# Construct option button styleboxes to match dream or reality environments.
			var style_normal = StyleBoxFlat.new()
			style_normal.corner_radius_top_left = 0
			style_normal.corner_radius_top_right = 0
			style_normal.corner_radius_bottom_left = 0
			style_normal.corner_radius_bottom_right = 0
			style_normal.border_width_left = 2
			style_normal.border_width_top = 2
			style_normal.border_width_right = 2
			style_normal.border_width_bottom = 2
			style_normal.anti_aliasing = false
			
			var style_hover = style_normal.duplicate()
			var style_pressed = style_normal.duplicate()
			
			if _is_dream_world:
				style_normal.bg_color = Color(0.92, 0.90, 0.84, 0.65) # Translucent paper cream
				style_normal.border_color = Color(0.12, 0.12, 0.15, 0.15) # Very thin charcoal outline
				style_normal.shadow_color = Color(0, 0, 0, 0.08)
				style_normal.shadow_size = 1
				style_normal.shadow_offset = Vector2(1, 1)
				
				style_hover.bg_color = Color(0.97, 0.95, 0.90, 0.75)
				style_hover.border_color = Color(0.65, 0.25, 0.15, 0.5) # Soft brick red outline
				style_hover.shadow_color = Color(0, 0, 0, 0.08)
				style_hover.shadow_size = 1
				style_hover.shadow_offset = Vector2(1, 1)
				
				style_pressed.bg_color = Color(0.85, 0.83, 0.77, 0.7)
				style_pressed.border_color = Color(0.12, 0.12, 0.15, 0.15)
				style_pressed.shadow_offset = Vector2(0, 0)
				
				btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
				btn.add_theme_color_override("font_hover_color", Color(0.65, 0.25, 0.15, 1.0))
				btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.12, 0.15, 1.0))
			else:
				style_normal.bg_color = Color(0.08, 0.1, 0.16, 0.5) # Translucent slate
				style_normal.border_color = Color(1.0, 1.0, 1.0, 0.1) # Translucent white highlight
				style_normal.shadow_color = Color(0, 0, 0, 0.15)
				style_normal.shadow_size = 2
				style_normal.shadow_offset = Vector2(1, 1)
				
				style_hover.bg_color = Color(0.18, 0.18, 0.22, 0.6) # Translucent grey glass hover background
				style_hover.border_color = Color(0.8, 0.8, 0.8, 0.5) # Soft silver highlight outline
				style_hover.shadow_color = Color(0, 0, 0, 0.15)
				style_hover.shadow_size = 2
				style_hover.shadow_offset = Vector2(1, 1)
				
				style_pressed.bg_color = Color(0.05, 0.06, 0.08, 0.6)
				style_pressed.border_color = Color(1.0, 1.0, 1.0, 0.05)
				style_pressed.shadow_offset = Vector2(0, 0)
				
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
				btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0)) # Crisp white hover text
				btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
				
			btn.add_theme_stylebox_override("normal", style_normal)
			btn.add_theme_stylebox_override("hover", style_hover)
			btn.add_theme_stylebox_override("pressed", style_pressed)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			
			btn.pivot_offset = Vector2(110, 15) # Center for scaling
			btn.mouse_entered.connect(func():
				btn.text = "▼ " + opt.get("text", "") # Prefix with upside-down triangle on hover
				var tw = btn.create_tween().set_parallel(true)
				tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			)
			btn.mouse_exited.connect(func():
				btn.text = opt.get("text", "") # Revert text
				var tw = btn.create_tween().set_parallel(true)
				tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			)
			
			btn.pressed.connect(func(): EventBus.dialogue_option_selected.emit(i))
			options_container.add_child(btn)
			
			# Dynamic pop-in bounce animation for dialogue buttons.
			btn.scale = Vector2(0.6, 0.6)
			btn.modulate.a = 0.0
			var pop_tw = btn.create_tween().set_parallel(true)
			pop_tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop_tw.tween_property(btn, "modulate:a", 1.0, 0.15)
			
			active_options.append(opt.get("next", ""))
			
	EventBus.dialogue_text_updated.emit(raw_text, active_options)
	
	var active_text_label = text_label
	
	# Fastened dialogue typewriter pacing.
	# Increment the typing session ID to signal any running coroutines to exit immediately.
	_typing_session_id += 1
	var current_session = _typing_session_id
	_is_typing = true
	_fast_forward = false
	active_text_label.visible_characters = 0
	
	for i in range(body_text.length()):
		# If the typing state has been cleared, fast-forwarded, or a new session started, abort.
		if not _is_typing or _fast_forward or current_session != _typing_session_id:
			break # User skipped animation or advanced node
			
		active_text_label.visible_characters = i + 1
		
		# RATIONALE: Check dynamically if the player is holding Space or E to speed up typewriter text.
		var char_delay = 0.01
		if Input.is_action_pressed("space") or Input.is_action_pressed("e"):
			char_delay = 0.001
		else:
			var c = body_text[i]
			if c in [".", "!", "?", ":"]:
				char_delay = 0.15
			elif c == ",":
				char_delay = 0.08
				
		# Re-verify before yielding to make sure we respond instantly if Space was pressed this frame.
		if not _is_typing or _fast_forward or current_session != _typing_session_id:
			break
			
		await get_tree().create_timer(char_delay).timeout
		
	# Only mark typing as finished and show indicators if this is the active session.
	if current_session == _typing_session_id:
		_is_typing = false
		_fast_forward = false
		active_text_label.visible_characters = -1 # Show all characters
		_show_continue_indicator()

# Callback when user presses an option button.
func select_option(index: int) -> void:
	if index >= 0 and index < active_options.size():
		var target_node = active_options[index]
		_play_node(target_node)

# Pulses the upside-down continue triangle indicator at the bottom-right of the active box.
func _show_continue_indicator() -> void:
	# RATIONALE: Bypassed speech bubbles mean we always render continuation triangle inside the bottom panel.
	var is_npc = false
	
	if active_options.is_empty():
		if is_npc:
			BubbleManager.show_continue_indicator(true)
		elif continue_indicator:
			continue_indicator.visible = true
			continue_indicator.modulate.a = 1.0
			# RATIONALE: Manage the tween safely to prevent overlapping pulse animations on the same label.
			if _continue_tween and _continue_tween.is_valid():
				_continue_tween.kill()
			_continue_tween = continue_indicator.create_tween().set_loops()
			_continue_tween.tween_property(continue_indicator, "modulate:a", 0.2, 0.4)
			_continue_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.4)


# Close dialogue and hide overlay.
func close_dialogue() -> void:
	print("[Dialogue] Sequence finished.")
	is_active = false
	_is_typing = false
	_fast_forward = false
	if continue_indicator:
		if _continue_tween and _continue_tween.is_valid():
			_continue_tween.kill()
		continue_indicator.visible = false
	
	# Hide NPC speech bubble when dialogue closes.
	BubbleManager.hide_bubble()
	
	# Smooth fade-out before hiding
	var tw = create_tween()
	tw.tween_property(dialogue_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	
	root_control.visible = false # Disable overlay so click interactions pass through
	dialogue_panel.visible = false
	
	for child in options_container.get_children():
		child.queue_free()
	active_options.clear()
	EventBus.dialogue_finished.emit()

# Show a floating sliding toast notification.
# RATIONALE: Renders non-intrusive system notifications at the top-center of the screen.
func show_toast(message: String) -> void:
	var display_text = message
	if display_text.begins_with("[System]:"):
		display_text = display_text.substr(9).strip_edges()
	elif display_text.begins_with("[System]"):
		display_text = display_text.substr(8).strip_edges()
		
	# Create a toast panel container.
	var toast_panel = Panel.new()
	toast_panel.custom_minimum_size = Vector2(400, 45)
	toast_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create StyleBox matching the current dream/reality aesthetic.
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.anti_aliasing = false
	
	if _is_dream_world:
		style.bg_color = Color(0.96, 0.95, 0.92, 0.9) # High contrast warm sketch paper
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.65, 0.25, 0.15, 0.4) # Brick red border
		style.shadow_color = Color(0, 0, 0, 0.08)
		style.shadow_size = 2
	else:
		style.bg_color = Color(0.08, 0.1, 0.16, 0.9) # Slate grey glass
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(1.0, 1.0, 1.0, 0.15) # Thin white border
		style.shadow_color = Color(0, 0, 0, 0.2)
		style.shadow_size = 3
		
	toast_panel.add_theme_stylebox_override("panel", style)
	_toast_container.add_child(toast_panel)
	
	# Margin container for text padding.
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	toast_panel.add_child(margin)
	
	# Label rendering.
	var label = Label.new()
	label.text = display_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	
	if _is_dream_world:
		label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
		
	margin.add_child(label)
	
	# Slide-in and fade Tween animations.
	toast_panel.modulate.a = 0.0
	toast_panel.scale = Vector2(0.9, 0.9)
	toast_panel.pivot_offset = Vector2(200, 22) # Center pivot for scaling
	
	var tw = toast_panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(toast_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(toast_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Keep the notification active on screen before fading out.
	await get_tree().create_timer(2.5).timeout
	
	var tw_out = toast_panel.create_tween()
	tw_out.set_parallel(true)
	tw_out.tween_property(toast_panel, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw_out.tween_property(toast_panel, "scale", Vector2(0.9, 0.9), 0.25).set_trans(Tween.TRANS_SINE)
	await tw_out.finished
	
	toast_panel.queue_free()
