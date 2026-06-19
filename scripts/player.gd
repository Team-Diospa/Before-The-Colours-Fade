extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export_category("Movement")
@export var speed: float = 300.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0
@export var gravity: float = 1500.0

@export_category("Abilities")
@export var jump_strength: float = -600.0 # Biasanya -600 sudah cukup tinggi, sesuaikan lagi nanti
@export var max_jump: int = 2
@export var dash_strength: float = 1000.0
@export var dash_cooldown: float = 3.0
@export var crouch_height: float = 50.0

@export_category("Healing")
@export var time_to_heal: float = 5.0

# State variables
var current_jump: int = 0
var idle_time: float = 0.0
var direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var is_crouching: bool = false

var _stand_height: float
var _stand_shape_pos: Vector2

func _ready() -> void:
	animated_sprite.play("Idle")
	var spawn_point = get_parent().get_node_or_null("SpawnPoint2D")
	if spawn_point:
		global_position = spawn_point.global_position
	_stand_height = (collision_shape.shape as CapsuleShape2D).height
	_stand_shape_pos = collision_shape.position

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_crouch()
	handle_jump()
	handle_dash()
	handle_horizontal_movement(delta)

	move_and_slide()

	# Update visual seperti animasi dan flip sprite dilakukan setelah move_and_slide
	update_animations(delta)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		current_jump = 0

func handle_crouch() -> void:
	if Input.is_action_pressed("s"):
		if is_on_floor() and not is_crouching:
			is_crouching = true
			var shape := collision_shape.shape as CapsuleShape2D
			var drop := (_stand_height - crouch_height) / 2.0
			shape.height = crouch_height
			collision_shape.position.y = _stand_shape_pos.y + drop
	elif is_crouching:
		is_crouching = false
		(collision_shape.shape as CapsuleShape2D).height = _stand_height
		collision_shape.position = _stand_shape_pos

func handle_jump() -> void:
	if is_crouching:
		return
	if Input.is_action_just_pressed("space") and current_jump < max_jump:
		velocity.y = jump_strength
		current_jump += 1
		is_dashing = false # Membatalkan dash jika lompat

func handle_dash() -> void:
	# Dash mekanik (hanya bisa di lantai sesuai kode awalmu)
	if is_crouching:
		return
	if Input.is_action_just_pressed("e") and is_on_floor() and direction.x != 0:
		velocity.x = sign(direction.x) * dash_strength
		is_dashing = true

func handle_horizontal_movement(delta: float) -> void:
	# Ambil input horizontal
	direction.x = Input.get_axis("a", "d")

	var current_speed := speed * (0.5 if is_crouching else 1.0)

	# Jika sedang dash, biarkan velocity.x perlahan melambat ke speed normal memakai friction
	if is_dashing:
		if abs(velocity.x) <= current_speed:
			is_dashing = false # Selesai dash jika kecepatan sudah kembali normal
		else:
			velocity.x = move_toward(velocity.x, sign(velocity.x) * current_speed, friction * delta)
	else:
		# Pergerakan normal
		if direction.x != 0:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

func update_animations(delta: float) -> void:
	# 1. Flip Sprite Direction
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

	# 2. Logika Animasi (Prioritas: Udara -> Tanah)
	if not is_on_floor():
		# Reset idle time karena sedang bergerak/berada di udara
		idle_time = 0.0

		if velocity.y < 0:
			animated_sprite.play("Jump")
		else:
			animated_sprite.play("Fall")
	elif is_crouching:
		idle_time = 0.0
		animated_sprite.play("Crouch")
	else:
		# Jika berada di lantai
		if velocity.x != 0:
			idle_time = 0.0
			animated_sprite.play("Run")
		else:
			# Hitung waktu diam untuk mekanik healing/regen kamu yang dulu
			# Karena animasi "Regen" sudah dihapus, bagian ini disiapkan untuk logic heal ke depannya
			idle_time += delta
			animated_sprite.play("Idle")

			if idle_time >= time_to_heal:
				# TODO: Masukkan fungsi atau logic nambah HP di sini nanti
				pass
