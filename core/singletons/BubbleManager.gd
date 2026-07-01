extends Node
# Autoload singleton for NPC speech bubbles.
# Rendered just ABOVE the bottom dialogue panel.
# NPC lines (Landlady, n.n., Peer 1, Peer 2, Professor) appear here.
# Hilbert's internal monologue and narration stay in the bottom panel.
# RATIONALE: Two visual channels = two psychological registers.
# "Someone is speaking at me" must feel different from "I am thinking."

const NPC_SPEAKERS: Array = ["Landlady", "n.n.", "Peer 1", "Peer 2", "Professor", "???", "Peer A", "Peer B"]

# Portrait color per NPC (the colored silhouette block on the left of the bubble).
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

# The portrait width determines how far right the text box starts.
const PORTRAIT_W: float = 80.0
const PANEL_H: float = 110.0
# Width of the bubble panel (matches dialogue panel width).
const PANEL_W: float = 700.0

var _canvas_layer: CanvasLayer
var _root: Control           # Anchor container for the whole bubble
var _portrait_panel: Panel   # Left NPC portrait box
var _portrait_bg: ColorRect  # Background fill behind the silhouette
var _portrait_head: ColorRect
var _portrait_shoulders: ColorRect
var _portrait_texture: TextureRect  # Front-facing placeholder image for NPC portrait
var _name_label: Label       # Speaker name (inside portrait box)
var _text_panel: Panel       # Right text box
var _text_label: Label       # Dialogue text
var _continue_indicator: Label  # Upside-down triangle (same as dialogue panel)

var _is_showing: bool = false
var _pulse_tween: Tween       # Tween reference to manage indicator pulse safely

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_canvas_layer = CanvasLayer.new()
	# RATIONALE: Layer 89 = above gameplay (80), below DialogueSystem panel (90),
	# below PauseManager (95). This lets the bubble sit in front of the world but
	# behind the main dialogue bottom panel.
	_canvas_layer.layer = 89
	add_child(_canvas_layer)

	# Root anchor: positioned at screen center
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	_canvas_layer.add_child(_root)

	# -------------------------------------------------------
	# Shared StyleBoxFlat (no rounded corners, thin white border).
	# -------------------------------------------------------
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.07, 0.11, 0.88)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.13)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.anti_aliasing = false
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel_style.shadow_size = 3
	panel_style.shadow_offset = Vector2(2, 2)

	# -------------------------------------------------------
	# Portrait panel (left side of bubble).
	# Horizontally anchored to center; vertically positioned at top
	# to place it cleanly below the top HUD panels (offset_top = 110, offset_bottom = 220).
	# -------------------------------------------------------
	_portrait_panel = Panel.new()
	_portrait_panel.anchor_left   = 0.5
	_portrait_panel.anchor_right  = 0.5
	_portrait_panel.anchor_top    = 0.0
	_portrait_panel.anchor_bottom = 0.0
	_portrait_panel.offset_left   = -(PANEL_W / 2.0)
	_portrait_panel.offset_right  = -(PANEL_W / 2.0) + PORTRAIT_W
	_portrait_panel.offset_top    = 110.0
	_portrait_panel.offset_bottom = 220.0
	_portrait_panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(_portrait_panel)

	# Background fill color block.
	_portrait_bg = ColorRect.new()
	_portrait_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_bg.color = Color(0.35, 0.52, 0.68, 1.0)
	_portrait_panel.add_child(_portrait_bg)

	# Head silhouette (centered, upper 40% of portrait).
	_portrait_head = ColorRect.new()
	_portrait_head.anchor_left   = 0.25
	_portrait_head.anchor_right  = 0.75
	_portrait_head.anchor_top    = 0.10
	_portrait_head.anchor_bottom = 0.48
	_portrait_head.color = Color(0.85, 0.72, 0.60, 1.0)
	_portrait_panel.add_child(_portrait_head)

	# Shoulders silhouette (lower 35% of portrait).
	_portrait_shoulders = ColorRect.new()
	_portrait_shoulders.anchor_left   = 0.10
	_portrait_shoulders.anchor_right  = 0.90
	_portrait_shoulders.anchor_top    = 0.55
	_portrait_shoulders.anchor_bottom = 1.00
	_portrait_shoulders.color = Color(0.55, 0.45, 0.38, 1.0)
	_portrait_panel.add_child(_portrait_shoulders)

	# Front-facing placeholder portrait image.
	_portrait_texture = TextureRect.new()
	_portrait_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_texture.visible = false
	_portrait_panel.add_child(_portrait_texture)

	# Load the placeholder texture if present in Assets.
	var placeholder_tex = load("res://Assets/Sprites/npc.png")
	if placeholder_tex:
		_portrait_texture.texture = placeholder_tex

	# Speaker name label at the very bottom of the portrait block.
	_name_label = Label.new()
	_name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_name_label.offset_top = -22
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 9)
	_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.add_theme_constant_override("shadow_outline_size", 1)
	_portrait_panel.add_child(_name_label)

	# -------------------------------------------------------
	# Text panel (right side of bubble).
	# Horizontally anchored to center; vertically positioned at top to align with portrait.
	# -------------------------------------------------------
	_text_panel = Panel.new()
	_text_panel.anchor_left   = 0.5
	_text_panel.anchor_right  = 0.5
	_text_panel.anchor_top    = 0.0
	_text_panel.anchor_bottom = 0.0
	_text_panel.offset_left   = -(PANEL_W / 2.0) + PORTRAIT_W + 4.0  # 4px gap between portrait and text
	_text_panel.offset_right  = (PANEL_W / 2.0)
	_text_panel.offset_top    = 110.0
	_text_panel.offset_bottom = 220.0
	_text_panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(_text_panel)

	# Margin container for text.
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 30) # Extra room for continue indicator
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_text_panel.add_child(margin)

	_text_label = Label.new()
	_text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 14)
	_text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	_text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_text_label.add_theme_constant_override("shadow_offset_x", 1)
	_text_label.add_theme_constant_override("shadow_offset_y", 1)
	margin.add_child(_text_label)

	# Continue indicator: upside-down triangle, bottom-right of text panel.
	_continue_indicator = Label.new()
	_continue_indicator.text = "▼"
	_continue_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_continue_indicator.offset_left = -28
	_continue_indicator.offset_top  = -26
	_continue_indicator.offset_right  = 0
	_continue_indicator.offset_bottom = 0
	_continue_indicator.add_theme_font_size_override("font_size", 12)
	_continue_indicator.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	_continue_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_indicator.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_continue_indicator.visible = false
	_text_panel.add_child(_continue_indicator)

	# Start invisible.
	_root.modulate.a = 0.0

