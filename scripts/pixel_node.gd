class_name PixelNode
extends Node2D
## Węzeł, którego _draw() trafia do siatki pikseli (pixel art z konturem) zamiast rysować
## gładkie kształty. Podklasy ustawiają px_* w _init(), wołają _pbegin() na początku _draw()
## i _pflush() na końcu, a zamiast draw_* używają _pp / _pc / _pl / _pr / _pa / _xf_set.

const OUTLINE := Color(0.05, 0.04, 0.07, 1.0)

var px_cell := 4.0
var px_w := 40
var px_h := 40
var px_origin := Vector2(-80, -140)
var px_every := 0.05

var _tex: ImageTexture
var _img: Image
var _bytes := PackedByteArray()
var _kind := PackedByteArray()
var _xf := Transform2D.IDENTITY
var _painting := false
var _rb := 0.0
var _bx0 := 0
var _bx1 := -1
var _by0 := 0
var _by1 := -1

func _pbegin() -> void:
	_xf = Transform2D.IDENTITY
	var dt := get_process_delta_time()
	_rb -= dt
	if _img == null:
		_bytes.resize(px_w * px_h * 4)
		_kind.resize(px_w * px_h)
		_img = Image.create(px_w, px_h, false, Image.FORMAT_RGBA8)
		_tex = ImageTexture.create_from_image(_img)
		_rb = 0.0
	_painting = _rb <= 0.0
	if _painting:
		_rb = px_every
		_bytes.fill(0)
		_kind.fill(0)
		_bx0 = px_w
		_bx1 = -1
		_by0 = px_h
		_by1 = -1

func _pflush() -> void:
	if _painting:
		_outline_pass()
		_img.set_data(px_w, px_h, false, Image.FORMAT_RGBA8, _bytes)
		_tex.update(_img)
		_painting = false
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect(_tex, Rect2(px_origin, Vector2(px_w, px_h) * px_cell), false)

func _outline_pass() -> void:
	if _bx1 < 0:
		return
	var x0 := maxi(0, _bx0 - 1)
	var x1 := mini(px_w - 1, _bx1 + 1)
	var y0 := maxi(0, _by0 - 1)
	var y1 := mini(px_h - 1, _by1 + 1)
	var mark: Array = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var i := y * px_w + x
			if _kind[i] == 2:
				continue
			if (x > 0 and _kind[i - 1] == 2) or (x < px_w - 1 and _kind[i + 1] == 2) or (y > 0 and _kind[i - px_w] == 2) or (y < px_h - 1 and _kind[i + px_w] == 2):
				mark.append(i)
	for i in mark:
		_write(i, OUTLINE, 2)

func _write(i: int, col: Color, kind: int) -> void:
	var o := i * 4
	_bytes[o] = int(col.r * 255.0 + 0.5)
	_bytes[o + 1] = int(col.g * 255.0 + 0.5)
	_bytes[o + 2] = int(col.b * 255.0 + 0.5)
	_bytes[o + 3] = int(col.a * 255.0 + 0.5)
	_kind[i] = kind

func _put(x: int, y: int, col: Color) -> void:
	if x < 0 or y < 0 or x >= px_w or y >= px_h:
		return
	var i := y * px_w + x
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

func _xf_set(pos: Vector2, rot: float, scl: Vector2) -> void:
	_xf = Transform2D(rot, scl, 0.0, pos)

func _to_cells(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var w := _xf * p
		out.append(Vector2((w.x - px_origin.x) / px_cell, (w.y - px_origin.y) / px_cell))
	return out

func _fill_cells(q: PackedVector2Array, col: Color, shade: bool) -> void:
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
	for y in range(maxi(0, int(floor(miny))), mini(px_h - 1, int(ceil(maxy))) + 1):
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
				_put(x, y, c)
				any = true
			k += 2
	if not any:
		_put(int(floor((minx + maxx) * 0.5)), int(floor((miny + maxy) * 0.5)), col)

func _pp(pts: PackedVector2Array, col: Color) -> void:
	if _painting:
		_fill_cells(_to_cells(pts), col, true)

func _pc(c: Vector2, r: float, col: Color) -> void:
	if not _painting:
		return
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_fill_cells(_to_cells(pts), col, r >= px_cell * 2.0)

func _pl(a: Vector2, b: Vector2, col: Color, width: float = 1.0, _aa: bool = false) -> void:
	if not _painting:
		return
	var d := b - a
	if d.length() < 0.01:
		return
	var nrm := Vector2(-d.y, d.x).normalized() * maxf(width, px_cell * 0.95) * 0.5
	_fill_cells(_to_cells(PackedVector2Array([a + nrm, b + nrm, b - nrm, a - nrm])), col, false)

func _pr(r: Rect2, col: Color, filled: bool = true, width: float = 1.0) -> void:
	if not _painting:
		return
	if filled:
		_fill_cells(_to_cells(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])), col, false)
	else:
		var tl := r.position
		var tr := Vector2(r.end.x, r.position.y)
		var br := r.end
		var bl := Vector2(r.position.x, r.end.y)
		_pl(tl, tr, col, width)
		_pl(tr, br, col, width)
		_pl(br, bl, col, width)
		_pl(bl, tl, col, width)

func _pa(c: Vector2, r: float, a0: float, a1: float, pts: int, col: Color, width: float = 1.0, _aa: bool = false) -> void:
	if not _painting:
		return
	var prev := c + Vector2(cos(a0), sin(a0)) * r
	for i in range(1, pts + 1):
		var a := lerpf(a0, a1, float(i) / float(pts))
		var cur := c + Vector2(cos(a), sin(a)) * r
		_pl(prev, cur, col, width)
		prev = cur
