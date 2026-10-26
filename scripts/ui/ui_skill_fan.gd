class_name UiSkillFan
extends Control
## Umiejętności jako rząd dziewięciu jajek (klawisze 1–9), bez listwy i tła. Cooldown zaciemnia jajko od góry,
## brak energii przygasza je, pusty slot to ciemne jajko. Nazwa na jajku, numer klawisza pod nim.

const N := 9
const STEP := 70.0
const EGG_W := 52.0
const EGG_H := 66.0

var player: Player = null

func _init() -> void:
	custom_minimum_size = Vector2(STEP * float(N - 1) + EGG_W, 104)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS

func _process(_delta: float) -> void:
	queue_redraw()

func _egg_points(cx: float, cy: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 28:
		var a := TAU * float(k) / 28.0
		var y := -cos(a)
		pts.append(Vector2(cx + sin(a) * EGG_W * 0.5 * (1.0 - 0.14 * maxf(0.0, -y)), cy + y * EGG_H * 0.5))
	return pts

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var c := pts.duplicate()
	c.append(pts[0])
	return c

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var slots: Array = player.skill_slots if player != null and is_instance_valid(player) else []
	var cds: Array = player.skill_cd if player != null and is_instance_valid(player) else []
	for i in N:
		var cx := EGG_W * 0.5 + float(i) * STEP
		var cy := EGG_H * 0.5 + 2.0
		var pts := _egg_points(cx, cy)
		var id := String(slots[i]) if i < slots.size() else ""
		if id == "":
			draw_colored_polygon(pts, Color(0.16, 0.11, 0.07, 0.8))
			draw_polyline(_closed(pts), Color(0.42, 0.29, 0.17), 2.0)
		else:
			var d := SkillDB.get_data(id)
			var cd := float(cds[i]) if i < cds.size() else 0.0
			var cost := float(d.get("cost", 0.0))
			var enough := player != null and player.energy >= cost
			var shell := Color(0.96, 0.94, 0.86) if cd <= 0.0 and enough else Color(0.62, 0.6, 0.54)
			draw_colored_polygon(pts, shell)
			draw_polyline(_closed(pts), Color(0.07, 0.07, 0.08), 2.5)
			if cd > 0.0:
				var total := maxf(0.1, float(d.get("cd", 3.0)))
				var frac := clampf(cd / total, 0.0, 1.0)
				var cut := cy - EGG_H * 0.5 + EGG_H * frac
				var shade := PackedVector2Array()
				for p in pts:
					shade.append(Vector2(p.x, minf(p.y, cut)))
				draw_colored_polygon(shade, Color(0.05, 0.05, 0.08, 0.6))
			var nm := String(d.get("name", "?")).substr(0, 4)
			draw_string(font, Vector2(cx - EGG_W * 0.5, cy + 1.0), nm, HORIZONTAL_ALIGNMENT_CENTER, EGG_W, 15, Color(0.2, 0.13, 0.07))
			var sub := ("%.0f" % cd) if cd > 0.0 else ("%d" % int(cost))
			draw_string(font, Vector2(cx - EGG_W * 0.5, cy + 19.0), sub, HORIZONTAL_ALIGNMENT_CENTER, EGG_W, 12, Color(0.4, 0.28, 0.16) if cd <= 0.0 else Color(1.0, 0.85, 0.6))
		draw_string(font, Vector2(cx - 10.0, cy + EGG_H * 0.5 + 16.0), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 20.0, 14, Color(0.95, 0.88, 0.7))

func _get_tooltip(at: Vector2) -> String:
	if player == null or not is_instance_valid(player):
		return ""
	var i := int(clampf(round((at.x - EGG_W * 0.5) / STEP), 0.0, float(N - 1)))
	if absf(at.x - (EGG_W * 0.5 + float(i) * STEP)) > EGG_W * 0.6:
		return ""
	var id := String(player.skill_slots[i]) if i < player.skill_slots.size() else ""
	if id == "":
		return "Pusty slot (klawisz %d)" % (i + 1)
	var d := SkillDB.get_data(id)
	return "%s\n%s\nKoszt: %d energii · cd %.1fs" % [d.get("name", ""), d.get("desc", ""), int(d.get("cost", 0.0)), float(d.get("cd", 0.0))]
