class_name DamageZone
extends Node2D
## Strefa obrażeń w czasie (np. Krąg Ognia): rani wrogów w promieniu przez czas trwania.

var radius := 150.0
var duration := 5.0
var dps := 30.0
var col := Color(1.0, 0.5, 0.2)
var source: Node = null
var _t := 0.0
var _tick := 0.0

func _ready() -> void:
	z_index = 27

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.4
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or not (e is Node2D):
				continue
			if e.has_method("is_dead") and e.is_dead():
				continue
			var d: float = e.global_position.distance_to(global_position) if GameState.is_topdown() else absf(e.global_position.x - global_position.x)
			if d > radius:
				continue
			var hb: Hurtbox = e.get_node_or_null("Hurtbox")
			if hb:
				hb.take_hit({
					"damage": dps * 0.4, "kb": Vector2.ZERO, "hitstun": 0.08, "launch": false,
					"crit": false, "team": (String(source.get("team_tag")) if (source != null and is_instance_valid(source) and "team_tag" in source) else "player"), "source": source, "kind": "zone",
				})
	queue_redraw()

func _draw() -> void:
	var fade := clampf((duration - _t) / 0.5, 0.0, 1.0)
	var pulse := 0.6 + 0.4 * sin(_t * 8.0)
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, 0.12 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(col.r, col.g, col.b, (0.35 + 0.25 * pulse) * fade), 3.0, true)
	for i in 9:
		var a := _t * 1.6 + TAU * float(i) / 9.0
		var r := radius * (0.35 + 0.55 * fposmod(float(i) * 0.37 + _t * 0.3, 1.0))
		var base := Vector2(cos(a), sin(a)) * r
		var h := 10.0 + 8.0 * sin(_t * 9.0 + float(i))
		draw_line(base, base + Vector2(sin(_t * 7.0 + float(i)) * 3.0, -h), Color(col.r, col.g * 0.8, col.b, 0.7 * fade), 3.0, true)
		draw_circle(base + Vector2(0, -h), 2.5, Color(1.0, 0.85, 0.4, 0.7 * fade))
