extends Area2D
class_name Interactable
# A reusable component that allows character bodies (players) to interact with world entities.
# Utilizes Area2D collision shapes to detect proximity and listen for input.

# Unique identifier for the interactable object.
@export var interaction_id: String = ""

# Dialogue / prompt to display when the player is near.
@export var prompt_message: String = "Press E to interact"

# Signal emitted when interaction is successfully triggered.
signal interacted(id: String)

# Tracks whether the player is currently inside the Area2D collision zone.
var is_player_near: bool = false

# Programmatic UI prompt label.
var prompt_label: Label

# Accumulate elapsed time for the vertical bobbing animation.
var _time: float = 0.0

func _ready() -> void:
	# Create and configure visual prompt label.
	prompt_label = Label.new()
	prompt_label.text = prompt_message
	prompt_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Position above the interactable object.
	prompt_label.position = Vector2(-100, -95)
	prompt_label.custom_minimum_size = Vector2(200, 30)
	
	# RATIONALE: Apply consistent glossy-neutral styling.
	# White text with a strong dark shadow reads clearly over both light (dream) and dark (reality) backgrounds.
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.add_theme_constant_override("shadow_outline_size", 2)
	
	add_child(prompt_label)
	
	# Connect local Area2D signals to handle proximity detection.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Gently bob the prompt label vertically when the player is nearby to draw visual attention.
	if is_player_near and prompt_label.visible:
		_time += delta
		prompt_label.position.y = -95.0 + sin(_time * 4.0) * 4.0

func _input(event: InputEvent) -> void:
	# Check if player is near and presses the mapped interaction key 'e'.
	if is_player_near and event.is_action_pressed("e"):
		# Print to console for verification.
		print("[Interactable] Player triggered interaction: ", interaction_id)
		
		# Emit the interaction signal with this object's specific identifier.
		interacted.emit(interaction_id)
		# Emit globally on EventBus so other managers can capture it.
		EventBus.player_interacted.emit(interaction_id)
		# Consume the input event to prevent other elements from processing it.
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	# Verify that the colliding body is indeed the player.
	if body is ExplorationPlayer:
		is_player_near = true
		prompt_label.visible = true
		prompt_label.modulate.a = 0.0
		# Reset positions and run a smooth fade-in tween
		_time = 0.0
		prompt_label.position.y = -95.0
		var tw = create_tween()
		tw.tween_property(prompt_label, "modulate:a", 1.0, 0.15)

func _on_body_exited(body: Node2D) -> void:
	if body is ExplorationPlayer:
		is_player_near = false
		# Run a smooth fade-out tween to avoid harsh visual popping
		var tw = create_tween()
		tw.tween_property(prompt_label, "modulate:a", 0.0, 0.12)
		await tw.finished
		# Ensure player hasn't quickly re-entered the zone before hiding
		if not is_player_near:
			prompt_label.visible = false
