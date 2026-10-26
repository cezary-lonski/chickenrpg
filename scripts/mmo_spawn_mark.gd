extends Node2D
## Okrąg strefy bezpiecznej wokół punktu odrodzenia na serwerze.

func _draw() -> void:
	draw_circle(Vector2.ZERO, MmoServer.SAFE_RADIUS, Color(0.4, 0.8, 0.5, 0.07))
	draw_arc(Vector2.ZERO, MmoServer.SAFE_RADIUS, 0.0, TAU, 96, Color(0.5, 0.95, 0.6, 0.45), 3.0, true)
