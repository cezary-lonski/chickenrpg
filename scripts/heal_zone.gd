class_name HealZone
extends Node2D

var radius := 220.0
var duration := 5.0
var heal_per_sec := 16.0
var col := Color(0.4, 1.0, 0.6)
var _t := 0.0
var _tick := 0.0

func _ready() -> void:
	z_index = 28

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		for p in get_tree().get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			if float(p.get("hp")) <= 0.0:
				continue
			if GameState.is_topdown():
				if p.global_position.distance_to(global_position) > radius:
					continue
			elif absf(p.global_position.x - global_position.x) > radius:
				continue
			if p.has_method("heal"):
				p.heal(heal_per_sec * 0.25)
			Fx.popup(p.global_position + Vector2(0, -60), "+%d" % int(heal_per_sec * 0.25), Color(0.4, 1.0, 0.6))
	queue_redraw()

func _draw() -> void:
	var fade := clampf((duration - _t) / 0.4, 0.0, 1.0)
	var pulse := 0.6 + 0.4 * sin(_t * 5.0)
	var a := (0.14 + 0.1 * pulse) * fade
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, a * 0.4))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(col.r, col.g, col.b, a + 0.28), 3.0, true)
	for i in 6:
		var ang := _t * 1.2 + TAU * float(i) / 6.0
		var p2 := Vector2(cos(ang), sin(ang)) * (radius * (0.7 + 0.2 * sin(_t * 2.0 + float(i))))
		draw_circle(p2, 2.0 + pulse, Color(0.8, 1.0, 0.9, 0.8 * fade))
