class_name MerchantStall
extends PixelNode

var accent := Color(0.95, 0.85, 0.45)
var _t := 0.0
var _glint := 0.0
var _rng := RandomNumberGenerator.new()

func setup(p_accent: Color, seed_i: int = 1) -> void:
	accent = p_accent
	_rng.seed = seed_i
	queue_redraw()

func _ready() -> void:
	if _rng.seed == 0:
		_rng.seed = 1
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	_glint += delta
	queue_redraw()

func _init() -> void:
	px_origin = Vector2(-124, -170)
	px_w = 62
	px_h = 48

func _draw() -> void:
	_pbegin()
	var wood := Color(0.44, 0.3, 0.18)
	var wood_dark := wood.darkened(0.22)
	var cloth_a := accent
	var cloth_b := Color(0.78, 0.22, 0.22)
	var sway := sin(_t * 1.6) * 2.2
	var sway2 := sin(_t * 1.6 + 1.1) * 1.5
	var base := Vector2(0, 0)

	_pp(_ellipse(base + Vector2(0, -4), Vector2(92, 20)), Color(0, 0, 0, 0.2))

	_pl(base + Vector2(-74, -6), base + Vector2(-74, -112), wood_dark, 7.0, true)
	_pl(base + Vector2(74, -6), base + Vector2(74, -112), wood_dark, 7.0, true)
	_pl(base + Vector2(-70, -64), base + Vector2(70, -64), wood, 5.0, true)

	var table := _poly([
		base + Vector2(-82, -58), base + Vector2(82, -58),
		base + Vector2(72, -42), base + Vector2(-72, -42),
	])
	_pp(table, wood)
	_pl(base + Vector2(-74, -42), base + Vector2(-66, 2), wood_dark, 6.0, true)
	_pl(base + Vector2(74, -42), base + Vector2(66, 2), wood_dark, 6.0, true)

	_draw_awning(base, cloth_a, cloth_b, sway)

	_draw_crate(base + Vector2(-58, -8), 22.0, wood, wood_dark)
	_draw_crate(base + Vector2(-36, -20), 16.0, wood.lightened(0.06), wood_dark)
	_draw_crate(base + Vector2(52, -10), 20.0, wood, wood_dark)
	_draw_sack(base + Vector2(28, -16))
	_draw_pot(base + Vector2(8, -24))
	_draw_coin_pile(base + Vector2(-18, -42))

	var swing := sin(_t * 2.1) * 0.12
	_draw_lantern(base + Vector2(54, -100) + Vector2(sin(_t * 2.1) * 3.0, 0), swing)

	var sign_pos := base + Vector2(0, -126 + sway2 * 0.4)
	_pl(base + Vector2(0, -112), base + Vector2(0, -124), wood_dark, 3.0, true)
	var bw := 62.0
	var bh := 22.0
	_pp(_poly([
		sign_pos + Vector2(-bw, -bh), sign_pos + Vector2(bw, -bh),
		sign_pos + Vector2(bw, bh), sign_pos + Vector2(-bw, bh),
	]), wood_dark)
	_pr(Rect2(sign_pos + Vector2(-bw + 4, -bh + 4), Vector2(bw * 2.0 - 8, bh * 2.0 - 8)), accent.darkened(0.12))
	_pl(base + Vector2(-bw - 6, -bh - 4), base + Vector2(-74, -118), Color(0.35, 0.35, 0.4), 2.0, true)
	_pl(base + Vector2(bw + 6, -bh - 4), base + Vector2(74, -118), Color(0.35, 0.35, 0.4), 2.0, true)
	_pflush()
	var font := ThemeDB.fallback_font
	if font != null:
		var txt := "KRAM"
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, sign_pos + Vector2(-w * 0.5, 5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.12, 0.08, 0.05))