# Show the NPC speech bubble and configure the portrait display.
func show_bubble(speaker: String, text: String) -> void:
	_is_showing = true
	_name_label.text = speaker
	_text_label.text = text
	_continue_indicator.visible = false # Managed externally by DialogueSystem typing

	# RATIONALE: Retract the placeholder texture from the text bubble. We always use the
	# previous custom procedural colored skin/head/shoulders silhouette blocks.
	_portrait_texture.visible = false
	_portrait_bg.visible = true
	_portrait_head.visible = true
	_portrait_shoulders.visible = true
	
	# Set custom colors for procedural silhouette.
	var bg_col    = PORTRAIT_COLORS.get(speaker,      Color(0.25, 0.25, 0.3, 1.0))
	var skin_col  = PORTRAIT_SKIN_COLORS.get(speaker, Color(0.75, 0.65, 0.55, 1.0))
	var cloth_col = bg_col.darkened(0.25)
	
	_portrait_bg.color        = bg_col
	_portrait_head.color      = skin_col
	_portrait_shoulders.color = cloth_col

	_root.visible = true

	# Fade in panel.
	var tw = _root.create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)

	# Start continue indicator pulse animation loop.
	_pulse_indicator()

# Hide the speech bubble with fade-out.
func hide_bubble() -> void:
	if not _is_showing:
		return
	_is_showing = false
	_continue_indicator.visible = false
	var tw = _root.create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if not _is_showing: # Guard against rapid show/hide race
		_root.visible = false

# Controls the visibility of the continue indicator (upside-down triangle) inside the bubble.
func show_continue_indicator(show: bool) -> void:
	if _continue_indicator:
		_continue_indicator.visible = show
		if show:
			_continue_indicator.modulate.a = 1.0

# Returns the Text Label node to drive the typewriter animation externally.
func get_text_label() -> Label:
	return _text_label

# Pulse the continue indicator in a loop.
func _pulse_indicator() -> void:
	if not _continue_indicator:
		return
	# RATIONALE: Kill the existing pulse tween before creating a new one to prevent tween stacking.
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = _continue_indicator.create_tween().set_loops()
	_pulse_tween.tween_property(_continue_indicator, "modulate:a", 0.2, 0.45)
	_pulse_tween.tween_property(_continue_indicator, "modulate:a", 1.0, 0.45)

func is_npc_speaker(speaker: String) -> bool:
	return NPC_SPEAKERS.has(speaker)
