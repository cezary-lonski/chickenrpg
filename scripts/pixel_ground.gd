class_name PixelGround
extends RefCounted
## Podłoże świata w pixel arcie: plamy trzech odcieni, kępki trawy / kamienie / piasek / pęknięcia
## zależnie od terenu oraz ścieżki z postrzępionymi brzegami. Tekstura jest wypiekana raz na teren.

const CELL := 4.0
static var _cache: Dictionary = {}

static func style_of(terrain: String) -> String:
	match terrain:
		"palace":
			return "marble"
		"city", "tower", "fortress", "cave", "dawn":
			return "stone"
		"ash":
			return "ash"
		"desert":
			return "sand"
	return "grass"

static func _hash(x: int, y: int, s: int) -> float:
	var n := (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177 & 0x7fffffff
	return float(n % 10000) / 10000.0

## Prostokąty ścieżek (piksele świata) dla danego terenu.
static func path_rects(terrain: String, size: Vector2) -> Array:
	if terrain == "road":
		return [Rect2(0, size.y * 0.42, size.x, size.y * 0.2)]
	if terrain == "palace":
		return [Rect2(size.x * 0.44, 0, size.x * 0.12, size.y)]
	return [Rect2(0, size.y * 0.52, size.x, size.y * 0.10), Rect2(size.x * 0.47, 0, size.x * 0.08, size.y)]

static func sprite(terrain: String, size: Vector2, base: Color, path: Color, decor: Color) -> Sprite2D:
	var key := terrain
	var tex: ImageTexture
	if _cache.has(key):
		tex = _cache[key]
	else:
		tex = _bake(terrain, size, base, path, decor)
		_cache[key] = tex
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(CELL, CELL)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = -10
	return s

static func _tone(c: Color, k: float) -> Color:
	return c.lightened(k) if k > 0.0 else c.darkened(-k)

static func _bake(terrain: String, size: Vector2, base: Color, path: Color, decor: Color) -> ImageTexture:
	var gw := int(ceil(size.x / CELL))
	var gh := int(ceil(size.y / CELL))
	var img := Image.create(gw, gh, false, Image.FORMAT_RGBA8)
	var style := style_of(terrain)
	var big := FastNoiseLite.new()
	big.seed = 11
	big.frequency = 0.028
	var mid := FastNoiseLite.new()
	mid.seed = 29
	mid.frequency = 0.11
	var edge := FastNoiseLite.new()
	edge.seed = 53
	edge.frequency = 0.09
	var rects := path_rects(terrain, size)
	var dec := Color(decor.r, decor.g, decor.b, 1.0)
	for y in gh:
		for x in gw:
			var px := (float(x) + 0.5) * CELL
			var py := (float(y) + 0.5) * CELL
			var v := big.get_noise_2d(float(x), float(y))
			var m := mid.get_noise_2d(float(x), float(y))
			# --- ścieżka z postrzępionym brzegiem
			var in_path := false
			var near_edge := false
			var jag := edge.get_noise_2d(float(x), float(y)) * 14.0
			for r in rects:
				var rr := Rect2(r.position + Vector2(jag, jag), r.size - Vector2(jag, jag) * 2.0)
				if rr.has_point(Vector2(px, py)):
					in_path = true
					if not rr.grow(-CELL * 1.5).has_point(Vector2(px, py)):
						near_edge = true
			var c: Color
			if in_path:
				c = path
				if m > 0.35:
					c = _tone(c, 0.07)
				elif m < -0.3:
					c = _tone(c, -0.08)
				if near_edge:
					c = _tone(c, -0.14)
				var hs := _hash(x, y, 3)
				if hs < 0.025:
					c = _tone(path, -0.22)           # kamyczki
				elif hs > 0.985:
					c = _tone(path, 0.2)
			else:
				c = base
				if v > 0.22:
					c = _tone(base, 0.09)
				elif v < -0.26:
					c = _tone(base, -0.1)
				if m > 0.42 and v > 0.0:
					c = _tone(c, 0.05)
				var h2 := _hash(x, y, 7)
				match style:
					"grass":
						if h2 < 0.018:
							c = _tone(base, 0.2)
						elif h2 > 0.992:
							c = dec.lightened(0.25)
						elif h2 > 0.975:
							c = _tone(base, -0.16)
					"stone":
						var row := y / 7
						var xo := x + (row % 2) * 5
						var bx := xo / 10
						if y % 7 == 0 or xo % 10 == 0:
							c = _tone(c, -0.16)
						else:
							c = _tone(c, (_hash(bx, row, 5) - 0.5) * 0.12)
					"marble":
						var tx := x / 10
						var ty := y / 10
						if (tx + ty) % 2 == 0:
							c = _tone(c, 0.05)
						if x % 10 == 0 or y % 10 == 0:
							c = _tone(c, -0.1)
						if h2 > 0.985:
							c = _tone(c, 0.12)
					"sand":
						var rip := sin(float(x) * 0.18 + big.get_noise_2d(float(x), float(y) * 2.0) * 5.0 + float(y) * 0.5)
						if rip > 0.93:
							c = _tone(base, 0.1)
						elif rip < -0.95:
							c = _tone(base, -0.09)
						if h2 > 0.994:
							c = _tone(base, -0.24)
					"ash":
						if absf(big.get_noise_2d(float(x) * 1.7, float(y) * 1.7)) < 0.022:
							c = _tone(base, -0.18)
						if h2 > 0.996:
							c = dec.lightened(0.35)
						elif h2 < 0.02:
							c = _tone(base, 0.08)
			img.set_pixel(x, y, c)
	# kępki trawy
	if style == "grass":
		var r := RandomNumberGenerator.new()
		r.seed = 99
		for i in int(float(gw * gh) / 260.0):
			var tx := r.randi_range(2, gw - 3)
			var ty := r.randi_range(3, gh - 2)
			var tc := _tone(base, 0.24)
			var td := _tone(base, -0.2)
			img.set_pixel(tx, ty, td)
			img.set_pixel(tx, ty - 1, tc)
			img.set_pixel(tx - 1, ty - 2, tc)
			img.set_pixel(tx + 1, ty - 2, tc)
	return ImageTexture.create_from_image(img)
