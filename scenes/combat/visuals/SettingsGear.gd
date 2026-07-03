extends Node2D

var gear_rotation: float = 0.0

func _process(delta: float) -> void:
	gear_rotation += 0.5 * delta
	queue_redraw()

func _draw() -> void:
	var gear_color = Color(0.12, 0.12, 0.15, 1.0)
	var gear_center = Vector2.ZERO # Draw at origin; node position controls placement
	
	# Clean outer wheel and axle cutout
	draw_circle(gear_center, 12.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), false, 1.5)
	draw_circle(gear_center, 4.0, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), false, 1.5)
	# Rotating gear teeth
	for i in range(8):
		var angle = i * (TAU / 8.0) + gear_rotation
		var start = gear_center + Vector2.from_angle(angle) * 12.0
		var end = gear_center + Vector2.from_angle(angle) * 17.0
		draw_line(start, end, Color(gear_color.r, gear_color.g, gear_color.b, 0.25), 2.0)
