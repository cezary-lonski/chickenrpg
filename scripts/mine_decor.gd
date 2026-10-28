class_name MineDecor
extends Node2D
## Wystrój wnętrza kopalni (MinesDB): tory z podkładami, drewniane stemple i belki, wózki z rudą, beczki, latarnie
## i kałuże — wody w Kopalni Żelaza albo kopce soli w Kopalni Soli. Rysowany raz, pod postaciami.

const SIZE := Vector2(2200, 1500)

var _mine := "kopalnia_zelaza"

func setup(mine_id: String) -> void:
	_mine = mine_id
	z_as_relative = false
	queue_redraw()

func _draw() -> void:
	if SpecialDB.is_camp(_mine):
		_draw_camp()
		return
	var salt := _mine == "kopalnia_soli"
	var rail := Color(0.45, 0.42, 0.4) if not salt else Color(0.7, 0.72, 0.78)
	var wood := Color(0.36, 0.25, 0.15)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_mine)
	# tory: poziome pasy z podkładami
	for y in [320.0, 660.0, 980.0, 1280.0]:
		for x in range(120, int(SIZE.x) - 100, 44):
			draw_rect(Rect2(x, y - 14, 10, 28), wood)
		draw_rect(Rect2(110, y - 8, SIZE.x - 220, 4), rail)
		draw_rect(Rect2(110, y + 6, SIZE.x - 220, 4), rail)
	# stemple i belki stropowe
	for x in range(260, int(SIZE.x) - 200, 380):
		for y in [180.0, 820.0, 1400.0]:
			draw_rect(Rect2(x - 40, y, 12, 100), wood)
			draw_rect(Rect2(x + 40, y, 12, 100), wood)
			draw_rect(Rect2(x - 52, y - 8, 116, 14), wood.lightened(0.12))
	# wózki z urobkiem
	for i in 5:
		var p := Vector2(rng.randf_range(300, SIZE.x - 300), [320.0, 660.0, 980.0, 1280.0][rng.randi() % 4])
		draw_rect(Rect2(p.x - 36, p.y - 40, 72, 34), Color(0.3, 0.28, 0.28))
		draw_rect(Rect2(p.x - 30, p.y - 48, 60, 10), Color(0.8, 0.82, 0.9) if salt else Color(0.5, 0.35, 0.28))
		draw_circle(p + Vector2(-22, -4), 8, Color(0.15, 0.15, 0.17))
		draw_circle(p + Vector2(22, -4), 8, Color(0.15, 0.15, 0.17))
	# beczki
	for i in 8:
		var q := Vector2(rng.randf_range(200, SIZE.x - 200), rng.randf_range(200, SIZE.y - 200))
		draw_rect(Rect2(q.x - 16, q.y - 22, 32, 44), Color(0.45, 0.3, 0.18))
		draw_rect(Rect2(q.x - 16, q.y - 8, 32, 5), Color(0.25, 0.18, 0.1))
	# kałuże / kopce soli
	for i in 9:
		var c := Vector2(rng.randf_range(160, SIZE.x - 160), rng.randf_range(240, SIZE.y - 160))
		if salt:
			draw_rect(Rect2(c.x - 40, c.y - 10, 80, 22), Color(0.95, 0.95, 1.0, 0.85))
			draw_rect(Rect2(c.x - 22, c.y - 22, 44, 14), Color(1, 1, 1, 0.9))
		else:
			draw_rect(Rect2(c.x - 50, c.y - 8, 100, 20), Color(0.2, 0.4, 0.65, 0.55))
			draw_rect(Rect2(c.x - 26, c.y - 4, 52, 4), Color(0.8, 0.92, 1.0, 0.5))
	# latarnie (ciepły blask)
	for i in 10:
		var l := Vector2(200 + i * 190, 100 + (i % 3) * 460)
		draw_circle(l, 44, Color(1.0, 0.8, 0.4, 0.07))
		draw_circle(l, 22, Color(1.0, 0.85, 0.5, 0.12))
		draw_rect(Rect2(l.x - 4, l.y - 6, 8, 12), Color(1.0, 0.9, 0.55))

## Obóz niewolników w opuszczonej kopalni na pustyni: tory, wózki z rudą, hałdy, namioty strażników i ogniska.
func _draw_camp() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_mine)
	var wood := Color(0.4, 0.28, 0.17)
	for y in [420.0, 800.0, 1180.0]:
		for x in range(100, int(SIZE.x) - 80, 46):
			draw_rect(Rect2(x, y - 12, 10, 24), wood)
		draw_rect(Rect2(90, y - 7, SIZE.x - 180, 4), Color(0.4, 0.38, 0.36))
		draw_rect(Rect2(90, y + 5, SIZE.x - 180, 4), Color(0.4, 0.38, 0.36))
	# hałdy urobku
	for i in 7:
		var h := Vector2(rng.randf_range(160, SIZE.x - 160), rng.randf_range(260, SIZE.y - 200))
		draw_colored_polygon(PackedVector2Array([h + Vector2(-70, 24), h + Vector2(-30, -26), h + Vector2(20, -34), h + Vector2(72, 24)]), Color(0.45, 0.35, 0.27))
		draw_colored_polygon(PackedVector2Array([h + Vector2(-34, 24), h + Vector2(-8, -8), h + Vector2(30, 24)]), Color(0.52, 0.42, 0.33))
	# wózki
	for i in 5:
		var p := Vector2(rng.randf_range(260, SIZE.x - 260), [420.0, 800.0, 1180.0][rng.randi() % 3])
		draw_rect(Rect2(p.x - 36, p.y - 38, 72, 32), Color(0.3, 0.28, 0.28))
		draw_rect(Rect2(p.x - 30, p.y - 46, 60, 10), Color(0.5, 0.38, 0.3))
		draw_circle(p + Vector2(-22, -2), 8, Color(0.15, 0.15, 0.17))
		draw_circle(p + Vector2(22, -2), 8, Color(0.15, 0.15, 0.17))
	# namioty strażników z ogniskami
	for i in 4:
		var t := Vector2(rng.randf_range(300, SIZE.x - 300), rng.randf_range(300, SIZE.y - 300))
		draw_colored_polygon(PackedVector2Array([t + Vector2(-52, 26), t + Vector2(0, -50), t + Vector2(52, 26)]), Color(0.62, 0.35, 0.3))
		draw_colored_polygon(PackedVector2Array([t + Vector2(-14, 26), t + Vector2(0, -6), t + Vector2(14, 26)]), Color(0.1, 0.07, 0.07))
		var f := t + Vector2(80, 14)
		draw_circle(f, 40, Color(1.0, 0.7, 0.3, 0.08))
		draw_circle(f, 8, Color(1.0, 0.6, 0.2, 0.9))
	# kajdany i palisada przy klatkach
	for i in 12:
		var q := Vector2(150 + i * 170, 90)
		draw_rect(Rect2(q.x - 4, q.y, 8, 70), wood)
		draw_colored_polygon(PackedVector2Array([q + Vector2(-5, 0), q + Vector2(0, -14), q + Vector2(5, 0)]), wood.lightened(0.1))
