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

# Tracks if dialogue is active.
var is_active: bool = false

# Current options mapped to their target nodes.
var active_options: Array = []

# RATIONALE: Keep track of printing state to prevent accidental dialogue skipping.
var _is_typing: bool = false
var _active_tween: Tween

# Tracks whether the dialogue is currently drawn in the dream/combat world.
var _is_dream_world: bool = false

# Dynamically updates the dialogue styling depending on whether the scene is dream or reality.
# Ensures seamless visual transitions between the warm beige sketch and cold slate aesthetics.
func _update_ui_style() -> void:
	_is_dream_world = false
	if get_tree() and get_tree().current_scene:
		var path = get_tree().current_scene.scene_file_path
		if path != "" and ("combat" in path or "field" in path or "village" in path):
			_is_dream_world = true
			
	var style_box = StyleBoxFlat.new()
	style_box.corner_radius_top_left = 0
	style_box.corner_radius_top_right = 0
	style_box.corner_radius_bottom_left = 0
	style_box.corner_radius_bottom_right = 0
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.anti_aliasing = false
	
	if _is_dream_world:
		style_box.bg_color = Color(0.96, 0.95, 0.92, 0.65) # Warm beige translucent paper glass
		style_box.border_color = Color(0.12, 0.12, 0.15, 0.15) # Soft translucent charcoal border
		style_box.shadow_color = Color(0, 0, 0, 0.1) # Soft muted shadow
		style_box.shadow_size = 2
		style_box.shadow_offset = Vector2(2, 2)
		
		text_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
		speaker_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Brick red badge
		continue_indicator.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0))
	else:
		style_box.bg_color = Color(0.06, 0.08, 0.12, 0.5) # Dark slate translucent glass
		style_box.border_color = Color(1.0, 1.0, 1.0, 0.15) # Thin white glass shine border
		style_box.shadow_color = Color(0, 0, 0, 0.25) # Soft subtle shadow
		style_box.shadow_size = 4
		style_box.shadow_offset = Vector2(2, 2)
		
		text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		speaker_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 1.0)) # Sky blue badge
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
	var margin_container = MarginContainer.new()
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
	
	# Horizontal container to separate text and option buttons.
	var h_box = HBoxContainer.new()
	margin_container.add_child(h_box)
	
	# RATIONALE: Nesting labels inside a VBox container to show speaker badge above dialogue text.
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	h_box.add_child(text_vbox)
	
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
	h_box.add_child(options_container)
	
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

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Advance dialogue when E or Space is pressed, if there are no branching options.
	if (event.is_action_pressed("e") or event.is_action_pressed("space")):
		# RATIONALE: If dialogue is still drawing, first press stops typewriter animation.
		# A subsequent press is required to advance nodes, preventing skipping.
		if _is_typing:
			_is_typing = false # Will break the typing coroutine
			text_label.visible_characters = -1 # Show all text
			get_viewport().set_input_as_handled()
			return
			
		if active_options.is_empty():
			# Hide continuation indicator when advancing.
			continue_indicator.visible = false
			# Fetch next node from current node data.
			var node_data = dialogue_tree.get(current_node_id, {})
			if node_data.has("next") and node_data["next"] != "":
				_play_node(node_data["next"])
			else:
				# End of dialogue tree reached.
				close_dialogue()
			get_viewport().set_input_as_handled()

