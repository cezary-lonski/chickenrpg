class_name PvpBarrier
extends Node2D
## Krąg antypotworowy: przez `duration` sekund potwory nie mogą wejść do środka.
## Gracze mogą przechodzić swobodnie.

var radius := 130.0
var duration := 30.0
var col := Color(0.5, 0.95, 0.95)
var _t := 0.0

func _ready() -> void:
	z_index = 30

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - global_position
		var d := to_e.length()
		if d < radius and d > 0.001:
			# wypchnij potwora na zewnątrz kręgu
			var push := to_e / d * (radius - d + 2.0)
			e.global_position += push
	queue_redraw()

func _draw() -> void:
	var a := 0.25 + 0.1 * sin(_t * 3.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(col.r, col.g, col.b, a + 0.4), 3.0, true)
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, 0.08))
