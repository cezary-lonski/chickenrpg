class_name UiChickenGauge
extends Control
## Miernik w kształcie kurczaka (pixel art, jak postacie w grze), pusty w środku: widać tylko kontur i oko,
## a wnętrze wypełnia się od dołu kolorem (życie / energia). Wartość 0..1 jak w UiBar.

const W := 56
const H := 56
const S := 2.0                     # skala pikseli
const K := Color(0.05, 0.04, 0.07)

var value := 1.0
var text := "":
	set(v):
		text = v
		if _label:
			_label.text = v
var fill_col := Color(0.85, 0.28, 0.25)
var hi_col := Color(0.95, 0.5, 0.45)
var flipped := false

var _tex: ImageTexture
var _spans: Array = []              # na wiersz: Array of Vector2i (x0, x1)
var _label: Label
var _shown := 1.0

func _init() -> void:
	custom_minimum_size = Vector2(W * S, H * S)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ready() -> void:
	_build()
	_label = UiKit.label(text, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_label.position = Vector2(0, 34.0 * S)
	_label.size = Vector2(46.0 * S, 24)
	if flipped:
		_label.position.x = (W - 46.0) * S
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)

func set_fill(c: Color) -> void:
	fill_col = c

func set_value(v: float) -> void:
	value = clampf(v, 0.0, 1.0)

func _process(delta: float) -> void:
	_shown = move_toward(_shown, value, delta * 1.6)
	queue_redraw()

# ----------------------------------------------------------- rasteryzacja ---

func _disc(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color, mask: Array = []) -> void:
	for y in range(int(floor(cy - ry)), int(cy + ry) + 1):
		for x in range(int(floor(cx - rx)), int(cx + rx) + 1):
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and x >= 0 and y >= 0 and x < W and y < H:
				img.set_pixel(x, y, col)
				if not mask.is_empty():
					mask[y * W + x] = true

func _tri(img: Image, p: Array, col: Color, mask: Array = []) -> void:
	var minx := 999.0
	var maxx := -999.0
	var miny := 999.0
	var maxy := -999.0
	for q: Vector2 in p:
		minx = minf(minx, q.x)
		maxx = maxf(maxx, q.x)
		miny = minf(miny, q.y)
		maxy = maxf(maxy, q.y)
	for y in range(int(miny), int(maxy) + 1):
		for x in range(int(minx), int(maxx) + 1):
			var pt := Vector2(float(x) + 0.5, float(y) + 0.5)
			var s1: float = (p[1].x - p[0].x) * (pt.y - p[0].y) - (p[1].y - p[0].y) * (pt.x - p[0].x)
			var s2: float = (p[2].x - p[1].x) * (pt.y - p[1].y) - (p[2].y - p[1].y) * (pt.x - p[1].x)
			var s3: float = (p[0].x - p[2].x) * (pt.y - p[2].y) - (p[0].y - p[2].y) * (pt.x - p[2].x)
			var neg: bool = s1 < 0.0 or s2 < 0.0 or s3 < 0.0
			var pos: bool = s1 > 0.0 or s2 > 0.0 or s3 > 0.0
			if not (neg and pos) and x >= 0 and y >= 0 and x < W and y < H:
				img.set_pixel(x, y, col)
				if not mask.is_empty():
					mask[y * W + x] = true

func _rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x >= 0 and y >= 0 and x < W and y < H:
				img.set_pixel(x, y, col)

func _build() -> void:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var body: Array = []
	body.resize(W * H)
	body.fill(false)
	var tmp := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_disc(tmp, 24, 35, 17, 13, Color.WHITE, body)
	_tri(tmp, [Vector2(8, 32), Vector2(0, 20), Vector2(12, 25)], Color.WHITE, body)
	_disc(tmp, 38, 20, 8, 8, Color.WHITE, body)
	for y in range(24, 34):
		for x in range(30, 40):
			body[y * W + x] = true
	# nogi, grzebień, dziób i dzwonek (z konturem)
	var leg := Color(0.94, 0.7, 0.16)
	_rect(img, 18, 47, 3, 7, leg)
	_rect(img, 28, 47, 3, 7, leg)
	_rect(img, 15, 53, 7, 2, leg)
	_rect(img, 25, 53, 7, 2, leg)
	var red := Color(0.85, 0.28, 0.25)
	_disc(img, 35, 10, 3, 3, red)
	_disc(img, 39, 8, 3, 4, red)
	_disc(img, 43, 10, 3, 3, red)
	_tri(img, [Vector2(44, 19), Vector2(54, 22), Vector2(44, 26)], Color(0.94, 0.54, 0.16))
	_disc(img, 43, 28, 2, 3, red)
	var copy := img.duplicate()
	for y in H:
		for x in W:
			if copy.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < W and ny < H and copy.get_pixel(nx, ny).a > 0.0:
					img.set_pixel(x, y, K)
					break
	# krawędź ciała (2 px), wnętrze zostaje puste i jest wypełniane miernikiem
	_spans.clear()
	_spans.resize(H)
	for y in H:
		var row: Array = []
		var start := -1
		for x in W:
			var inside: bool = body[y * W + x]
			if inside:
				var edge := false
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx < 0 or ny < 0 or nx >= W or ny >= H or not body[ny * W + nx]:
						edge = true
						break
				if edge:
					img.set_pixel(x, y, K)
					inside = false
			if inside:
				if start < 0:
					start = x
			elif start >= 0:
				row.append(Vector2i(start, x - 1))
				start = -1
		if start >= 0:
			row.append(Vector2i(start, W - 1))
		_spans[y] = row
	# oko i brew
	_rect(img, 36, 17, 5, 5, Color.WHITE)
	_rect(img, 38, 18, 3, 4, K)
	_rect(img, 34, 14, 8, 1, K)
	_rect(img, 36, 15, 6, 1, K)
	_tex = ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ rysunek ---

func _draw() -> void:
	if _tex == null:
		return
	if flipped:
		draw_set_transform(Vector2(float(W) * S, 0.0), 0.0, Vector2(-1.0, 1.0))
	var level := int(round(46.0 - (46.0 - 12.0) * _shown))
	var empty := Color(0.08, 0.05, 0.03, 0.4)
	for y in H:
		for sp in _spans[y]:
			var col := empty
			if y >= level:
				col = hi_col if y == level else fill_col
			draw_rect(Rect2(float(sp.x) * S, float(y) * S, float(sp.y - sp.x + 1) * S, S), col)
	draw_texture_rect(_tex, Rect2(0.0, 0.0, float(W) * S, float(H) * S), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
