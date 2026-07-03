extends CharacterBody2D
class_name ExplorationPlayer
# Controller for Hilbert Hickman's exploration movement in reality levels.
# Simplified to horizontal-only movement to represent side-scroller exploration.

# Reference to the AnimatedSprite2D node for updating visuals.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export_category("Movement")
# RATIONALE: Speed capped at 120.0 as per the pov_curation_guide.md.
# Hilbert's movement represents physical lethargy, depression, and dragging feet.
@export var speed: float = 120.0

# State variable to block player input when dialogue is active.
var input_locked: bool = false

# RATIONALE: The walk sheet faces left by default, while 3_4test (idle) faces right.
# We track last_facing_right to flip both correctly, and dynamically scale the sprite
# since 3_4test is 258px high (scaled by 0.5 = 129px) and walk frames are 128px high (scaled by 1.0 = 128px).
var last_facing_right: bool = true

func _ready() -> void:
	z_index = 1
	# SpriteFrames (Idle + Run animations) are baked into player.tscn.
	# Play the idle animation as the default starting state.
	animated_sprite.play("Idle")
	animated_sprite.scale = Vector2(1, 1)
	animated_sprite.position = Vector2.ZERO
	
	# Restore proper Camera2D limits matching the game viewport (1152x648)
	var cam = get_node_or_null("Camera2D")
	if cam:
		cam.limit_top = 0
		cam.limit_bottom = 648
	
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
		animated_sprite.scale = Vector2(1, 1)
		animated_sprite.flip_h = not last_facing_right
		move_and_slide()
		return

	# Retrieve horizontal movement input from actions 'a' (left) and 'd' (right).
	var direction := Input.get_axis("a", "d")
	
	if direction != 0:
		# Set horizontal velocity.
		velocity.x = direction * speed
		last_facing_right = (direction > 0)
		
		# RATIONALE: The walk sheet faces left. So we flip when moving right.
		animated_sprite.flip_h = last_facing_right
		animated_sprite.scale = Vector2(2, 2)
		animated_sprite.play("Run")
	else:
		# Smooth deceleration to simulate dragging feet.
		velocity.x = move_toward(velocity.x, 0, speed * delta * 8.0)
		
		# RATIONALE: Idle 3_4test faces right. So we flip when facing left.
		animated_sprite.flip_h = not last_facing_right
		animated_sprite.scale = Vector2(1, 1)
		animated_sprite.play("Idle")
		
	# Side-scrolling horizontal constraint (vertical velocity is zero).
	velocity.y = 0

	move_and_slide()
