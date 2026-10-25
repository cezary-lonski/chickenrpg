class_name PixelProps
extends RefCounted
## Rekwizyty świata narysowane jako pixel art (drzewa, domy, studnia, kolumny, skały…).
## Każda funkcja zwraca Sprite2D z gotową teksturą; punkt (0,0) to „stopy” obiektu.

const CELL := 4.0

static func _rng(seed_i: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_i * 7919 + 17
	return r

static func _shade(c: Color, k: float) -> Color:
	return c.lightened(k) if k > 0.0 else c.darkened(-k)

static func tree(seed_i: int, leaf: Color = Color(0.25, 0.5, 0.24)) -> Sprite2D:
	var r := _rng(seed_i)
	var cv := PixelCanvas.new(36, 44, Vector2(-72, -176), CELL)
	var bark := Color(0.4, 0.27, 0.16)
	# korzenie i pień
	cv.poly(PackedVector2Array([Vector2(-16, 0), Vector2(-7, -14), Vector2(7, -14), Vector2(16, 0)]), bark.darkened(0.1))
	cv.poly(PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(6, -84), Vector2(-6, -84)]), bark)
	cv.line(Vector2(-2, -12), Vector2(-3, -70), bark.darkened(0.25), 3.0)
	cv.line(Vector2(3, -20), Vector2(2, -60), bark.lightened(0.12), 3.0)
	# korona: ciemne spody, jasne wierzchołki
	var blobs := [
		[Vector2(-26, -86), 26.0, -0.12], [Vector2(26, -88), 25.0, -0.1], [Vector2(0, -80), 28.0, -0.16],
		[Vector2(-20, -108), 25.0, 0.0], [Vector2(22, -110), 24.0, 0.0], [Vector2(0, -122), 27.0, 0.07],
	]
	for b in blobs:
		var c: Vector2 = b[0] + Vector2(r.randf_range(-4, 4), r.randf_range(-4, 4))
		cv.circle(c, float(b[1]) + r.randf_range(-3, 3), _shade(leaf, float(b[2])), true)
	# listki: jaśniejsze i ciemniejsze kępki
	for i in 22:
		var a := r.randf() * TAU
		var d := r.randf_range(8.0, 38.0)
		var p := Vector2(0, -100) + Vector2(cos(a) * d * 1.05, sin(a) * d * 0.9)
		cv.dot(p, leaf.lightened(0.28) if r.randf() < 0.5 else leaf.darkened(0.3))
	cv.finish()
	return cv.to_sprite()

static func dead_tree(seed_i: int) -> Sprite2D:
	var r := _rng(seed_i)
	var cv := PixelCanvas.new(32, 34, Vector2(-64, -136), CELL)
	var col := Color(0.36, 0.28, 0.21)
	cv.poly(PackedVector2Array([Vector2(-10, 0), Vector2(-5, -20), Vector2(5, -20), Vector2(10, 0)]), col.darkened(0.1))
	cv.line(Vector2(0, -10), Vector2(-4, -54), col, 10.0)
	cv.line(Vector2(-4, -54), Vector2(3, -96), col.darkened(0.05), 8.0)
	for i in 5:
		var y := -40.0 - i * 11.0
		var dir := -1.0 if i % 2 == 0 else 1.0
		var end := Vector2(dir * r.randf_range(20, 42), y - r.randf_range(14, 32))
		cv.line(Vector2(0, y), end, col.darkened(0.08), 6.0)
		cv.line(end, end + Vector2(dir * 10, -12), col.darkened(0.12), 4.0)
	cv.finish()
	return cv.to_sprite()

static func rock(seed_i: int, col: Color) -> Sprite2D:
	var r := _rng(seed_i)
	var cv := PixelCanvas.new(24, 18, Vector2(-48, -68), CELL)
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * float(i) / 9.0
		pts.append(Vector2(cos(a) * r.randf_range(22, 36), sin(a) * r.randf_range(14, 24) - 22.0))
	cv.poly(pts, col)
	cv.poly(PackedVector2Array([Vector2(-14, -32), Vector2(6, -40), Vector2(20, -28), Vector2(0, -22)]), col.lightened(0.14), false)
	cv.line(Vector2(-6, -30), Vector2(-12, -14), col.darkened(0.3), 2.0)
	for i in 5:
		cv.dot(Vector2(r.randf_range(-26, 26), r.randf_range(-12, 0)), col.darkened(0.25))
	cv.finish()
	return cv.to_sprite()

