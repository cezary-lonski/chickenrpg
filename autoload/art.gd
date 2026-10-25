extends Node
## Art — proceduralna grafika 2D. Projekt nie wymaga żadnych plików graficznych:
## wszystko rysowane jest w kodzie (kształty) albo generowane jako tekstury (Image/Gradient).

# ---------------------------------------------------------------- tekstury ---

var _cache: Dictionary = {}

func _fill_poly(img: Image, pts: PackedVector2Array, col: Color) -> void:
	var n := pts.size()
	if n < 3:
		return
	var min_y := INF
	var max_y := -INF
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var y0 := maxi(0, int(floor(min_y)))
	var y1 := mini(img.get_height() - 1, int(ceil(max_y)))
	for y in range(y0, y1 + 1):
		var yc := float(y) + 0.5
		var xs: Array[float] = []
		for i in n:
			var a := pts[i]
			var b := pts[(i + 1) % n]
			if (a.y <= yc and b.y > yc) or (b.y <= yc and a.y > yc):
				xs.append(a.x + (yc - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var sx := int(round(xs[k]))
			var ex := int(round(xs[k + 1]))
			for x in range(maxi(0, sx), mini(img.get_width() - 1, ex) + 1):
				img.set_pixel(x, y, col)
			k += 2

func _rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y),
	])

func _ellipse_pts(c: Vector2, rx: float, ry: float, steps: int = 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out

func _star_pts(c: Vector2, r_out: float, r_in: float, tips: int, phase: float = -PI / 2.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in tips * 2:
		var a := phase + TAU * float(i) / float(tips * 2)
		var r := r_out if i % 2 == 0 else r_in
		out.append(c + Vector2(cos(a) * r, sin(a) * r))
	return out

func _blank(w: int, h: int, col: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return img

func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

func _cached(key: String) -> Variant:
	return _cache.get(key)

# ------------------------------------------------------------- gradienty ---

func gradient(colors: Array, vertical: bool = true, w: int = 8, h: int = 128) -> GradientTexture2D:
	var key := "grad|%s|%s|%d|%d" % [str(colors), str(vertical), w, h]
	if _cache.has(key):
		return _cache[key]
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offsets.append(float(i) / maxf(1.0, float(colors.size() - 1)))
		cols.append(colors[i])
	g.offsets = offsets
	g.colors = cols
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = w
	t.height = h
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1) if vertical else Vector2(1, 0)
	_cache[key] = t
	return t

func radial_glow(radius: int, col: Color) -> ImageTexture:
	var key := "glow|%d|%s" % [radius, str(col)]
	if _cache.has(key):
		return _cache[key]
	var s := radius * 2
	var img := _blank(s, s, Color(0, 0, 0, 0))
	for y in s:
		for x in s:
			var d := Vector2(x - radius + 0.5, y - radius + 0.5).length() / float(radius)
			if d <= 1.0:
				var a := pow(1.0 - d, 2.0)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * a))
	_cache[key] = _tex(img)
	return _cache[key]

func soft_blob(size: int, col: Color, lumpy: float = 0.3, seed_v: int = 1) -> ImageTexture:
	var key := "blob|%d|%s|%.2f|%d" % [size, str(col), lumpy, seed_v]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var img := _blank(size, size, Color(0, 0, 0, 0))
	var r := size * 0.5
	var lobes: Array[float] = []
	for i in 6:
		lobes.append(r * (1.0 - lumpy + rng.randf() * lumpy * 2.0))
	for y in size:
		for x in size:
			var d := Vector2(x - r + 0.5, y - r + 0.5).length() / r
			var a := atan2(y - r + 0.5, x - r + 0.5)
			var lim := 0.0
			for i in lobes.size():
				lim += sin(a * (i + 2.0) + float(i) * 1.7) * (lobes[i] / r) / float(i + 2.0)
			lim = (lobes[0] / r) + lim * 0.35
			if d <= lim:
				var t := clampf(d / maxf(0.01, lim), 0.0, 1.0)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * clampf(1.25 - t * 0.5, 0.0, 1.0)))
	_cache[key] = _tex(img)
	return _cache[key]

