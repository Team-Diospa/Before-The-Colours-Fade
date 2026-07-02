extends Node2D
# RATIONALE: Renders clean vector sketch assets programmatically in the combat screen.
# Uses crisp, thin, single-stroke lines for a high-quality technical blueprint feel.
# Incorporates smooth health bar drainage interpolation and slow ambient rotations.

# Reference to the CombatManager parent to read HP, energy, block, and charge values.
@onready var manager = get_parent()

# Animation tracking variables.
var smooth_player_hp_ratio: float = 1.0
var gear_rotation: float = 0.0
var sun_rotation: float = 0.0

# Preload custom texture assets for progress bars and energy widgets
# RATIONALE: Assets live under res://Assets/UI/, not res://Assets/Combat/UI/.
# Each texture is guarded with file_exists to prevent crashes if assets are missing.
var bar_frame_tex: Texture2D = null
var green_fill_tex: Texture2D = null
var blue_fill_tex: Texture2D = null
var red_fill_tex: Texture2D = null
var energy_orb_tex: Texture2D = null
var targeting_arrow_tex: Texture2D = null

func _ready() -> void:
	position = Vector2.ZERO
	
	# Load textures from correct paths with file_exists guards
	if FileAccess.file_exists("res://Assets/UI/prog_bar_frame_16x6.png"):
		bar_frame_tex = load("res://Assets/UI/prog_bar_frame_16x6.png")
	if FileAccess.file_exists("res://Assets/UI/green_fill_8x4_full.png"):
		green_fill_tex = load("res://Assets/UI/green_fill_8x4_full.png")
	if FileAccess.file_exists("res://Assets/UI/blue_full_8x4_full.png"):
		blue_fill_tex = load("res://Assets/UI/blue_full_8x4_full.png")
	if FileAccess.file_exists("res://Assets/UI/red_fill_8x4_full.png"):
		red_fill_tex = load("res://Assets/UI/red_fill_8x4_full.png")
	if FileAccess.file_exists("res://Assets/UI/energy_orb_48x48.png"):
		energy_orb_tex = load("res://Assets/UI/energy_orb_48x48.png")
	if FileAccess.file_exists("res://Assets/UI/targeting_arrow_32x32.png"):
		targeting_arrow_tex = load("res://Assets/UI/targeting_arrow_32x32.png")
	
	if manager:
		smooth_player_hp_ratio = float(manager.player_hp) / float(manager.player_max_hp)
		for enemy in manager.active_enemies:
			enemy["smooth_hp_ratio"] = float(enemy["hp"]) / float(enemy["max_hp"])
	queue_redraw()

func _process(delta: float) -> void:
	if manager:
		# Smooth HP ratio drainage (lerp over time)
		var target_p = float(manager.player_hp) / float(manager.player_max_hp)
		smooth_player_hp_ratio = lerp(smooth_player_hp_ratio, target_p, 8.0 * delta)
		
		for enemy in manager.active_enemies:
			var target_e = float(enemy["hp"]) / float(enemy["max_hp"])
			enemy["smooth_hp_ratio"] = lerp(enemy.get("smooth_hp_ratio", 1.0), target_e, 8.0 * delta)
		
		# Slowly accumulate rotations for sun rays and gear
		gear_rotation += 0.5 * delta
		sun_rotation += 0.1 * delta
		
		queue_redraw()