static func fence() -> Sprite2D:
	var cv := PixelCanvas.new(20, 16, Vector2(-40, -60), CELL)
	var wood := Color(0.55, 0.38, 0.22)
	for i in 2:
		cv.rect(Rect2(-34 + i * 56, -48, 12, 50), wood, true)
	for i in 2:
		cv.rect(Rect2(-36, -36 + i * -14.0, 72, 8), wood.lightened(0.1), true)
	cv.finish()
	return cv.to_sprite()

static func pillar() -> Sprite2D:
	var cv := PixelCanvas.new(16, 40, Vector2(-32, -160), CELL)
	var st := Color(0.58, 0.56, 0.6)
	cv.rect(Rect2(-24, -10, 48, 12), st.darkened(0.12), true)
	cv.poly(PackedVector2Array([Vector2(-18, -8), Vector2(18, -8), Vector2(14, -112), Vector2(-14, -112)]), st)
	cv.line(Vector2(-4, -12), Vector2(-3, -108), st.darkened(0.25), 2.0)
	cv.line(Vector2(5, -12), Vector2(4, -108), st.lightened(0.12), 2.0)
	cv.rect(Rect2(-26, -130, 52, 20), st.darkened(0.06), true)
	cv.finish()
	return cv.to_sprite()

static func well() -> Sprite2D:
	var cv := PixelCanvas.new(28, 28, Vector2(-56, -104), CELL)
	var st := Color(0.58, 0.58, 0.6)
	var wood := Color(0.5, 0.34, 0.2)
	cv.rect(Rect2(-40, -78, 7, 78), wood, true)
	cv.rect(Rect2(33, -78, 7, 78), wood, true)
	cv.ellipse(Vector2(0, -6), 44, 22, st.darkened(0.15), true)
	cv.ellipse(Vector2(0, -12), 38, 18, st, true)
	cv.ellipse(Vector2(0, -14), 28, 12, Color(0.18, 0.34, 0.5), false)
	for i in 5:
		cv.dot(Vector2(-18 + i * 9, -14 + (i % 2) * 4), Color(0.4, 0.62, 0.8))
	cv.poly(PackedVector2Array([Vector2(-50, -76), Vector2(50, -76), Vector2(26, -102), Vector2(-26, -102)]), Color(0.62, 0.3, 0.22))
	cv.line(Vector2(-40, -84), Vector2(40, -84), Color(0.42, 0.2, 0.15), 3.0)
	cv.finish()
	return cv.to_sprite()

