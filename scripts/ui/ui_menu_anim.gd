class_name UiMenuAnim
extends Control
## Animowane tło menu startowego (pixel art): płyną chmury, lecą ptaki, powiewa flaga na zamku, dymi komin,
## błyska rzeka i latają świetliki. Rysowane w siatce 320×180 powiększonej 4×, na wierzchu statycznego tła.
## Animacje można wyłączyć w ustawieniach („Animacje”).

const PX := 4.0
const CLOUDS := [[10.0, 24.0, 1.0, 2.2], [130.0, 16.0, 0.8, 1.4], [95.0, 40.0, 0.6, 0.9], [250.0, 28.0, 0.7, 1.8], [200.0, 10.0, 0.5, 1.1]]
const BIRDS := [[0.0, 30.0], [16.0, 26.0], [28.0, 34.0]]

var _t := 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if GameState.setting("animations"):
		_t += delta
		queue_redraw()

func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x) * PX, floorf(y) * PX, w * PX, h * PX), c)

func _cloud(x: float, y: float, s: float) -> void:
	var col := Color(1, 1, 1, 0.92)
	for e in [[0, 0, 7], [8, -3, 8], [17, 0, 7], [8, 2, 9]]:
		var r: float = float(e[2]) * s
		var cx: float = x + float(e[0]) * s
		var cy: float = y + float(e[1]) * s
		for yy in range(int(-r * 0.55), int(r * 0.55) + 1):
			for xx in range(int(-r), int(r) + 1):
				var a := float(xx) / r
				var b := float(yy) / (r * 0.55)
				if a * a + b * b <= 1.0:
					_r(cx + float(xx), cy + float(yy), 1, 1, col)

func _draw() -> void:
	if not GameState.setting("animations"):
		return
	var t := _t
	# chmury
	for c in CLOUDS:
		var x := fposmod(float(c[0]) + t * float(c[3]) * 2.5, 380.0) - 40.0
		_cloud(x, float(c[1]), float(c[2]))
	# ptaki
	for b in BIRDS:
		var bx := fposmod(t * 14.0 + float(b[0]) * 3.0, 360.0) - 20.0
		var by := float(b[1]) + sin(t * 2.0 + float(b[0])) * 3.0
		var up := sin(t * 10.0 + float(b[0])) > 0.0
		var dark := Color(0.16, 0.13, 0.19)
		_r(bx, by, 3, 1, dark)
		_r(bx + 4.0, by, 3, 1, dark)
		_r(bx + 2.0, by - (1.0 if up else 0.0), 1, 1, dark)
		_r(bx + 5.0, by + (0.0 if up else -1.0), 1, 1, dark)
	# flaga na zamku
	for i in 7:
		_r(257.0 + float(i), 30.0 + roundf(sin(t * 6.0 + float(i) * 0.8) * 1.5), 1, 3, Color(0.88, 0.71, 0.23))
	# okna zamku migają
	if int(t * 2.0) % 3 != 0:
		_r(229.0, 70.0, 2, 4, Color(1.0, 0.85, 0.42))
	if int(t * 3.0) % 4 != 0:
		_r(283.0, 70.0, 2, 4, Color(1.0, 0.85, 0.42))
	# dym z komina wioski
	for i in 5:
		var k := fposmod(t * 0.6 + float(i) / 5.0, 1.0)
		var sx := 90.0 + k * 10.0 + sin(t + float(i)) * 2.0
		var sy := 108.0 - k * 22.0
		var rr := 1.5 + k * 1.5
		draw_circle(Vector2(sx, sy) * PX, rr * PX, Color(0.96, 0.93, 0.96, (1.0 - k) * 0.85))
	# połysk rzeki
	for i in 46:
		var rx := 160.0 + fposmod(float(i * 37) + floorf(t * 12.0), 150.0)
		var ry := 138.0 + floorf((rx - 160.0) / 10.0) + float(i % 3) - 1.0
		if int(t * 4.0 + float(i)) % 3 == 0:
			_r(rx, ry, 2, 1, Color(0.85, 0.95, 0.98))
	# świetliki
	for i in 22:
		var ph := float(i) * 0.7
		if sin(t * 2.0 + ph) > 0.2:
			var fx := fposmod(float((i * 53) % 320) + sin(t + ph) * 4.0, 320.0)
			var fy := 150.0 + float((i * 17) % 28) + cos(t * 1.3 + ph) * 3.0
			_r(fx, fy, 1, 1, Color(1.0, 0.96, 0.63))
