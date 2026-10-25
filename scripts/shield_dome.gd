class_name ShieldDome
extends Node2D
## Obszarowa osłona Lady: chroni graczy przebywających w środku przez cały czas
## trwania. Rysowana jako pulsująca kopuła z runami.

var radius := 240.0
var duration := 6.0
var col := Color(0.9, 0.78, 1.0)
var reduction := 0.6
var _t := 0.0

func _ready() -> void:
	z_index = 29

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if float(p.get("hp")) <= 0.0:
			continue
		var dist: float = p.global_position.distance_to(global_position)
		if GameState.is_topdown():
			if dist > radius:
				continue
		elif absf(p.global_position.x - global_position.x) > radius:
			continue
		# ochrona nie stackuje się: odświeżamy tylko czas i bierzemy najsilniejszą redukcję
		p.set("dome_t", 0.15)
		p.set("dome_reduction", maxf(float(p.get("dome_reduction")), reduction))
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	var fade := clampf((duration - _t) / 0.6, 0.0, 1.0)
	var a := (0.18 + 0.08 * pulse) * fade
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, a * 0.45))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(col.r, col.g, col.b, a + 0.32), 4.0, true)
	draw_arc(Vector2.ZERO, radius - 8.0, 0.0, TAU, 72, Color(1, 1, 1, a * 0.7), 1.5, true)
	for i in 8:
		var ang := _t * 0.8 + TAU * float(i) / 8.0
		var p := Vector2(cos(ang), sin(ang)) * (radius - 18.0)
		draw_circle(p, 3.0 + pulse * 1.5, Color(1.0, 0.92, 0.55, 0.75 * fade))
	# delikatne linie biegnące od środka
	for i in 6:
		var a2 := -_t * 0.45 + TAU * float(i) / 6.0
		draw_line(Vector2.ZERO, Vector2(cos(a2), sin(a2)) * radius, Color(col.r, col.g, col.b, a * 0.25), 1.0)