static func house(w: float, h: float, wall: Color, roof: Color) -> Sprite2D:
	var cols := int(ceil((w * 1.3 + 16.0) / CELL))
	var rows := int(ceil((h + 112.0) / CELL))
	var cv := PixelCanvas.new(cols, rows, Vector2(-float(cols) * CELL * 0.5, -h - 104.0), CELL)
	# ściana
	cv.rect(Rect2(-w * 0.5, -h, w, h), wall, true)
	var x := -w * 0.5 + 14.0
	while x < w * 0.5 - 6.0:
		cv.line(Vector2(x, -h + 4), Vector2(x, -12), wall.darkened(0.16), 1.0)
		x += 16.0
	# fundament
	cv.rect(Rect2(-w * 0.5, -14, w, 14), Color(0.5, 0.48, 0.5), false)
	var sx := -w * 0.5
	while sx < w * 0.5:
		cv.line(Vector2(sx, -14), Vector2(sx, 0), Color(0.34, 0.32, 0.36), 1.0)
		sx += 20.0
	# cień pod okapem
	cv.rect(Rect2(-w * 0.5, -h, w, 8), wall.darkened(0.3), false)
	# komin
	cv.rect(Rect2(w * 0.22, -h - 96, 26, 50), Color(0.5, 0.44, 0.42), true)
	cv.rect(Rect2(w * 0.22 - 4, -h - 100, 34, 8), Color(0.38, 0.34, 0.34), false)
	# dach
	cv.poly(PackedVector2Array([Vector2(-w * 0.64, -h + 4), Vector2(w * 0.64, -h + 4), Vector2(w * 0.46, -h - 72), Vector2(-w * 0.46, -h - 72)]), roof, true)
	var ry := -h - 4.0
	var row := 0
	while ry > -h - 70.0:
		cv.line(Vector2(-w * 0.62 + (row % 2) * 8.0, ry), Vector2(w * 0.62 - (row % 2) * 8.0, ry), roof.darkened(0.25), 1.0)
		var tx := -w * 0.6 + float(row % 2) * 10.0
		while tx < w * 0.6:
			cv.dot(Vector2(tx, ry - 6.0), roof.lightened(0.14))
			tx += 20.0
		ry -= 14.0
		row += 1
	# drzwi
	cv.rect(Rect2(-26, -66, 52, 66), Color(0.24, 0.16, 0.1), true)
	cv.rect(Rect2(-30, -70, 60, 6), Color(0.45, 0.32, 0.2), false)
	cv.line(Vector2(0, -62), Vector2(0, -2), Color(0.14, 0.09, 0.06), 1.0)
	cv.dot(Vector2(14, -34), Color(0.95, 0.8, 0.3))
	# okna
	for sgn in [-1.0, 1.0]:
		var wx: float = sgn * (w * 0.5 - 40.0)
		if absf(wx) > 34.0:
			cv.rect(Rect2(wx - 17, -h * 0.68, 34, 34), Color(0.45, 0.32, 0.2), false)
			cv.rect(Rect2(wx - 13, -h * 0.68 + 4, 26, 26), Color(0.95, 0.85, 0.5), false)
			cv.line(Vector2(wx, -h * 0.68 + 4), Vector2(wx, -h * 0.68 + 30), Color(0.45, 0.32, 0.2), 1.0)
			cv.line(Vector2(wx - 13, -h * 0.68 + 17), Vector2(wx + 13, -h * 0.68 + 17), Color(0.45, 0.32, 0.2), 1.0)
	cv.finish()
	return cv.to_sprite()

static func dune(width: float, col: Color) -> Sprite2D:
	var cols := int(ceil(width * 1.2 / CELL))
	var cv := PixelCanvas.new(cols, int(ceil(width * 0.5 / CELL)), Vector2(-width * 0.6, -width * 0.25), CELL)
	cv.ellipse(Vector2.ZERO, width * 0.55, width * 0.2, col, false)
	cv.finish(false)
	return cv.to_sprite()

static func bones(seed_i: int) -> Sprite2D:
	var r := _rng(seed_i)
	var cv := PixelCanvas.new(16, 14, Vector2(-32, -28), CELL)
	var col := Color(0.88, 0.84, 0.72)
	for i in 4:
		var a := r.randf_range(-0.9, 0.9)
		var b := Vector2(cos(a), sin(a)) * r.randf_range(14, 26)
		cv.line(Vector2.ZERO, b, col, 4.0)
		cv.circle(b, 4.0, col.lightened(0.05), false)
	cv.finish()
	return cv.to_sprite()

static func twig(length: float, seed_i: int) -> Sprite2D:
	var r := _rng(seed_i)
	var cv := PixelCanvas.new(int(ceil(length / CELL)) + 8, 16, Vector2(-12, -32), CELL)
	var col := Color(0.32, 0.26, 0.2)
	cv.line(Vector2.ZERO, Vector2(length, r.randf_range(-6, 6)), col, 5.0)
	for i in 3:
		var x := r.randf_range(12, length - 10)
		cv.line(Vector2(x, 0), Vector2(x + r.randf_range(10, 22), r.randf_range(-18, 18)), col.darkened(0.1), 3.0)
	cv.finish()
	return cv.to_sprite()

# ---------------------------------------------------------------- wyposażenie wnętrz ---

## Rozmiar kolizji mebla dla decor(); brak wpisu = bez kolizji.
const DECOR_BODY := {
	"shelf": Vector2(120, 28), "table": Vector2(170, 50), "pew": Vector2(110, 26), "altar": Vector2(110, 40), "rack": Vector2(90, 24),
	"round": Vector2(210, 90), "statue": Vector2(40, 30), "cell": Vector2(110, 24), "desk": Vector2(110, 40),
}

