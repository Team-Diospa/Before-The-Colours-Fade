extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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

@export_category("Healing")
@export var time_to_heal: float = 5.0

# State variables
var current_jump: int = 0
var idle_time: float = 0.0
var direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false

func _ready() -> void:
	animated_sprite.play("Idle")
	var spawn_point = get_parent().get_node_or_null("SpawnPoint2D")
	if spawn_point:
		global_position = spawn_point.global_position

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
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

func handle_jump() -> void:
	if Input.is_action_just_pressed("space") and current_jump < max_jump:
		velocity.y = jump_strength
		current_jump += 1
		is_dashing = false # Membatalkan dash jika lompat

func handle_dash() -> void:
	# Dash mekanik (hanya bisa di lantai sesuai kode awalmu)
	if Input.is_action_just_pressed("e") and is_on_floor() and direction.x != 0:
		velocity.x = sign(direction.x) * dash_strength
		is_dashing = true

func handle_horizontal_movement(delta: float) -> void:
	# Ambil input horizontal
	direction.x = Input.get_axis("a", "d")
	
	# Jika sedang dash, biarkan velocity.x perlahan melambat ke speed normal memakai friction
	if is_dashing:
		if abs(velocity.x) <= speed:
			is_dashing = false # Selesai dash jika kecepatan sudah kembali normal
		else:
			velocity.x = move_toward(velocity.x, sign(velocity.x) * speed, friction * delta)
	else:
		# Pergerakan normal
		if direction.x != 0:
			velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
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
