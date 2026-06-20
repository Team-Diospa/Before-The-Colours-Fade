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

# Tracks if dialogue is active.
var is_active: bool = false

# Current options mapped to their target nodes.
var active_options: Array = []

# RATIONALE: Keep track of printing state to prevent accidental dialogue skipping.
var _is_typing: bool = false
var _active_tween: Tween

func _ready() -> void:
	# Build dialogue overlay UI programmatically.
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 90 # Below scene transition layer
	add_child(canvas_layer)
	
	# Root control node covering full viewport.
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.visible = false
	canvas_layer.add_child(root_control)
	
	# Main dialog container panel - positioned below screen for slide-up entry.
	dialogue_panel = Panel.new()
	dialogue_panel.visible = false
	dialogue_panel.modulate.a = 0.0
	root_control.add_child(dialogue_panel)
	
	# RATIONALE: Panel anchored to the bottom. Starts below the viewport (offset_top = 0)
	# and animates upward to -185 pixels on entry. This produces a sheet slide-up effect.
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_right = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = 0.0
	dialogue_panel.offset_right = 0.0
	dialogue_panel.offset_bottom = 0.0
	dialogue_panel.offset_top = 0.0 # Starts fully off-screen below
	
	# Styled dark panel with stronger border and slight inner shadow.
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.06, 0.06, 0.09, 0.97)
	style_box.corner_radius_top_left = 16
	style_box.corner_radius_top_right = 16
	style_box.border_width_top = 1
	style_box.border_color = Color(0.18, 0.28, 0.45, 1.0)
	style_box.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style_box.shadow_size = 12
	style_box.shadow_offset = Vector2(0, -4)
	dialogue_panel.add_theme_stylebox_override("panel", style_box)
	
	# MarginContainer for internal padding.
	var margin_container = MarginContainer.new()
	margin_container.anchor_right = 1.0
	margin_container.anchor_bottom = 1.0
	margin_container.add_theme_constant_override("margin_left", 36)
	margin_container.add_theme_constant_override("margin_right", 36)
	margin_container.add_theme_constant_override("margin_top", 22)
	margin_container.add_theme_constant_override("margin_bottom", 22)
	dialogue_panel.add_child(margin_container)
	
	# Horizontal split: text on the left, options on the right.
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 24)
	margin_container.add_child(h_box)
	
	# Left side: speaker badge and dialogue text.
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 8)
	h_box.add_child(text_vbox)
	
	# Speaker name pill - styled as a small badge above the text.
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 12)
	speaker_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 1.0))
	speaker_label.text = ""
	speaker_label.visible = false
	# Pill background styling.
	var speaker_style = StyleBoxFlat.new()
	speaker_style.bg_color = Color(0.12, 0.2, 0.35, 0.85)
	speaker_style.corner_radius_top_left = 4
	speaker_style.corner_radius_top_right = 4
	speaker_style.corner_radius_bottom_left = 4
	speaker_style.corner_radius_bottom_right = 4
	speaker_style.content_margin_left = 10
	speaker_style.content_margin_right = 10
	speaker_style.content_margin_top = 3
	speaker_style.content_margin_bottom = 3
	speaker_label.add_theme_stylebox_override("normal", speaker_style)
	text_vbox.add_child(speaker_label)
	
	# Dialogue body text.
	text_label = Label.new()
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 17)
	text_label.add_theme_constant_override("line_spacing", 6)
	text_vbox.add_child(text_label)
	
	# Advance hint label.
	var hint_label = Label.new()
	hint_label.text = "[ E / Space to advance ]"
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.25))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text_vbox.add_child(hint_label)
	
	# Right side: vertically stacked option buttons.
	options_container = VBoxContainer.new()
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_container.add_theme_constant_override("separation", 8)
	options_container.custom_minimum_size.x = 200
	h_box.add_child(options_container)
	
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
	root_control.visible = true
	dialogue_panel.visible = true
	
	# RATIONALE: Slide-up entry animation. Panel starts at offset_top = 0 (fully hidden below
	# the screen edge) and tweens to -185 while simultaneously fading in. This is more dynamic
	# than a simple fade and feels premium without being distracting.
	dialogue_panel.offset_top = 0.0
	dialogue_panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_panel, "offset_top", -185.0, 0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(dialogue_panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	
	EventBus.dialogue_started.emit(start_node)
	_play_node(start_node)

# Helper to play a specific node.
func _play_node(node_id: String) -> void:
	current_node_id = node_id
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
	
	# System notifications formatting
	if speaker_label.text == "[System]":
		text_label.modulate = Color(0.8, 0.7, 0.4, 1.0) # Muted gold
		speaker_label.modulate = Color(0.8, 0.7, 0.4, 1.0)
	else:
		text_label.modulate = Color(1.0, 1.0, 1.0, 1.0) # White
		speaker_label.modulate = Color(0.4, 0.7, 1.0, 1.0) # Sky blue highlight
	
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
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.custom_minimum_size = Vector2(0, 44)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# RATIONALE: Card-style button with a left accent border to create visual identity.
			# Dark background with a glowing blue border on hover signals interactability clearly.
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = Color(0.08, 0.1, 0.16, 0.85)
			style_normal.corner_radius_top_left = 8
			style_normal.corner_radius_top_right = 8
			style_normal.corner_radius_bottom_left = 8
			style_normal.corner_radius_bottom_right = 8
			style_normal.border_width_left = 3
			style_normal.border_color = Color(0.25, 0.4, 0.7, 0.6)
			style_normal.content_margin_left = 14
			style_normal.content_margin_right = 14
			style_normal.content_margin_top = 8
			style_normal.content_margin_bottom = 8
			
			var style_hover = style_normal.duplicate()
			style_hover.bg_color = Color(0.14, 0.2, 0.36, 0.95)
			style_hover.border_color = Color(0.5, 0.75, 1.0, 1.0)
			style_hover.border_width_left = 4
			
			var style_pressed = style_hover.duplicate()
			style_pressed.bg_color = Color(0.1, 0.16, 0.28, 1.0)
			
			btn.add_theme_stylebox_override("normal", style_normal)
			btn.add_theme_stylebox_override("hover", style_hover)
			btn.add_theme_stylebox_override("pressed", style_pressed)
			btn.add_theme_font_size_override("font_size", 15)
			btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			
			# Scale + translate on hover for tactile feel.
			btn.pivot_offset = Vector2(0, 22)
			btn.mouse_entered.connect(func():
				var tw = btn.create_tween().set_parallel(true)
				tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12).set_trans(Tween.TRANS_SINE)
			)
			btn.mouse_exited.connect(func():
				var tw = btn.create_tween().set_parallel(true)
				tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
			)
			
			# Stagger button entrance animations.
			btn.modulate.a = 0.0
			var entry_tw = btn.create_tween()
			entry_tw.tween_property(btn, "modulate:a", 1.0, 0.15).set_delay(0.05 * i)
			
			btn.pressed.connect(func(): EventBus.dialogue_option_selected.emit(i))
			options_container.add_child(btn)
			active_options.append(opt.get("next", ""))
			
	EventBus.dialogue_text_updated.emit(raw_text, active_options)
	
	# RATIONALE: Dynamic typewriter pacing using coroutine.
	# Pauses longer on commas and periods to simulate natural breathing/thought.
	# 0.012s base delay is roughly twice as fast as the old 0.02 default.
	_is_typing = true
	text_label.visible_characters = 0
	
	for i in range(body_text.length()):
		if not _is_typing:
			break # User skipped animation
		text_label.visible_characters = i + 1
		
		var char_delay = 0.012
		var c = body_text[i]
		if c in [".", "!", "?"]:
			char_delay = 0.18
		elif c == "," or c == ":":
			char_delay = 0.08
			
		await get_tree().create_timer(char_delay).timeout
		
	if _is_typing:
		_is_typing = false

# Callback when user presses an option button.
func select_option(index: int) -> void:
	if index >= 0 and index < active_options.size():
		var target_node = active_options[index]
		_play_node(target_node)

# Close dialogue and hide overlay.
func close_dialogue() -> void:
	print("[Dialogue] Sequence finished.")
	is_active = false
	_is_typing = false
	
	# Slide-down + fade-out to mirror the slide-up entrance.
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_panel, "offset_top", 0.0, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tw.tween_property(dialogue_panel, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	await tw.finished
	
	root_control.visible = false # Disable overlay so click interactions pass through
	dialogue_panel.visible = false
	
	for child in options_container.get_children():
		child.queue_free()
	active_options.clear()
	EventBus.dialogue_finished.emit()