static func decor(kind: String, seed_i: int = 0) -> Sprite2D:
	match kind:
		"shelf": return _shelf(seed_i)
		"table": return _feast_table(seed_i)
		"portrait": return _portrait(seed_i)
		"pew": return _pew()
		"altar": return _altar()
		"rack": return _rack()
		"round": return _round_table()
		"banner": return _banner()
		"statue": return _statue()
		"cell": return _cell()
		"desk": return _desk()
	return _statue()

static func _shelf(seed_i: int) -> Sprite2D:
	var cv := PixelCanvas.new(34, 34, Vector2(-68, -120), CELL)
	var wood := Color(0.45, 0.3, 0.18)
	cv.rect(Rect2(-58, -108, 116, 112), wood, true)
	cv.rect(Rect2(-52, -102, 104, 100), wood.darkened(0.35), false)
	for sh in 4:
		var y := -102.0 + sh * 25.0
		cv.rect(Rect2(-52, y + 22, 104, 4), wood.lightened(0.1), false)
		var x := -50.0
		var k := 0
		while x < 46.0:
			var w := 6.0 + float((seed_i + sh * 7 + k * 3) % 3) * 2.0
			var hh := 16.0 + float((seed_i + k * 5 + sh) % 4) * 2.0
			cv.rect(Rect2(x, y + 22 - hh, w, hh), Color.from_hsv(fposmod(float(seed_i * 3 + sh * 5 + k) * 0.137, 1.0), 0.55, 0.78), false)
			x += w + 1.0
			k += 1
	cv.finish()
	return cv.to_sprite()

static func _feast_table(seed_i: int) -> Sprite2D:
	var cv := PixelCanvas.new(46, 30, Vector2(-92, -104), CELL)
	var wood := Color(0.5, 0.34, 0.2)
	cv.rect(Rect2(-82, -20, 10, 22), wood.darkened(0.2), false)
	cv.rect(Rect2(72, -20, 10, 22), wood.darkened(0.2), false)
	cv.rect(Rect2(-88, -50, 176, 34), Color(0.93, 0.9, 0.82), true)
	cv.rect(Rect2(-88, -26, 176, 10), Color(0.75, 0.2, 0.25), false)
	for i in 7:
		var c := Color(0.85, 0.5, 0.25) if (i + seed_i) % 3 == 0 else (Color(0.95, 0.8, 0.3) if (i + seed_i) % 3 == 1 else Color(0.5, 0.75, 0.35))
		cv.circle(Vector2(-72 + i * 24, -40), 7.0 + float(i % 2) * 2.0, c, true)
	cv.rect(Rect2(-6, -74, 12, 26), Color(0.95, 0.85, 0.4), false)
	cv.finish()
	return cv.to_sprite()

static func _portrait(seed_i: int) -> Sprite2D:
	var cv := PixelCanvas.new(18, 22, Vector2(-36, -88), CELL)
	cv.rect(Rect2(-30, -80, 60, 76), Color(0.78, 0.62, 0.22), true)
	var bg := Color.from_hsv(fposmod(float(seed_i) * 0.21, 1.0), 0.35, 0.45)
	cv.rect(Rect2(-24, -74, 48, 64), bg, false)
	cv.circle(Vector2(0, -44), 15.0, Color(0.9, 0.84, 0.72), true)
	cv.rect(Rect2(-9, -50, 4, 4), Color(0.1, 0.1, 0.12), false)
	cv.rect(Rect2(5, -50, 4, 4), Color(0.1, 0.1, 0.12), false)
	cv.rect(Rect2(-12, -26, 24, 16), bg.lightened(0.2), false)
	cv.finish()
	return cv.to_sprite()

static func _pew() -> Sprite2D:
	var cv := PixelCanvas.new(30, 18, Vector2(-60, -64), CELL)
	var wood := Color(0.5, 0.33, 0.2)
	cv.rect(Rect2(-54, -52, 108, 14), wood.lightened(0.05), true)
	cv.rect(Rect2(-54, -34, 108, 8), wood, true)
	cv.rect(Rect2(-54, -34, 8, 34), wood.darkened(0.25), false)
	cv.rect(Rect2(46, -34, 8, 34), wood.darkened(0.25), false)
	cv.finish()
	return cv.to_sprite()

