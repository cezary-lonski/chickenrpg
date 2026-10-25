class_name BossTelegraph
extends Node2D
## Zapowiedzi niebezpiecznych ataków bossa rysowane na ziemi (okręgi, pierścienie, linie,
## obracające się promienie). Gracz ma czas zareagować: wyjść z obszaru, użyć uniku
## (iframe'y) albo umiejętności obronnej.

var items: Array = []
var beams: Dictionary = {}   # {center, angles, length, width, active}

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 2

func add_circle(c: Vector2, r: float, dur: float, col: Color = Color(1.0, 0.25, 0.2)) -> void:
	items.append({"type": "circle", "c": c, "r": r, "dur": dur, "t": 0.0, "col": col})

func add_ring(c: Vector2, r_in: float, r_out: float, dur: float, col: Color = Color(1.0, 0.3, 0.2)) -> void:
	items.append({"type": "ring", "c": c, "ri": r_in, "ro": r_out, "dur": dur, "t": 0.0, "col": col})

func add_line(a: Vector2, b: Vector2, w: float, dur: float, col: Color = Color(1.0, 0.3, 0.2)) -> void:
	items.append({"type": "line", "a": a, "b": b, "w": w, "dur": dur, "t": 0.0, "col": col})

func clear() -> void:
	items.clear()
	beams = {}

func _process(delta: float) -> void:
	for it in items:
		it["t"] = float(it["t"]) + delta
	items = items.filter(func(it): return float(it["t"]) < float(it["dur"]) + 0.05)
	queue_redraw()

func _draw() -> void:
	for it in items:
		var k := clampf(float(it["t"]) / maxf(0.01, float(it["dur"])), 0.0, 1.0)
		var col: Color = it["col"]
		match String(it["type"]):
			"circle":
				var c: Vector2 = it["c"]
				var r := float(it["r"])
				draw_circle(c, r, Color(col.r, col.g, col.b, 0.10 + 0.12 * k))
				draw_circle(c, r * k, Color(col.r, col.g, col.b, 0.22 + 0.2 * k))
				draw_arc(c, r, 0.0, TAU, 56, Color(col.r, col.g, col.b, 0.7 + 0.3 * k), 3.0, true)
			"ring":
				var c2: Vector2 = it["c"]
				var ri := float(it["ri"])
				var ro := float(it["ro"])
				draw_arc(c2, (ri + ro) * 0.5, 0.0, TAU, 96, Color(col.r, col.g, col.b, 0.14 + 0.2 * k), ro - ri, true)
				draw_arc(c2, ri, 0.0, TAU, 96, Color(col.r, col.g, col.b, 0.8), 2.5, true)
				draw_arc(c2, ro, 0.0, TAU, 96, Color(col.r, col.g, col.b, 0.8), 2.5, true)
			"line":
				var a: Vector2 = it["a"]
				var b: Vector2 = it["b"]
				var w := float(it["w"])
				draw_line(a, b, Color(col.r, col.g, col.b, 0.12 + 0.2 * k), w, true)
				draw_line(a, a.lerp(b, k), Color(col.r, col.g, col.b, 0.35 + 0.3 * k), w * 0.8, true)
				draw_line(a, b, Color(col.r, col.g, col.b, 0.75), 2.0, true)
	if not beams.is_empty():
		var c3: Vector2 = beams["center"]
		var active := bool(beams.get("active", false))
		var length := float(beams.get("length", 800.0))
		var width := float(beams.get("width", 44.0))
		for ang in beams["angles"]:
			var tip := c3 + Vector2.RIGHT.rotated(float(ang)) * length
			if active:
				draw_line(c3, tip, Color(0.7, 0.2, 1.0, 0.35), width * 1.6, true)
				draw_line(c3, tip, Color(0.95, 0.6, 1.0, 0.9), width, true)
				draw_line(c3, tip, Color(1, 1, 1, 0.9), width * 0.3, true)
			else:
				draw_line(c3, tip, Color(0.8, 0.3, 1.0, 0.45), 4.0, true)
