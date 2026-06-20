extends CharacterBody2D
class_name ExplorationPlayer
# Controller for Hilbert Hickman's exploration movement in reality levels.
# Simplified to horizontal-only movement to represent side-scroller exploration.

# Reference to the AnimatedSprite2D node for updating visuals.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export_category("Movement")
# Speed increased to 220.0 for faster, more responsive exploration.
@export var speed: float = 220.0

# State variable to block player input when dialogue is active.
var input_locked: bool = false

func _ready() -> void:
	# Ensure the player starts with the idle animation.
	animated_sprite.play("Idle")
	
	# Optional spawn point placement.
	var spawn_point = get_parent().get_node_or_null("SpawnPoint2D")
	if spawn_point:
		global_position = spawn_point.global_position
		
	# Connect to DialogueSystem events to lock/unlock movement.
	EventBus.dialogue_started.connect(func(_node_id): input_locked = true)
	EventBus.dialogue_finished.connect(func(): input_locked = false)
	
	# Connect to combat events to lock/unlock movement.
	EventBus.lock_player_ui.connect(func(): input_locked = true)
	EventBus.unlock_player_ui.connect(func(): input_locked = false)

func _physics_process(delta: float) -> void:
	# If input is locked (dialogue active, etc.), stop player immediately.
	if input_locked:
		velocity.x = 0
		animated_sprite.play("Idle")
		move_and_slide()
		return

	# Retrieve horizontal movement input from actions 'a' (left) and 'd' (right).
	var direction := Input.get_axis("a", "d")
	
	if direction != 0:
		# Set horizontal velocity.
		velocity.x = direction * speed
		# Flip sprite based on direction.
		animated_sprite.flip_h = direction < 0
		# Play walk/run animation.
		animated_sprite.play("Run")
	else:
		# Smooth deceleration to simulate dragging feet.
		velocity.x = move_toward(velocity.x, 0, speed * delta * 8.0)
		animated_sprite.play("Idle")
		
	# Side-scrolling horizontal constraint (vertical velocity is zero).
	velocity.y = 0

	move_and_slide()