static func _altar() -> Sprite2D:
	var cv := PixelCanvas.new(30, 28, Vector2(-60, -104), CELL)
	cv.rect(Rect2(-52, -50, 104, 52), Color(0.72, 0.7, 0.76), true)
	cv.rect(Rect2(-56, -58, 112, 12), Color(0.82, 0.8, 0.86), false)
	cv.rect(Rect2(-44, -46, 88, 28), Color(0.7, 0.15, 0.2), false)
	for x in [-40.0, 34.0]:
		cv.rect(Rect2(x, -80, 6, 24), Color(0.95, 0.93, 0.85), false)
		cv.circle(Vector2(x + 3, -88), 5.0, Color(1.0, 0.8, 0.3), false)
	cv.rect(Rect2(-3, -96, 6, 38), Color(0.95, 0.8, 0.3), false)
	cv.rect(Rect2(-11, -86, 22, 6), Color(0.95, 0.8, 0.3), false)
	cv.finish()
	return cv.to_sprite()

static func _rack() -> Sprite2D:
	var cv := PixelCanvas.new(28, 28, Vector2(-56, -104), CELL)
	var wood := Color(0.42, 0.28, 0.17)
	cv.rect(Rect2(-48, -96, 96, 96), wood, true)
	cv.rect(Rect2(-42, -90, 84, 84), wood.darkened(0.4), false)
	for i in 4:
		var x := -34.0 + i * 22.0
		cv.line(Vector2(x, -84), Vector2(x, -22), Color(0.82, 0.85, 0.92), 6.0)
		cv.rect(Rect2(x - 7, -30, 14, 5), Color(0.9, 0.7, 0.25), false)
	cv.circle(Vector2(0, -50), 12.0, Color(0.7, 0.2, 0.2), true)
	cv.finish()
	return cv.to_sprite()

static func _round_table() -> Sprite2D:
	var cv := PixelCanvas.new(56, 34, Vector2(-112, -112), CELL)
	cv.ellipse(Vector2(0, -22), 100.0, 52.0, Color(0.45, 0.3, 0.18), true)
	cv.ellipse(Vector2(0, -28), 92.0, 44.0, Color(0.5, 0.35, 0.2), true)
	cv.ellipse(Vector2(0, -30), 76.0, 34.0, Color(0.82, 0.74, 0.5), false)
	cv.line(Vector2(-50, -34), Vector2(40, -26), Color(0.55, 0.4, 0.25), 3.0)
	cv.line(Vector2(-20, -52), Vector2(30, -14), Color(0.55, 0.4, 0.25), 3.0)
	cv.circle(Vector2(-26, -36), 5.0, Color(0.8, 0.2, 0.2), false)
	cv.circle(Vector2(28, -24), 5.0, Color(0.2, 0.4, 0.8), false)
	cv.finish()
	return cv.to_sprite()

static func _banner() -> Sprite2D:
	var cv := PixelCanvas.new(14, 24, Vector2(-28, -100), CELL)
	cv.rect(Rect2(-24, -92, 48, 6), Color(0.55, 0.4, 0.2), false)
	cv.poly(PackedVector2Array([Vector2(-20, -86), Vector2(20, -86), Vector2(20, -22), Vector2(0, -8), Vector2(-20, -22)]), Color(0.55, 0.12, 0.2), true)
	cv.circle(Vector2(0, -56), 11.0, Color(0.1, 0.08, 0.14), false)
	cv.poly(PackedVector2Array([Vector2(0, -62), Vector2(9, -54), Vector2(0, -48)]), Color(0.95, 0.75, 0.25), false)
	cv.finish()
	return cv.to_sprite()

static func _statue() -> Sprite2D:
	var cv := PixelCanvas.new(16, 30, Vector2(-32, -116), CELL)
	var st := Color(0.66, 0.66, 0.7)
	cv.rect(Rect2(-24, -16, 48, 18), st.darkened(0.15), true)
	cv.rect(Rect2(-12, -64, 24, 50), st, true)
	cv.circle(Vector2(0, -74), 11.0, st.lightened(0.1), true)
	cv.rect(Rect2(-15, -66, 30, 8), st.darkened(0.1), false)
	cv.line(Vector2(16, -64), Vector2(16, -24), Color(0.85, 0.87, 0.93), 5.0)
	cv.finish()
	return cv.to_sprite()

