extends Node2D

var sun_rotation: float = 0.0

func _process(delta: float) -> void:
	sun_rotation += 0.1 * delta
	queue_redraw()

func _draw() -> void:
	var charge = GlobalState.dimension_charge
	var eye_color = Color(0.12, 0.12, 0.15, 0.2) # Grey base
	if charge == 1:
		eye_color = Color(0.12, 0.12, 0.15, 0.4) # Muted graphite
	elif charge == 2:
		eye_color = Color(0.85, 0.65, 0.15, 0.5) # Ochre yellow
	elif charge >= 3:
		eye_color = Color(0.8, 0.35, 0.1, 0.7) # Glowing orange
		
	var eye_center = Vector2.ZERO # Controlled by node position
	
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
