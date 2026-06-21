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

func _ready() -> void:
	position = Vector2.ZERO
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
	if not manager:
		return
		
	# 1. Ground Line (thin charcoal vector line separating hand area from battle area)
	draw_line(Vector2(0, 420), Vector2(1152, 420), Color(0.12, 0.12, 0.15, 0.25), 1.5)
	
	# 2. Notebook Page Border framing the drawing canvas
	draw_rect(Rect2(15, 15, 1122, 618), Color(0.12, 0.12, 0.15, 0.15), false, 1.5)
	
	# 3. Player Stats Frame and Health Line (X = 150 to 350, Y = 150 to 250)
	var player_x_start = 160
	var player_x_end = 340
	var player_y_bar = 240
	
	# Clean rectangular outline surrounding player statistics label
	draw_rect(Rect2(140, 130, 220, 120), Color(0.12, 0.12, 0.15, 0.15), false, 1.5)
	# Health fill background
	draw_line(Vector2(player_x_start, player_y_bar), Vector2(player_x_end, player_y_bar), Color(0.2, 0.2, 0.2, 0.1), 5.0)
	# Health actual fill line (smoothly lerping red vector)
	draw_line(Vector2(player_x_start, player_y_bar), Vector2(player_x_start + 180 * smooth_player_hp_ratio, player_y_bar), Color(0.8, 0.25, 0.25, 0.75), 5.0)
	
	# Muted block shield highlight outline (translucent silver)
	if manager.player_block > 0:
		draw_rect(Rect2(player_x_start - 4, player_y_bar - 6, 188, 12), Color(0.8, 0.8, 0.8, 0.45), false, 1.5)
		
	# 4. Enemy Stats Frames and Health Lines for all active wave enemies
	for idx in range(manager.active_enemies.size()):
		var enemy = manager.active_enemies[idx]
		if enemy["hp"] <= 0:
			continue
			
		var panel = enemy["panel"]
		if not panel:
			continue
			
		var panel_pos = panel.position
		var panel_size = panel.size
		var e_rect = Rect2(panel_pos, panel_size)
		
		# Highlight targeted enemy panel with sienna color and thicker outline border.
		var outline_color = Color(0.65, 0.25, 0.15, 0.45) if idx == manager.selected_enemy_idx else Color(0.12, 0.12, 0.15, 0.15)
		var border_w = 2.5 if idx == manager.selected_enemy_idx else 1.5
		draw_rect(e_rect, outline_color, false, border_w)
		
		var enemy_x_start = panel_pos.x + 20
		var enemy_x_end = panel_pos.x + 180
		var enemy_y_bar = panel_pos.y + 80
		
		# Health fill background
		draw_line(Vector2(enemy_x_start, enemy_y_bar), Vector2(enemy_x_end, enemy_y_bar), Color(0.2, 0.2, 0.2, 0.1), 5.0)
		
		# Health actual fill line (smoothly lerping red vector)
		var hp_ratio = enemy.get("smooth_hp_ratio", 1.0)
		draw_line(Vector2(enemy_x_start, enemy_y_bar), Vector2(enemy_x_start + 160.0 * hp_ratio, enemy_y_bar), Color(0.8, 0.25, 0.25, 0.75), 5.0)
		
		# Muted block shield outline (sienna shade)
		if enemy["block"] > 0:
			draw_rect(Rect2(enemy_x_start - 4, enemy_y_bar - 6, 168, 12), Color(0.65, 0.25, 0.15, 0.45), false, 1.5)
			
		# 5. Draw targeted crown/arrow indicator pointing down at the active targeted enemy sprite
		if idx == manager.selected_enemy_idx:
			var sprite = enemy["sprite"]
			if sprite and is_instance_valid(sprite):
				var s_pos = sprite.position
				var pt1 = Vector2(s_pos.x, s_pos.y - 120)
				var pt2 = Vector2(s_pos.x - 10, s_pos.y - 140)
				var pt3 = Vector2(s_pos.x + 10, s_pos.y - 140)
				# Draw clean sienna arrow outline
				draw_line(pt1, pt2, Color(0.65, 0.25, 0.15, 0.85), 2.0)
				draw_line(pt2, pt3, Color(0.65, 0.25, 0.15, 0.85), 2.0)
				draw_line(pt3, pt1, Color(0.65, 0.25, 0.15, 0.85), 2.0)
		
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

	# 8. Slay the Spire style Energy Orb (clean vector sketched)
	var orb_center = Vector2(122, 512)
	var orb_radius = 28.0
	
	var energy_color = Color(0.8, 0.4, 0.1, 0.65) # Muted energy sienna
	if manager.player_energy == 0:
		energy_color = Color(0.5, 0.5, 0.5, 0.3) # Drained grey
	
	# Draw filled soft circle background
	draw_circle(orb_center, orb_radius, Color(energy_color.r, energy_color.g, energy_color.b, 0.1))
	draw_circle(orb_center, orb_radius * 0.8, Color(energy_color.r, energy_color.g, energy_color.b, 0.2))
	
	# Draw outer outline
	draw_circle(orb_center, orb_radius, Color(0.12, 0.12, 0.15, 0.25), false, 1.5)
	
	# Draw energy spirals/rays inside if energy > 0
	if manager.player_energy > 0:
		var time_scale = Time.get_ticks_msec() * 0.003
		for i in range(3):
			var angle_offset = i * (TAU / 3.0) + time_scale
			var start = orb_center + Vector2.from_angle(angle_offset) * 4.0
			var end = orb_center + Vector2.from_angle(angle_offset + 1.2) * (orb_radius * 0.7)
			draw_line(start, end, energy_color, 1.5)
