extends Area2D
class_name Interactable
# A reusable component that handles exploration interactions using clean retro icons.
# Supports target cycling (Q/Tab) and direct mouse-click selection.

# Unique identifier for the interactable object.
@export var interaction_id: String = ""

# Dialogue / prompt description (used by callbacks).
@export var prompt_message: String = "Press E to interact"

# Signal emitted when interaction is successfully triggered.
signal interacted(id: String)

# Tracks whether the player is currently inside the Area2D collision zone.
var is_player_near: bool = false

# Class-level static tracking variables.
static var nearby_interactables: Array = []
static var active_player: Node2D = null
static var targeted_index: int = 0

func _ready() -> void:
	# Connect local Area2D signals to handle proximity detection.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Connect input event to capture direct mouse clicks.
	input_event.connect(_on_input_event)

func _process(_delta: float) -> void:
	# Redraw the custom vector indicators to reflect active target state.
	queue_redraw()

func _draw() -> void:
	if not is_player_near:
		return
		
	# Determine if this interactable is currently active.
	var is_targeted = (Interactable._get_targeted_item() == self)
	
	# Draw a clean, minimalist retro pixel-style indicator circle.
	var center = Vector2(0, -90)
	var radius = 11.0
	
	# Targeted item glows warm sienna/orange; inactive items are faint grey.
	var col = Color(0.8, 0.4, 0.1, 0.8) if is_targeted else Color(0.5, 0.5, 0.5, 0.3)
	
	# Outer border ring.
	draw_circle(center, radius, col)
	# Inner dark cutout.
	draw_circle(center, radius - 1.5, Color(0.08, 0.08, 0.1, col.a))
	
	# Render the action icon shape inside the circle.
	if interaction_id in ["bed", "desk", "window", "papers", "blackboard"]:
		# Magnifying Glass symbol for inspection actions.
		draw_arc(center + Vector2(-2, -2), 3.0, 0, TAU, 8, col, 1.2)
		draw_line(center + Vector2(0, 0), center + Vector2(4, 4), col, 1.2)
	elif interaction_id in ["orang1", "orang2", "peer1", "peer2"]:
		# Speech Bubble symbol for conversations.
		draw_rect(Rect2(center.x - 4, center.y - 3, 8, 6), col, false, 1.2)
		draw_line(center + Vector2(-2, 3), center + Vector2(-4, 5), col, 1.2)
		draw_line(center + Vector2(-4, 5), center + Vector2(0, 3), col, 1.2)
	else:
		# Gear/Action symbol for usage interactions.
		draw_circle(center, 2.5, col)
		for i in range(4):
			var angle = i * (PI / 2.0)
			draw_line(center + Vector2.from_angle(angle) * 2.5, center + Vector2.from_angle(angle) * 5.0, col, 1.2)

	# RATIONALE: Draw the interaction prompt message above the targeted circle indicator
	# to give clear visual feedback on which object is selected and what key to press.
	# We draw a thick black outline first to ensure high readability against any background art.
	if is_targeted and prompt_message != "":
		var fallback_font = ThemeDB.get_fallback_font()
		var font_size = 11
		# Center the text horizontally by centering a 300px box at x = -150 relative to the interactable.
		var text_pos = Vector2(-150, -115)
		draw_string_outline(fallback_font, text_pos, prompt_message, HORIZONTAL_ALIGNMENT_CENTER, 300.0, font_size, 3, Color(0.0, 0.0, 0.0, 0.85))
		draw_string(fallback_font, text_pos, prompt_message, HORIZONTAL_ALIGNMENT_CENTER, 300.0, font_size, Color(0.95, 0.95, 1.0, 1.0))

func _input(event: InputEvent) -> void:
	if not is_player_near:
		return
		
	# Cycle between nearby interactable objects using Q, W, or S keys.
	if event is InputEventKey and event.pressed and (event.keycode == KEY_Q or event.keycode == KEY_W or event.keycode == KEY_S):
		if Interactable.nearby_interactables.size() > 1:
			Interactable.targeted_index = (Interactable.targeted_index + 1) % Interactable.nearby_interactables.size()
			get_viewport().set_input_as_handled()
			
	# Interact with the currently active target when E is pressed.
	if event.is_action_pressed("e") and not DialogueSystem.is_active:
		if Interactable._get_targeted_item() == self:
			_trigger_interaction()
			get_viewport().set_input_as_handled()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_player_near:
		return
		
	# Direct left-click on the object immediately selects and activates it.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx = Interactable.nearby_interactables.find(self)
		if idx != -1:
			Interactable.targeted_index = idx
		
		if not DialogueSystem.is_active:
			_trigger_interaction()
			get_viewport().set_input_as_handled()

func _trigger_interaction() -> void:
	print("[Interactable] Triggering interaction: ", interaction_id)
	interacted.emit(interaction_id)
	EventBus.player_interacted.emit(interaction_id)

func _on_body_entered(body: Node2D) -> void:
	if body is ExplorationPlayer:
		is_player_near = true
		Interactable.active_player = body
		if not Interactable.nearby_interactables.has(self):
			Interactable.nearby_interactables.append(self)
			# Sort array from left to right for intuitive cycling.
			Interactable.nearby_interactables.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
			Interactable.targeted_index = clamp(Interactable.targeted_index, 0, Interactable.nearby_interactables.size() - 1)
		queue_redraw()

func _on_body_exited(body: Node2D) -> void:
	if body is ExplorationPlayer:
		is_player_near = false
		Interactable.nearby_interactables.erase(self)
		Interactable.targeted_index = clamp(Interactable.targeted_index, 0, max(0, Interactable.nearby_interactables.size() - 1))
		queue_redraw()

static func _get_targeted_item() -> Interactable:
	if nearby_interactables.is_empty():
		return null
	targeted_index = clamp(targeted_index, 0, nearby_interactables.size() - 1)
	return nearby_interactables[targeted_index]