# Load and start a dialogue sequence from a Dictionary.
func start_dialogue(tree: Dictionary, start_node: String = "start") -> void:
	dialogue_tree = tree
	is_active = true
	root_control.visible = true # Enable full overlay control node
	dialogue_panel.visible = true
	
	# Dynamically update styling to adapt to the active world mode (dream vs. reality).
	_update_ui_style()
	
	# Smooth fade-in
	var tw = create_tween()
	tw.tween_property(dialogue_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	EventBus.dialogue_started.emit(start_node)
	_play_node(start_node)

# Helper to play a specific node.
func _play_node(node_id: String) -> void:
	current_node_id = node_id
	if continue_indicator:
		continue_indicator.visible = false
	if not dialogue_tree.has(node_id):
		close_dialogue()
		return
		
	var node_data = dialogue_tree[node_id]
	var raw_text = node_data.get("text", "")
	
	# RATIONALE: Prefer explicit "speaker" field in node data over the split heuristic.
	# Explicit field supports speaker names of any length and avoids false positives.
	# Falls back to the heuristic for backward compatibility with all existing dialogue trees.
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
	
	if speaker != "":
		if speaker.begins_with("[") and speaker.ends_with("]"):
			speaker_label.text = speaker
		else:
			speaker_label.text = "[" + speaker + "]"
	else:
		speaker_label.text = ""
		
	speaker_label.visible = speaker != ""
	text_label.text = body_text
	
	# Style-specific text modulations for high contrast and readability.
	if speaker_label.text == "[System]":
		if _is_dream_world:
			text_label.add_theme_color_override("font_color", Color(0.55, 0.4, 0.1, 1.0)) # Golden-brown system text in dream
			speaker_label.add_theme_color_override("font_color", Color(0.55, 0.4, 0.1, 1.0))
		else:
			text_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4, 1.0)) # Muted gold system text in reality
			speaker_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4, 1.0))
	else:
		if _is_dream_world:
			text_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.15, 1.0)) # Dark slate body in dream
			speaker_label.add_theme_color_override("font_color", Color(0.65, 0.25, 0.15, 1.0)) # Warm brick-red speaker in dream
		else:
			text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0)) # White body in reality
			speaker_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 1.0)) # Sky blue speaker in reality
	
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
				
				style_hover.bg_color = Color(0.14, 0.18, 0.26, 0.6)
				style_hover.border_color = Color(0.3, 0.6, 0.9, 0.5) # Soft ice blue outline
				style_hover.shadow_color = Color(0, 0, 0, 0.15)
				style_hover.shadow_size = 2
				style_hover.shadow_offset = Vector2(1, 1)
				
				style_pressed.bg_color = Color(0.05, 0.06, 0.08, 0.6)
				style_pressed.border_color = Color(1.0, 1.0, 1.0, 0.05)
				style_pressed.shadow_offset = Vector2(0, 0)
				
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
				btn.add_theme_color_override("font_hover_color", Color(0.4, 0.7, 1.0, 1.0))
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
	
	# Fastened dialogue typewriter pacing.
	_is_typing = true
	text_label.visible_characters = 0
	
	for i in range(body_text.length()):
		if not _is_typing:
			break # User skipped animation
		text_label.visible_characters = i + 1
		
		var char_delay = 0.01
		var c = body_text[i]
		if c in [".", "!", "?", ":"]:
			char_delay = 0.15
		elif c == ",":
			char_delay = 0.08
			
		await get_tree().create_timer(char_delay).timeout
		
	_is_typing = false
	_show_continue_indicator()

# Callback when user presses an option button.
func select_option(index: int) -> void:
	if index >= 0 and index < active_options.size():
		var target_node = active_options[index]
		_play_node(target_node)

# Pulses the upside-down continue triangle indicator at the bottom-right of the box.
func _show_continue_indicator() -> void:
	if active_options.is_empty() and continue_indicator:
		continue_indicator.visible = true
		continue_indicator.modulate.a = 1.0
		var tw = continue_indicator.create_tween().set_loops()
		tw.tween_property(continue_indicator, "modulate:a", 0.2, 0.4)
		tw.tween_property(continue_indicator, "modulate:a", 1.0, 0.4)

# Close dialogue and hide overlay.
func close_dialogue() -> void:
	print("[Dialogue] Sequence finished.")
	is_active = false
	_is_typing = false
	if continue_indicator:
		continue_indicator.visible = false
	
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