func vignette(size: Vector2i, strength: float = 0.55) -> ImageTexture:
	var img := _blank(size.x, size.y, Color(0, 0, 0, 0))
	var c := Vector2(size.x, size.y) * 0.5
	var maxd := c.length()
	for y in size.y:
		for x in size.x:
			var d := (Vector2(x, y) - c).length() / maxd
			img.set_pixel(x, y, Color(0, 0, 0, strength * pow(clampf(d, 0.0, 1.0), 2.2)))
	return _tex(img)

# ---------------------------------------------------------------- ikony ---

## Rysuje ikonę przedmiotu (id z ItemDB) w kwadracie o boku `s`.
func item_icon(id: String, s: int = 32) -> ImageTexture:
	var key := "icon|%s|%d" % [id, s]
	if _cache.has(key):
		return _cache[key]
	var data := ItemDB.get_data(id)
	var kind := String(data.get("icon", "jajko"))
	if PixelIcons.has(kind):
		var ptex := ImageTexture.create_from_image(PixelIcons.make(kind, data.get("tint", Color(0, 0, 0, 0)), s))
		_cache[key] = ptex
		return ptex
	var img := _blank(s, s, Color(0, 0, 0, 0))
	var f := float(s) / 32.0
	var metal := Color(0.78, 0.82, 0.9)
	var dark := Color(0.34, 0.36, 0.44)
	var wood := Color(0.6, 0.42, 0.24)
	var gold := Color(0.98, 0.79, 0.25)
	var cloth := Color(0.72, 0.24, 0.26)
	var bone := Color(0.94, 0.92, 0.85)
	var green := Color(0.55, 0.85, 0.4)
	var shell := Color(0.42, 0.78, 0.78)

	if kind == "kol":
			_fill_poly(img, _rect_pts(Rect2(14 * f, 3 * f, 5 * f, 26 * f)), wood)
			_fill_poly(img, _rect_pts(Rect2(12 * f, 3 * f, 2 * f, 5 * f)), dark)
	elif kind == "kij":
			_fill_poly(img, _rect_pts(Rect2(15 * f, 2 * f, 4 * f, 20 * f)), wood)
			_fill_poly(img, _ellipse_pts(Vector2(17 * f, 8 * f), 8 * f, 8 * f), dark)
	elif kind == "widelec":
			_fill_poly(img, _rect_pts(Rect2(15 * f, 10 * f, 2.5 * f, 19 * f)), metal)
			for i in 4:
				_fill_poly(img, _rect_pts(Rect2((9.5 + i * 4) * f, 3 * f, 2 * f, 9 * f)), metal)
	elif kind == "kosa":
			_fill_poly(img, _rect_pts(Rect2(7 * f, 4 * f, 3 * f, 25 * f)), wood)
			_fill_poly(img, PackedVector2Array([Vector2(8 * f, 6 * f), Vector2(26 * f, 9 * f), Vector2(24 * f, 16 * f), Vector2(8 * f, 12 * f)]), metal)
	elif kind == "mlot":
			_fill_poly(img, _rect_pts(Rect2(14 * f, 12 * f, 4 * f, 18 * f)), wood)
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 9 * f), 11 * f, 6 * f), dark)
	elif kind == "szabla":
			_fill_poly(img, PackedVector2Array([Vector2(6 * f, 26 * f), Vector2(9 * f, 6 * f), Vector2(20 * f, 4 * f), Vector2(11 * f, 20 * f)]), metal)
			_fill_poly(img, _rect_pts(Rect2(4 * f, 24 * f, 13 * f, 3 * f)), gold)
			_fill_poly(img, _rect_pts(Rect2(6 * f, 27 * f, 3 * f, 4 * f)), dark)
	elif kind == "dziobak":
			_fill_poly(img, _rect_pts(Rect2(15 * f, 8 * f, 2.5 * f, 22 * f)), dark)
			for i in 3:
				_fill_poly(img, PackedVector2Array([Vector2(15 * f, (8 + i * 7) * f), Vector2(23 * f, (7 + i * 7) * f), Vector2(15 * f, (13 + i * 7) * f)]), metal)
	elif kind == "laska":
			_fill_poly(img, _rect_pts(Rect2(15 * f, 4 * f, 2.5 * f, 26 * f)), wood)
			_fill_poly(img, _star_pts(Vector2(16 * f, 8 * f), 10 * f, 4 * f, 5), gold)
	elif kind == "pioro":
			_fill_poly(img, PackedVector2Array([Vector2(5 * f, 28 * f), Vector2(20 * f, 3 * f), Vector2(27 * f, 10 * f), Vector2(12 * f, 30 * f)]), Color(0.95, 0.95, 1.0))
			_fill_poly(img, _rect_pts(Rect2(6 * f, 27 * f, 2 * f, 3 * f)), dark)
	elif kind == "kolce":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 15 * f), 11 * f, 9 * f), dark)
			for i in 8:
				var a := TAU * float(i) / 8.0
				_fill_poly(img, PackedVector2Array([
					Vector2(16 * f, 15 * f) + Vector2(cos(a), sin(a)) * 7 * f,
					Vector2(16 * f, 15 * f) + Vector2(cos(a + 0.3), sin(a + 0.3)) * 7 * f,
					Vector2(16 * f, 15 * f) + Vector2(cos(a + 0.15), sin(a + 0.15)) * 14 * f,
				]), metal)
	elif kind == "kamizelka" or kind == "kolczuga" or kind == "pancerz" or kind == "plaszcz" or kind == "szmata" or kind == "upior":
			_fill_poly(img, PackedVector2Array([
				Vector2(10 * f, 5 * f), Vector2(22 * f, 5 * f), Vector2(27 * f, 10 * f),
				Vector2(25 * f, 28 * f), Vector2(7 * f, 28 * f), Vector2(5 * f, 10 * f),
			]), cloth if kind == "plaszcz" else dark)
			if kind == "kamizelka":
				_fill_poly(img, _rect_pts(Rect2(12 * f, 6 * f, 8 * f, 21 * f)), gold)
			if kind == "kolczuga":
				for i in 6:
					for j in 3:
						_fill_poly(img, _ellipse_pts(Vector2((9 + j * 7) * f, (9 + i * 6) * f), 1.2 * f, 1.2 * f), metal)
			if kind == "upior":
				_fill_poly(img, _ellipse_pts(Vector2(16 * f, 13 * f), 4 * f, 4 * f), green)
			if kind == "pancerz":
				_fill_poly(img, _rect_pts(Rect2(6 * f, 15 * f, 20 * f, 3 * f)), gold)
	elif kind == "skorupa":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 18 * f), 12 * f, 10 * f), shell)
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 18 * f), 8 * f, 6.5 * f), shell.lightened(0.25))
			for i in 3:
				_fill_poly(img, _rect_pts(Rect2(6 * f, (12 + i * 5) * f, 20 * f, 1.5 * f)), shell.darkened(0.3))
	elif kind == "skrzydla":
			for sgn in [-1.0, 1.0]:
				_fill_poly(img, PackedVector2Array([
					Vector2(16 * f, 14 * f),
					Vector2(16 * f + sgn * 14 * f, 5 * f),
					Vector2(16 * f + sgn * 15 * f, 16 * f),
					Vector2(16 * f + sgn * 6 * f, 22 * f),
				]), bone)
	elif kind == "obroza":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 20 * f), 11 * f, 8 * f, 18), cloth)
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 20 * f), 6 * f, 4 * f, 16), Color(0, 0, 0, 0))
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 11 * f), 3.5 * f, 3.5 * f), gold)
	elif kind == "koraliki" or kind == "amulet" or kind == "szalik" or kind == "korona" or kind == "feniks":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 14 * f), 9 * f, 9 * f, 18), gold)
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 14 * f), 4 * f, 4 * f), Color(0.9, 0.35, 0.3))
			_fill_poly(img, _rect_pts(Rect2(4 * f, 12 * f, 24 * f, 1.5 * f)), gold.darkened(0.2))
	elif kind == "buty":
			_fill_poly(img, PackedVector2Array([Vector2(6 * f, 12 * f), Vector2(17 * f, 12 * f), Vector2(19 * f, 24 * f), Vector2(4 * f, 24 * f)]), Color(0.35, 0.4, 0.75))
			_fill_poly(img, PackedVector2Array([Vector2(17 * f, 16 * f), Vector2(28 * f, 16 * f), Vector2(29 * f, 24 * f), Vector2(19 * f, 24 * f)]), Color(0.3, 0.35, 0.68))
			_fill_poly(img, _rect_pts(Rect2(4 * f, 24 * f, 25 * f, 3 * f)), bone)
	elif kind == "kiel":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 15 * f), 12 * f, 8 * f), Color(0.8, 0.45, 0.4))
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 20 * f), 12 * f, 6 * f), Color(0.6, 0.3, 0.28))
	elif kind == "piercien":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 18 * f), 10 * f, 10 * f, 22), gold)
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 18 * f), 5 * f, 5 * f, 20), Color(0, 0, 0, 0))
			_fill_poly(img, _star_pts(Vector2(16 * f, 7 * f), 4 * f, 1.8 * f, 4), Color(0.3, 0.8, 1.0))
	elif kind == "okulary":
			_fill_poly(img, _ellipse_pts(Vector2(10 * f, 16 * f), 7 * f, 6 * f), Color(0.2, 0.2, 0.25, 0.9))
			_fill_poly(img, _ellipse_pts(Vector2(23 * f, 16 * f), 7 * f, 6 * f), Color(0.2, 0.2, 0.25, 0.9))
			_fill_poly(img, _rect_pts(Rect2(15 * f, 15 * f, 3 * f, 2 * f)), dark)
			_fill_poly(img, PackedVector2Array([Vector2(6 * f, 13 * f), Vector2(11 * f, 12 * f), Vector2(8 * f, 18 * f)]), Color(1, 1, 1, 0.55))
	elif kind == "miecz":
			_fill_poly(img, PackedVector2Array([Vector2(16 * f, 2 * f), Vector2(20 * f, 7 * f), Vector2(18 * f, 22 * f), Vector2(14 * f, 22 * f), Vector2(12 * f, 7 * f)]), metal)
			_fill_poly(img, _rect_pts(Rect2(8 * f, 21 * f, 16 * f, 3 * f)), gold)
			_fill_poly(img, _rect_pts(Rect2(14.5 * f, 24 * f, 3 * f, 6 * f)), wood)
	elif kind == "helm":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 15 * f), 11 * f, 11 * f), metal)
			_fill_poly(img, _rect_pts(Rect2(5 * f, 15 * f, 22 * f, 11 * f)), Color(0, 0, 0, 0))
			_fill_poly(img, _rect_pts(Rect2(5 * f, 15 * f, 22 * f, 4 * f)), dark)
			_fill_poly(img, _rect_pts(Rect2(15 * f, 5 * f, 2 * f, 12 * f)), metal.lightened(0.3))
	elif kind == "sztabka":
			_fill_poly(img, PackedVector2Array([Vector2(5 * f, 22 * f), Vector2(9 * f, 11 * f), Vector2(27 * f, 11 * f), Vector2(25 * f, 22 * f)]), metal)
			_fill_poly(img, PackedVector2Array([Vector2(9 * f, 11 * f), Vector2(13 * f, 7 * f), Vector2(29 * f, 7 * f), Vector2(27 * f, 11 * f)]), metal.lightened(0.3))
			_fill_poly(img, PackedVector2Array([Vector2(25 * f, 22 * f), Vector2(27 * f, 11 * f), Vector2(29 * f, 7 * f), Vector2(28 * f, 18 * f)]), metal.darkened(0.3))
	elif kind == "krysztal":
			_fill_poly(img, PackedVector2Array([Vector2(16 * f, 3 * f), Vector2(24 * f, 13 * f), Vector2(16 * f, 29 * f), Vector2(8 * f, 13 * f)]), metal)
			_fill_poly(img, PackedVector2Array([Vector2(16 * f, 3 * f), Vector2(16 * f, 29 * f), Vector2(8 * f, 13 * f)]), metal.darkened(0.25))
	elif kind == "klucz":
			_fill_poly(img, _ellipse_pts(Vector2(10 * f, 10 * f), 6 * f, 6 * f), gold)
			_fill_poly(img, _ellipse_pts(Vector2(10 * f, 10 * f), 2.5 * f, 2.5 * f), Color(0, 0, 0, 0))
			_fill_poly(img, _rect_pts(Rect2(14 * f, 9 * f, 14 * f, 3 * f)), gold)
			_fill_poly(img, _rect_pts(Rect2(22 * f, 12 * f, 3 * f, 5 * f)), gold)
			_fill_poly(img, _rect_pts(Rect2(26 * f, 12 * f, 3 * f, 4 * f)), gold)
	elif kind == "luk":
			_fill_poly(img, PackedVector2Array([Vector2(8 * f, 3 * f), Vector2(18 * f, 8 * f), Vector2(22 * f, 16 * f), Vector2(18 * f, 24 * f), Vector2(8 * f, 29 * f), Vector2(12 * f, 16 * f)]), wood)
			_fill_poly(img, _rect_pts(Rect2(8 * f, 15 * f, 20 * f, 2 * f)), bone)
	elif kind == "jajko":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 19 * f), 9 * f, 12 * f), Color(0.97, 0.93, 0.85))
			_fill_poly(img, _ellipse_pts(Vector2(13 * f, 15 * f), 2.5 * f, 3.5 * f), Color(1, 1, 1, 0.8))
	elif kind == "jajko_duze":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 18 * f), 13 * f, 14 * f), Color(0.97, 0.93, 0.85))
			_fill_poly(img, _ellipse_pts(Vector2(11 * f, 12 * f), 3 * f, 4 * f), Color(1, 1, 1, 0.8))
	elif kind == "skamielina":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 19 * f), 10 * f, 10 * f), Color(0.72, 0.7, 0.62))
			_fill_poly(img, _ellipse_pts(Vector2(13 * f, 17 * f), 2 * f, 2 * f), Color(0.15, 0.15, 0.18))
			_fill_poly(img, _ellipse_pts(Vector2(20 * f, 20 * f), 1.5 * f, 1.5 * f), Color(0.15, 0.15, 0.18))
	elif kind == "cebula":
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 20 * f), 11 * f, 10 * f), Color(0.78, 0.5, 0.72))
			_fill_poly(img, PackedVector2Array([Vector2(15 * f, 10 * f), Vector2(17 * f, 10 * f), Vector2(18 * f, 2 * f), Vector2(14 * f, 2 * f)]), green)
	elif kind == "mikstura" or kind == "eliksir" or kind == "koktajl" or kind == "rosol":
			var liquid := Color(0.85, 0.25, 0.3)
			if kind == "eliksir":
				liquid = Color(0.4, 0.6, 0.95)
			elif kind == "koktajl":
				liquid = Color(0.95, 0.75, 0.25)
			elif kind == "rosol":
				liquid = Color(0.95, 0.85, 0.5)
			_fill_poly(img, PackedVector2Array([
				Vector2(12 * f, 4 * f), Vector2(20 * f, 4 * f), Vector2(20 * f, 9 * f),
				Vector2(27 * f, 21 * f), Vector2(27 * f, 27 * f), Vector2(5 * f, 27 * f),
				Vector2(5 * f, 21 * f), Vector2(12 * f, 9 * f),
			]), Color(0.85, 0.9, 0.95, 0.55))
			_fill_poly(img, PackedVector2Array([
				Vector2(9 * f, 17 * f), Vector2(23 * f, 17 * f), Vector2(27 * f, 21 * f),
				Vector2(27 * f, 27 * f), Vector2(5 * f, 27 * f), Vector2(5 * f, 21 * f),
			]), liquid)
			_fill_poly(img, _rect_pts(Rect2(11 * f, 2 * f, 10 * f, 3 * f)), Color(0.5, 0.35, 0.2))
			_fill_poly(img, PackedVector2Array([Vector2(11 * f, 20 * f), Vector2(15 * f, 19 * f), Vector2(12 * f, 25 * f)]), Color(1, 1, 1, 0.4))
	elif kind == "feather":
			_fill_poly(img, PackedVector2Array([Vector2(6 * f, 28 * f), Vector2(22 * f, 3 * f), Vector2(28 * f, 12 * f), Vector2(12 * f, 30 * f)]), Color(0.4, 0.45, 0.55))
			_fill_poly(img, _rect_pts(Rect2(6 * f, 27 * f, 2 * f, 3 * f)), Color(0.9, 0.9, 0.9))
	else:
			_fill_poly(img, _rect_pts(Rect2(6 * f, 6 * f, 20 * f, 20 * f)), metal)
	if data.has("tint"):
		var tint: Color = data["tint"]
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					var lum := 0.45 + (c.r + c.g + c.b) / 3.0 * 0.75
					img.set_pixel(x, y, Color(minf(tint.r * lum, 1.0), minf(tint.g * lum, 1.0), minf(tint.b * lum, 1.0), c.a))
	_cache[key] = _tex(img)
	return _cache[key]