func _draw_awning(base: Vector2, a: Color, b: Color, sway: float) -> void:
	var top_l := base + Vector2(-92, -124)
	var top_r := base + Vector2(92, -124)
	var low_l := base + Vector2(-106, -90 + sway)
	var low_r := base + Vector2(106, -90 - sway)
	var cols := [a, b]
	var segs := 8
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var p0t := top_l.lerp(top_r, t0)
		var p1t := top_l.lerp(top_r, t1)
		var p0b := low_l.lerp(low_r, t0)
		var p1b := low_l.lerp(low_r, t1)
		var col: Color = cols[i % 2]
		if i % 2 == 1:
			col = col.darkened(0.08)
		_pp(_poly([p0t, p1t, p1b, p0b]), col)
	var hem_a := low_l + Vector2(0, 4)
	var hem_b := low_r + Vector2(0, 4)
	_pl(low_l, low_r, a.darkened(0.25), 4.0, true)
	for i in range(1, 8):
		var t := float(i) / 8.0
		var p := low_l.lerp(low_r, t)
		_pl(p, p + Vector2(0, 11), a.darkened(0.18), 2.0, true)
		_pp(_ellipse(p + Vector2(0, 13), Vector2(4, 3), 8), a)
	_pl(top_l, top_r, a.darkened(0.25), 4.0, true)
	_pl(hem_a, hem_b, Color(0, 0, 0, 0.18), 1.0, true)

func _draw_crate(c: Vector2, s: float, wood: Color, dark: Color) -> void:
	_pr(Rect2(c + Vector2(-s, -s), Vector2(s * 2.0, s * 2.0)), wood)
	_pr(Rect2(c + Vector2(-s, -s), Vector2(s * 2.0, s * 2.0)), dark, false, 2.0)
	_pl(c + Vector2(-s, -s), c + Vector2(s, s), dark, 2.0, true)
	_pl(c + Vector2(s, -s), c + Vector2(-s, s), dark, 2.0, true)

func _draw_sack(c: Vector2) -> void:
	var col := Color(0.72, 0.62, 0.4)
	_pp(_ellipse(c + Vector2(0, -6), Vector2(12, 14), 12), col)
	_pl(c + Vector2(-4, -18), c + Vector2(4, -18), col.darkened(0.25), 3.0, true)
	_pl(c + Vector2(-11, -3), c + Vector2(11, -3), col.darkened(0.12), 1.5, true)

func _draw_pot(c: Vector2) -> void:
	var col := Color(0.55, 0.34, 0.24)
	_pp(_ellipse(c + Vector2(0, -6), Vector2(10, 12), 12), col)
	_pr(Rect2(c + Vector2(-7, -20), Vector2(14, 6)), col.lightened(0.16))
	_pp(_ellipse(c + Vector2(0, -20), Vector2(6, 2.5), 10), Color(0.3, 0.18, 0.12))

func _draw_coin_pile(c: Vector2) -> void:
	for i in 5:
		var off := Vector2(float(i % 3) * 4.0 - 4.0 + sin(float(i) * 2.0) * 2.0, -float(i) * 2.0)
		var glow := 0.55 + 0.45 * sin(_glint * 3.0 + float(i))
		_pc(c + off, 3.2, accent.lightened(0.15))
		_pc(c + off + Vector2(-0.8, -0.8), 1.0, Color(1, 1, 1, glow))

func _draw_lantern(c: Vector2, ang: float) -> void:
	_pl(c + Vector2(0, -18), c + Vector2(0, 0), Color(0.2, 0.2, 0.24), 2.0, true)
	_xf_set(c, ang, Vector2.ONE)
	var glow := 0.6 + 0.4 * sin(_t * 4.5)
	_pc(Vector2(0, 9), 18.0, Color(1, 0.78, 0.3, 0.12 * glow))
	_pr(Rect2(Vector2(-7, 0), Vector2(14, 18)), Color(0.16, 0.14, 0.12))
	_pr(Rect2(Vector2(-4, 3), Vector2(8, 12)), Color(1, 0.83, 0.4, 0.7 + 0.3 * glow))
	_pl(Vector2(-7, 0), Vector2(7, 0), Color(0.2, 0.18, 0.15), 2.0, true)
	_pl(Vector2(-7, 18), Vector2(7, 18), Color(0.2, 0.18, 0.15), 2.0, true)
	_xf_set(Vector2.ZERO, 0.0, Vector2.ONE)

func _ellipse(c: Vector2, r: Vector2, steps: int = 16) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		out.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return out

func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p)
	return out