func _draw() -> void:
	if not manager: return
	
	# 1. Action Panel Notebook Framing (if we still want it, but action panel is transparent now)
	# We can just keep the page border.
	draw_rect(Rect2(15, 15, 1122, 618), Color(0.12, 0.12, 0.15, 0.15), false, 1.5)
	
	for idx in range(manager.active_enemies.size()):
		var enemy = manager.active_enemies[idx]
		if enemy["hp"] <= 0: continue
		
	# Removed static targeting arrow per user request
	# 5. Sun (top-right, X = 1050, Y = 80)
	var sun_color = Color(0.9, 0.75, 0.15, 1.0) # Warm sienna/yellow
	var sun_center = Vector2(1050, 80)
	# Soft background fill
	draw_circle(sun_center, 25.0, Color(sun_color.r, sun_color.g, sun_color.b, 0.08))
	# Clean outline
	draw_circle(sun_center, 26.0, Color(sun_color.r, sun_color.g, sun_color.b, 0.3), false, 1.5)
	# Rotating sunbeams
	for i in range(12):
		var angle = i * (TAU / 12.0) + sun_rotation
		var start = sun_center + Vector2.from_angle(angle) * 32.0
		var end = sun_center + Vector2.from_angle(angle) * 44.0
		draw_line(start, end, Color(sun_color.r, sun_color.g, sun_color.b, 0.3), 1.5)
		
	# 6. Settings Gear (top-left, X = 80, Y = 80)
	var gear_color = Color(0.12, 0.12, 0.15, 1.0)
	var gear_center = Vector2(80, 80)
	# Clean outer wheel and axle cutout
	draw_circle(gear_center, 12.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), false, 1.5)
	draw_circle(gear_center, 4.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), false, 1.5)
	# Rotating gear teeth
	for i in range(8):
		var angle = i * (TAU / 8.0) + gear_rotation
		var start = gear_center + Vector2.from_angle(angle) * 12.0
		var end = gear_center + Vector2.from_angle(angle) * 17.0
		draw_line(start, end, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), 2.0)
		
	# 7. Dimensional Shift Eye (top-center, X = 576, Y = 80)
	var eye_center = Vector2(576, 80)
	var charge = GlobalState.dimension_charge
	var eye_color = Color(0.12, 0.12, 0.15, 0.2) # Grey base
	if charge == 1:
		eye_color = Color(0.12, 0.12, 0.15, 0.4) # Muted graphite
	elif charge == 2:
		eye_color = Color(0.85, 0.65, 0.15, 0.5) # Ochre yellow
	elif charge >= 3:
		eye_color = Color(0.8, 0.35, 0.1, 0.7) # Glowing orange
		
	# Draw eye arches using clean vector segments
	var points_top = []
	var points_bottom = []
	for i in range(21):
		var t = float(i) / 20.0
		var x = lerp(eye_center.x - 45.0, eye_center.x + 45.0, t)
		var y_offset = sin(t * PI) * 22.0
		points_top.append(Vector2(x, eye_center.y - y_offset))
		points_bottom.append(Vector2(x, eye_center.y + y_offset))
		
	for i in range(20):
		draw_line(points_top[i], points_top[i+1], eye_color, 1.5)
		draw_line(points_bottom[i], points_bottom[i+1], eye_color, 1.5)
		
	# Pupil: clean circle and highlight
	draw_circle(eye_center, 10.0, eye_color, false, 1.5)
	draw_circle(eye_center + Vector2(3, -3), 3.0, Color(1.0, 1.0, 1.0, 0.5))
	
	# If charge is 3, draw radiant rays from the eye (glowing sun-eye)
	if charge >= 3:
		var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
		var ray_color = Color(0.8, 0.35, 0.1, 0.3 + 0.3 * pulse)
		for i in range(12):
			var angle = i * (TAU / 12.0) - sun_rotation # Rotate opposite to sun
			var start = eye_center + Vector2.from_angle(angle) * 35.0
			var end = eye_center + Vector2.from_angle(angle) * (48.0 + 10.0 * pulse)
			draw_line(start, end, ray_color, 1.5)

	# 8. Draw energy orb texture centered at X = 122, Y = 502 (risen by half the distance of the main orb)
	# RATIONALE: Real image is 161x158 pixels. Filename label says 48x48. We render at 48x48.
	if energy_orb_tex:
		var dest_rect = Rect2(122 - 24, 502 - 24, 48, 48) # Risen half distance (Y=502)
		draw_texture_rect(energy_orb_tex, dest_rect, false)
	else:
		# Fallback to vector drawings if asset not loaded
		var orb_center = Vector2(122, 502) # Risen half distance
		var orb_radius = 28.0
		var energy_color = Color(0.8, 0.4, 0.1, 0.65)
		if manager.player_energy == 0:
			energy_color = Color(0.5, 0.5, 0.5, 0.3)
		draw_circle(orb_center, orb_radius, Color(energy_color.r, energy_color.g, energy_color.b, 0.1))
		draw_circle(orb_center, orb_radius * 0.8, Color(energy_color.r, energy_color.g, energy_color.b, 0.2))
		draw_circle(orb_center, orb_radius, Color(0.12, 0.12, 0.15, 0.25), false, 1.5)
		if manager.player_energy > 0:
			var time_scale = Time.get_ticks_msec() * 0.003
			for i in range(3):
				var angle_offset = i * (TAU / 3.0) + time_scale
				var start = orb_center + Vector2.from_angle(angle_offset) * 4.0
				var end = orb_center + Vector2.from_angle(angle_offset + 1.2) * (orb_radius * 0.7)
				draw_line(start, end, energy_color, 1.5)

