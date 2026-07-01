extends Node2D
# RATIONALE: Renders the custom combat HP progress bars and energy widgets.
# Replaces procedural vector lines with the user's hand-drawn slice textures:
# prog_bar_frame_16x6.png, green_fill_8x4_full.png, red_fill_8x4_full.png,
# blue_full_8x4_full.png, and energy_orb_48x48.png.

# Reference to the CombatManager parent to read HP, energy, block, and charge values.
@onready var manager = get_parent()

# Animation tracking variables.
var smooth_player_hp_ratio: float = 1.0
var gear_rotation: float = 0.0
var sun_rotation: float = 0.0

# Texture assets loaded once on ready.
var hp_frame_tex: Texture2D
var hp_fill_green: Texture2D
var hp_fill_red: Texture2D
var hp_fill_blue: Texture2D
var energy_orb_tex: Texture2D

func _ready() -> void:
	position = Vector2.ZERO
	
	# Load custom UI textures.
	hp_frame_tex = load("res://Assets/UI/prog_bar_frame_16x6.png")
	hp_fill_green = load("res://Assets/UI/green_fill_8x4_full.png")
	hp_fill_red = load("res://Assets/UI/red_fill_8x4_full.png")
	hp_fill_blue = load("res://Assets/UI/blue_full_8x4_full.png")
	energy_orb_tex = load("res://Assets/UI/energy_orb_48x48.png")
	
	if manager:
		smooth_player_hp_ratio = float(manager.player_hp) / float(manager.player_max_hp)
		for enemy in manager.active_enemies:
			enemy["smooth_hp_ratio"] = float(enemy["hp"]) / float(enemy["max_hp"])
	queue_redraw()

