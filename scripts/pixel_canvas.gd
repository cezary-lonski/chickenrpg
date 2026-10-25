class_name PixelCanvas
extends RefCounted
## Siatka pikseli do rysowania prawdziwego pixel artu w kodzie: kształty trafiają do komórek
## (cell px), dostają płaskie cieniowanie (jasna góra-lewo, ciemny dół-prawo), a całość
## czarny kontur. Wynik to jedna tekstura. Współrzędne są lokalne (w pikselach świata).

const OUTLINE := Color(0.05, 0.04, 0.07, 1.0)

var cell := 4.0
var w := 32
var h := 32
var origin := Vector2.ZERO        # lokalna pozycja lewego górnego rogu siatki
var texture: ImageTexture

var _img: Image
var _bytes := PackedByteArray()
var _kind := PackedByteArray()     # 0 puste, 1 półprzezroczyste, 2 pełne
var _bx0 := 0
var _bx1 := -1
var _by0 := 0
var _by1 := -1

func _init(p_w: int, p_h: int, p_origin: Vector2, p_cell: float = 4.0) -> void:
	w = p_w
	h = p_h
	origin = p_origin
	cell = p_cell
	_bytes.resize(w * h * 4)
	_kind.resize(w * h)
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(_img)
	clear()

func clear() -> void:
	_bytes.fill(0)
	_kind.fill(0)
	_bx0 = w
	_bx1 = -1
	_by0 = h
	_by1 = -1

func _write(i: int, col: Color, kind: int) -> void:
	var o := i * 4
	_bytes[o] = int(col.r * 255.0 + 0.5)
	_bytes[o + 1] = int(col.g * 255.0 + 0.5)
	_bytes[o + 2] = int(col.b * 255.0 + 0.5)
	_bytes[o + 3] = int(col.a * 255.0 + 0.5)
	_kind[i] = kind

func put(x: int, y: int, col: Color) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	var i := y * w + x
	if col.a >= 0.9:
		_write(i, col, 2)
	elif _kind[i] != 2:
		_write(i, col, 1)
	else:
		return
	if x < _bx0: _bx0 = x
	if x > _bx1: _bx1 = x
	if y < _by0: _by0 = y
	if y > _by1: _by1 = y

func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor((p.x - origin.x) / cell)), int(floor((p.y - origin.y) / cell)))

## Pojedyncza komórka w punkcie lokalnym.
func dot(p: Vector2, col: Color) -> void:
	var c := cell_of(p)
	put(c.x, c.y, col)

func _q(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2((p.x - origin.x) / cell, (p.y - origin.y) / cell))
	return out

func poly(pts: PackedVector2Array, col: Color, shade: bool = true) -> void:
	_fill(_q(pts), col, shade)

func ellipse(c: Vector2, rx: float, ry: float, col: Color, shade: bool = true, steps: int = 20) -> void:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	poly(pts, col, shade)

func circle(c: Vector2, r: float, col: Color, shade: bool = true) -> void:
	ellipse(c, r, r, col, shade, 16)

func rect(r: Rect2, col: Color, shade: bool = false) -> void:
	poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), col, shade)

func line(a: Vector2, b: Vector2, col: Color, width: float = 1.0) -> void:
	var d := b - a
	if d.length() < 0.01:
		dot(a, col)
		return
	var nrm := Vector2(-d.y, d.x).normalized() * maxf(width, cell * 0.95) * 0.5
	poly(PackedVector2Array([a + nrm, b + nrm, b - nrm, a - nrm]), col, false)

func _fill(q: PackedVector2Array, col: Color, shade: bool) -> void:
	var n := q.size()
	if n < 3:
		return
	var minx := INF
	var maxx := -INF
	var miny := INF
	var maxy := -INF
	for p in q:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var bw := maxx - minx
	var bh := maxy - miny
	var do_shade := shade and col.a >= 0.9 and bw >= 4.0 and bh >= 4.0
	var light := col.lightened(0.15)
	var dark := col.darkened(0.17)
	var any := false
	for y in range(maxi(0, int(floor(miny))), mini(h - 1, int(ceil(maxy))) + 1):
		var yc := float(y) + 0.5
		var xs: Array[float] = []
		for i in n:
			var a := q[i]
			var b := q[(i + 1) % n]
			if (a.y <= yc and b.y > yc) or (b.y <= yc and a.y > yc):
				xs.append(a.x + (yc - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var sx := int(ceil(xs[k] - 0.5))
			var ex := int(floor(xs[k + 1] - 0.5))
			for x in range(sx, ex + 1):
				var c := col
				if do_shade:
					var t := ((float(x) + 0.5 - minx) / bw + (yc - miny) / bh) * 0.5
					if t < 0.27:
						c = light
					elif t > 0.78:
						c = dark
				put(x, y, c)
				any = true
			k += 2
	if not any:
		put(int(floor((minx + maxx) * 0.5)), int(floor((miny + maxy) * 0.5)), col)

## Dodaje czarny kontur (puste / półprzezroczyste komórki sąsiadujące z pełnymi) i wgrywa teksturę.
func finish(outline: bool = true) -> ImageTexture:
	if outline and _bx1 >= 0:
		var x0 := maxi(0, _bx0 - 1)
		var x1 := mini(w - 1, _bx1 + 1)
		var y0 := maxi(0, _by0 - 1)
		var y1 := mini(h - 1, _by1 + 1)
		var mark: Array = []
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var i := y * w + x
				if _kind[i] == 2:
					continue
				if (x > 0 and _kind[i - 1] == 2) or (x < w - 1 and _kind[i + 1] == 2) or (y > 0 and _kind[i - w] == 2) or (y < h - 1 and _kind[i + w] == 2):
					mark.append(i)
		for i in mark:
			_write(i, OUTLINE, 2)
	_img.set_data(w, h, false, Image.FORMAT_RGBA8, _bytes)
	texture.update(_img)
	return texture

## Rysuje gotowy sprite w danym węźle (lokalny układ współrzędnych węzła).
func draw_on(node: CanvasItem) -> void:
	node.draw_texture_rect(texture, Rect2(origin, Vector2(w, h) * cell), false)

## Sprite2D z gotową teksturą (statyczne rekwizyty).
func to_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.position = origin
	s.scale = Vector2(cell, cell)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s
