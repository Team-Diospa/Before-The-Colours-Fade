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
var text_label: Label
var options_container: VBoxContainer

# Tracks if dialogue is active.
var is_active: bool = false

# Current options mapped to their target nodes.
var active_options: Array = []

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
	root_control.add_child(dialogue_panel)
	
	# Position panel at the bottom of the screen.
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_right = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_top = -160.0
	dialogue_panel.offset_right = 0.0
	dialogue_panel.offset_bottom = 0.0
	dialogue_panel.offset_left = 0.0
	
	# Apply premium glassmorphism StyleBoxFlat.
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.1, 0.9) # Dark slate semi-transparent
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.border_width_top = 2
	style_box.border_color = Color(0.25, 0.35, 0.45, 0.8) # Premium highlight border
	dialogue_panel.add_theme_stylebox_override("panel", style_box)
	
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
	
	# Label to render the text.
	text_label = Label.new()
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Apply a clean font override size if needed.
	text_label.add_theme_font_size_override("font_size", 16)
	h_box.add_child(text_label)
	
	# VBoxContainer to render branch choice buttons.
	options_container = VBoxContainer.new()
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	options_container.custom_minimum_size.x = 220
	h_box.add_child(options_container)
	
	# Connect to EventBus signals.
	EventBus.dialogue_option_selected.connect(select_option)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Advance dialogue when E or Space is pressed, if there are no branching options.
	if (event.is_action_pressed("e") or event.is_action_pressed("space")):
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
	root_control.visible = true # Enable full overlay control node
	dialogue_panel.visible = true
	EventBus.dialogue_started.emit(start_node)
	_play_node(start_node)

# Helper to play a specific node.
func _play_node(node_id: String) -> void:
	current_node_id = node_id
	if not dialogue_tree.has(node_id):
		close_dialogue()
		return
		
	var node_data = dialogue_tree[node_id]
	var text_content = node_data.get("text", "")
	
	# Print to console for editor debugging.
	print("[Dialogue Node ID: ", node_id, "] ", text_content)
	
	# Update label text.
	text_label.text = text_content
	
	# Clear old buttons.
	for child in options_container.get_children():
		child.queue_free()
		
	active_options.clear()
	
	# Populate options if available.
	if node_data.has("options"):
		var options = node_data["options"]
		for i in range(options.size()):
			var opt = options[i]
			var btn = Button.new()
			btn.text = opt.get("text", "")
			btn.pressed.connect(func(): EventBus.dialogue_option_selected.emit(i))
			options_container.add_child(btn)
			active_options.append(opt.get("next", ""))
			
	EventBus.dialogue_text_updated.emit(text_content, active_options)

# Callback when user presses an option button.
func select_option(index: int) -> void:
	if index >= 0 and index < active_options.size():
		var target_node = active_options[index]
		_play_node(target_node)

# Close dialogue and hide overlay.
func close_dialogue() -> void:
	print("[Dialogue] Sequence finished.")
	is_active = false
	root_control.visible = false # Disable overlay so click interactions pass through
	dialogue_panel.visible = false
	for child in options_container.get_children():
		child.queue_free()
	active_options.clear()
	EventBus.dialogue_finished.emit()
