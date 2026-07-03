extends Node2D

var sun_rotation: float = 0.0

func _process(delta: float) -> void:
	sun_rotation += 0.1 * delta
	queue_redraw()

func _draw() -> void:
	var sun_color = Color(0.9, 0.75, 0.15, 1.0) # Warm sienna/yellow
	var sun_center = Vector2.ZERO # Controlled by node position
	
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