func _process(delta: float) -> void:
	if manager:
		# Smooth HP ratio drainage (lerp over time for catchup feedback)
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
	
	# 3. Player HP Bar (draw inside player_stats box)
	# Position matches player panel offset (170, 430) with forced size (160, 50).
	var bar_w = 144.0
	var bar_h = 10.0
	var player_bar_x = 170.0 + 8.0
	var player_bar_y = 430.0 + 34.0
	
	# Draw frame container.
	if hp_frame_tex:
		draw_texture_rect(hp_frame_tex, Rect2(player_bar_x, player_bar_y, bar_w, bar_h), false)
		
		# Draw fills (inside borders). Fill width is bar_w - 4.
		var fill_max_w = bar_w - 4.0
		var fill_h = bar_h - 4.0
		var fill_x = player_bar_x + 2.0
		var fill_y = player_bar_y + 2.0
		
		# Red catchup HP lag.
		if hp_fill_red:
			draw_texture_rect(hp_fill_red, Rect2(fill_x, fill_y, fill_max_w * smooth_player_hp_ratio, fill_h), false)
			
		# Green actual HP.
		var actual_ratio = float(manager.player_hp) / float(manager.player_max_hp)
		if hp_fill_green:
			draw_texture_rect(hp_fill_green, Rect2(fill_x, fill_y, fill_max_w * actual_ratio, fill_h), false)
			
		# Blue shield capacity.
		if manager.player_block > 0 and hp_fill_blue:
			var block_ratio = float(manager.player_block) / float(manager.player_max_hp)
			draw_texture_rect(hp_fill_blue, Rect2(fill_x, fill_y, fill_max_w * min(1.0, block_ratio), fill_h), false)
			
	# 4. Enemy HP Bars (drawn inside duplicate enemy stats panels)
	for idx in range(manager.active_enemies.size()):
		var enemy = manager.active_enemies[idx]
		if enemy["hp"] <= 0:
			continue
			
		var panel = enemy["panel"]
		if not panel:
			continue
			
		var panel_pos = panel.position
		var enemy_bar_x = panel_pos.x + 8.0
		var enemy_bar_y = panel_pos.y + 34.0
		
		if hp_frame_tex:
			draw_texture_rect(hp_frame_tex, Rect2(enemy_bar_x, enemy_bar_y, bar_w, bar_h), false)
			
			var fill_max_w = bar_w - 4.0
			var fill_h = bar_h - 4.0
			var fill_x = enemy_bar_x + 2.0
			var fill_y = enemy_bar_y + 2.0
			
			# Red catchup HP lag.
			var smooth_e_ratio = enemy.get("smooth_hp_ratio", 1.0)
			if hp_fill_red:
				draw_texture_rect(hp_fill_red, Rect2(fill_x, fill_y, fill_max_w * smooth_e_ratio, fill_h), false)
				
			# Green actual HP.
			var actual_e_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
			if hp_fill_green:
				draw_texture_rect(hp_fill_green, Rect2(fill_x, fill_y, fill_max_w * actual_e_ratio, fill_h), false)
				
			# Blue shield capacity.
			if enemy["block"] > 0 and hp_fill_blue:
				var block_e_ratio = float(enemy["block"]) / float(enemy["max_hp"])
				draw_texture_rect(hp_fill_blue, Rect2(fill_x, fill_y, fill_max_w * min(1.0, block_e_ratio), fill_h), false)
				
		# 5. Draw targeted crown/arrow indicator pointing down at the active targeted enemy sprite.
		if idx == manager.selected_enemy_idx:
			var sprite = enemy["sprite"]
			if sprite and is_instance_valid(sprite):
				var s_pos = sprite.position
				var pt1 = Vector2(s_pos.x, s_pos.y - 120)
				var pt2 = Vector2(s_pos.x - 10, s_pos.y - 140)
				var pt3 = Vector2(s_pos.x + 10, s_pos.y - 140)
				# Draw sienna arrow outline.
				draw_line(pt1, pt2, Color(0.65, 0.25, 0.15, 0.85), 2.0)
				draw_line(pt2, pt3, Color(0.65, 0.25, 0.15, 0.85), 2.0)
				draw_line(pt3, pt1, Color(0.65, 0.25, 0.15, 0.85), 2.0)
				
	# 6. Sun (top-right, X = 1050, Y = 80)
	var sun_color = Color(0.9, 0.75, 0.15, 1.0) # Warm sienna/yellow
	var sun_center = Vector2(1050, 80)
	draw_circle(sun_center, 25.0, Color(sun_color.r, sun_color.g, sun_color.b, 0.08))
	draw_circle(sun_center, 26.0, Color(sun_color.r, sun_color.g, sun_color.b, 0.3), false, 1.5)
	
	# Rotating sunbeams.
	for i in range(12):
		var angle = i * (TAU / 12.0) + sun_rotation
		var start = sun_center + Vector2.from_angle(angle) * 32.0
		var end = sun_center + Vector2.from_angle(angle) * 44.0
		draw_line(start, end, Color(sun_color.r, sun_color.g, sun_color.b, 0.3), 1.5)
		
	# 7. Settings Gear (top-left, X = 80, Y = 80)
	var gear_color = Color(0.12, 0.12, 0.15, 1.0)
	var gear_center = Vector2(80, 80)
	draw_circle(gear_center, 12.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), false, 1.5)
	draw_circle(gear_center, 4.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), false, 1.5)
	
	# Rotating gear teeth.
	for i in range(8):
		var angle = i * (TAU / 8.0) + gear_rotation
		var start = gear_center + Vector2.from_angle(angle) * 12.0
		var end = gear_center + Vector2.from_angle(angle) * 17.0
		draw_line(start, end, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), 2.0)
		
	# 8. Dimensional Shift Eye (top-center, X = 576, Y = 80)
	var eye_center = Vector2(576, 80)
	var charge = GlobalState.dimension_charge
	var eye_color = Color(0.12, 0.12, 0.15, 0.2) # Grey base
	if charge == 1:
		eye_color = Color(0.12, 0.12, 0.15, 0.4) # Muted graphite
	elif charge == 2:
		eye_color = Color(0.85, 0.65, 0.15, 0.5) # Ochre yellow
	elif charge >= 3:
		eye_color = Color(0.8, 0.35, 0.1, 0.7) # Glowing orange
		
	# Draw eye arches.
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
		
	# Pupil: clean circle and highlight.
	draw_circle(eye_center, 10.0, eye_color, false, 1.5)
	draw_circle(eye_center + Vector2(3, -3), 3.0, Color(1.0, 1.0, 1.0, 0.5))
	
	# Radiant rays for charge 3.
	if charge >= 3:
		var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
		var ray_color = Color(0.8, 0.35, 0.1, 0.3 + 0.3 * pulse)
		for i in range(12):
			var angle = i * (TAU / 12.0) - sun_rotation
			var start = eye_center + Vector2.from_angle(angle) * 35.0
			var end = eye_center + Vector2.from_angle(angle) * (48.0 + 10.0 * pulse)
			draw_line(start, end, ray_color, 1.5)
			
	# 9. Draw Copper Energy Orb (forced to 48x48 centered at panel position (90, 480)).
	if energy_orb_tex:
		draw_texture_rect(energy_orb_tex, Rect2(90, 480, 48, 48), false)