# --------------------------------------------------------- ikony HUD/UI ----

func hud_icon(kind: String, s: int = 24, col: Color = Color(1, 1, 1)) -> ImageTexture:
	var key := "hud|%s|%d|%s" % [kind, s, str(col)]
	if _cache.has(key):
		return _cache[key]
	var f := float(s) / 24.0
	var img := _blank(s, s, Color(0, 0, 0, 0))
	if kind == "health":
			_fill_poly(img, PackedVector2Array([Vector2(12 * f, 21 * f), Vector2(3 * f, 12 * f), Vector2(4 * f, 6 * f), Vector2(12 * f, 9 * f), Vector2(20 * f, 6 * f), Vector2(21 * f, 12 * f)]), col)
	elif kind == "energy":
			_fill_poly(img, _ellipse_pts(Vector2(12 * f, 14 * f), 7 * f, 9 * f), col)
	elif kind == "fury":
			_fill_poly(img, PackedVector2Array([Vector2(13 * f, 2 * f), Vector2(6 * f, 13 * f), Vector2(11 * f, 13 * f), Vector2(10 * f, 22 * f), Vector2(19 * f, 10 * f), Vector2(13 * f, 10 * f)]), col)
	elif kind == "gold":
			_fill_poly(img, _ellipse_pts(Vector2(12 * f, 12 * f), 8 * f, 8 * f), col)
			_fill_poly(img, _ellipse_pts(Vector2(12 * f, 12 * f), 4 * f, 4 * f), Color(0, 0, 0, 0))
	elif kind == "cod":
			_fill_poly(img, PackedVector2Array([Vector2(12 * f, 2 * f), Vector2(20 * f, 10 * f), Vector2(12 * f, 22 * f), Vector2(4 * f, 10 * f)]), col)
	elif kind == "xp":
			_fill_poly(img, _star_pts(Vector2(12 * f, 12 * f), 9 * f, 4 * f, 5), col)
	elif kind == "chicken":
			_fill_poly(img, _ellipse_pts(Vector2(12 * f, 15 * f), 8 * f, 6 * f), col)
			_fill_poly(img, _ellipse_pts(Vector2(16 * f, 7 * f), 4 * f, 4 * f), col)
	elif kind == "skull":
			_fill_poly(img, _ellipse_pts(Vector2(12 * f, 11 * f), 8 * f, 8 * f), col)
			_fill_poly(img, _rect_pts(Rect2(9 * f, 17 * f, 6 * f, 4 * f)), col)
			_fill_poly(img, _ellipse_pts(Vector2(9 * f, 11 * f), 2.2 * f, 2.6 * f), Color(0, 0, 0, 0))
			_fill_poly(img, _ellipse_pts(Vector2(15 * f, 11 * f), 2.2 * f, 2.6 * f), Color(0, 0, 0, 0))
	else:
			_fill_poly(img, _ellipse_pts(Vector2(12 * f, 12 * f), 7 * f, 7 * f), col)
	_cache[key] = _tex(img)
	return _cache[key]