static func _cell() -> Sprite2D:
	var cv := PixelCanvas.new(30, 28, Vector2(-60, -104), CELL)
	cv.rect(Rect2(-54, -96, 108, 98), Color(0.3, 0.3, 0.34), true)
	cv.rect(Rect2(-44, -86, 88, 84), Color(0.08, 0.08, 0.1), false)
	for i in 7:
		cv.rect(Rect2(-40 + i * 13, -90, 5, 92), Color(0.58, 0.6, 0.66), false)
	cv.rect(Rect2(-46, -60, 92, 6), Color(0.5, 0.52, 0.58), false)
	cv.finish()
	return cv.to_sprite()

static func _desk() -> Sprite2D:
	var cv := PixelCanvas.new(30, 22, Vector2(-60, -80), CELL)
	var wood := Color(0.48, 0.32, 0.2)
	cv.rect(Rect2(-52, -36, 104, 30), wood, true)
	cv.rect(Rect2(-52, -14, 8, 16), wood.darkened(0.3), false)
	cv.rect(Rect2(44, -14, 8, 16), wood.darkened(0.3), false)
	cv.rect(Rect2(-30, -52, 40, 18), Color(0.92, 0.9, 0.8), false)
	cv.rect(Rect2(-26, -48, 32, 4), Color(0.4, 0.35, 0.3), false)
	cv.rect(Rect2(20, -62, 6, 26), Color(0.95, 0.9, 0.7), false)
	cv.circle(Vector2(23, -66), 4.0, Color(1.0, 0.8, 0.3), false)
	cv.finish()
	return cv.to_sprite()

## Budynek laboratorium: murowany, z zielonymi oknami, kominem z oparami i szyldem z kolbą.
static func lab_building() -> Sprite2D:
	var cv := PixelCanvas.new(60, 56, Vector2(-120, -216), CELL)
	var wall := Color(0.58, 0.6, 0.66)
	var roof := Color(0.2, 0.38, 0.4)
	cv.rect(Rect2(-100, -92, 200, 92), wall, true)
	for i in 10:
		cv.rect(Rect2(-100 + i * 20, -92, 2, 92), wall.darkened(0.2), false)
	cv.rect(Rect2(-100, -16, 200, 16), Color(0.4, 0.4, 0.46), false)
	cv.poly(PackedVector2Array([Vector2(-114, -92), Vector2(114, -92), Vector2(86, -158), Vector2(-86, -158)]), roof, true)
	for r in 4:
		cv.line(Vector2(-108 + r * 6, -98 - r * 16), Vector2(108 - r * 6, -98 - r * 16), roof.darkened(0.3), 1.0)
	cv.rect(Rect2(50, -192, 26, 50), Color(0.45, 0.4, 0.4), true)
	cv.rect(Rect2(44, -198, 38, 10), Color(0.3, 0.28, 0.3), false)
	cv.rect(Rect2(-18, -64, 36, 64), Color(0.12, 0.14, 0.18), true)
	cv.rect(Rect2(-22, -68, 44, 6), Color(0.45, 0.45, 0.52), false)
	for x in [-72.0, 52.0]:
		cv.rect(Rect2(x - 4, -78, 38, 38), Color(0.4, 0.4, 0.46), false)
		cv.rect(Rect2(x, -74, 30, 30), Color(0.45, 0.95, 0.7), false)
		cv.line(Vector2(x + 15, -74), Vector2(x + 15, -44), Color(0.4, 0.4, 0.46), 1.0)
	cv.rect(Rect2(-3, -196, 6, 38), Color(0.4, 0.3, 0.2), false)
	cv.poly(PackedVector2Array([Vector2(-10, -176), Vector2(10, -176), Vector2(20, -148), Vector2(-20, -148)]), Color(0.45, 0.95, 0.7), false)
	cv.rect(Rect2(-6, -192, 12, 18), Color(0.7, 0.9, 0.85), false)
	cv.finish()
	return cv.to_sprite()
