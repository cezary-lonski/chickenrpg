extends Node
## Fx — Efekty: hitstop, trzęsienie kamery, liczby obrażeń, rozbłyski, pierścienie,
## wybuchy cząstek i przejścia ekranowe.

var world: Node2D = null
var camera: Camera2D = null

var _shake_amp := 0.0
var _shake_time := 0.0
var _shake_decay := 1.0
var _hitstop_left := 0.0
var _flash_layer: CanvasLayer
var _flash_rect: ColorRect
var _fade_rect: ColorRect
var _fading := false
var _fade_target := 0.0
var _fade_speed := 1.0
var _rng := RandomNumberGenerator.new()
var enabled_shake := true

# -------------------------------------------------------------------- init ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 90
	add_child(_flash_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_layer.add_child(_fade_rect)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_layer.add_child(_flash_rect)

func set_world(w: Node2D, cam: Camera2D = null) -> void:
	world = w
	camera = cam

func clear_world() -> void:
	world = null
	camera = null

# ---------------------------------------------------------------- hitstop ---

func hitstop(duration: float) -> void:
	# Wyłączone: spowolnienie czasu podczas trafień/zabić dawało efekt "lag".
	# Zachowujemy funkcję jako no-op, żeby istniejące wywołania nie psuły gry.
	pass

func _process(delta: float) -> void:
	if _shake_time > 0.0 and camera and enabled_shake:
		_shake_time -= delta
		var k := clampf(_shake_time / _shake_decay, 0.0, 1.0)
		camera.offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake_amp * k * k
		if _shake_time <= 0.0:
			camera.offset = Vector2.ZERO
	if _fading:
		var c := _fade_rect.color
		c.a = move_toward(c.a, _fade_target, _fade_speed * delta)
		_fade_rect.color = c
		if is_equal_approx(c.a, _fade_target):
			_fading = false

# ------------------------------------------------------------------- shake ---

func shake(amp: float, time: float = 0.28) -> void:
	if not enabled_shake or not GameState.setting("shake"):
		return
	_shake_amp = maxf(_shake_amp, amp)
	_shake_time = maxf(_shake_time, time)
	_shake_decay = time

# ------------------------------------------------------------------- flash ---

func flash(color: Color, duration: float = 0.12, strength: float = 0.55) -> void:
	_flash_rect.color = Color(color.r, color.g, color.b, strength)
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color", Color(color.r, color.g, color.b, 0.0), duration)

func fade_to(alpha: float, speed: float = 2.5) -> void:
	_fade_target = clampf(alpha, 0.0, 1.0)
	_fade_speed = speed
	_fading = true

func fade_out_and(callback: Callable, speed: float = 2.5) -> void:
	fade_to(1.0, speed)
	await get_tree().create_timer(1.0 / speed, true, false, true).timeout
	callback.call()
	fade_to(0.0, speed)

# ------------------------------------------------------------- liczby obrażeń ---

func damage_number(pos: Vector2, amount: float, color: Color = Color(1, 1, 0.85), style: String = "normal") -> void:
	if world == null or not is_instance_valid(world):
		return
	var t := FloatText.new()
	t.global_position = pos + Vector2(_rng.randf_range(-8, 8), -10)
	t.text = str(int(round(amount)))
	t.color = color
	t.style = style
	world.add_child(t)

func popup(pos: Vector2, text: String, color: Color) -> void:
	if world == null or not is_instance_valid(world):
		return
	var t := FloatText.new()
	t.global_position = pos
	t.text = text
	t.color = color
	t.style = "popup"
	world.add_child(t)

# ---------------------------------------------------------------- efekty 2D ---

func burst(pos: Vector2, color: Color, count: int = 12, speed: float = 260.0, size: float = 3.0, life: float = 0.4) -> void:
	if world == null or not is_instance_valid(world):
		return
	var p := ParticleBurst.new()
	p.global_position = pos
	p.color = color
	p.count = count
	p.speed = speed
	p.p_size = size
	p.life = life
	world.add_child(p)

func ring(pos: Vector2, color: Color, radius: float = 60.0, life: float = 0.3, width: float = 4.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var r := Ring.new()
	r.global_position = pos
	r.color = color
	r.radius = radius
	r.life = life
	r.width = width
	world.add_child(r)

func slash(pos: Vector2, facing: float, color: Color = Color(1, 1, 1, 0.9), scale_f: float = 1.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var s := Slash.new()
	s.global_position = pos
	s.facing = facing
	s.color = color
	s.scl = scale_f
	world.add_child(s)

func spin_arc(pos: Vector2, color: Color, radius: float = 68.0, angle: float = 0.0, life: float = 0.22, width: float = 5.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var s := SpinArc.new()
	s.global_position = pos
	s.color = color
	s.radius = radius
	s.angle = angle
	s.life = life
	s.width = width
	world.add_child(s)

func sparkle(pos: Vector2, color: Color) -> void:
	if world == null or not is_instance_valid(world):
		return
	var s := Sparkle.new()
	s.global_position = pos
	s.color = color
	world.add_child(s)

func text_puff(pos: Vector2, color: Color) -> void:
	burst(pos, color, 8, 120.0, 2.0, 0.3)


# -------------------------------------------------- animacje umiejętności ---
## Efekty w stylu pixel art (kwadratowe komórki 4 px z ciemnym konturem).

func _px_add(node: Node2D, pos: Vector2) -> void:
	if world == null or not is_instance_valid(world):
		node.queue_free()
		return
	node.global_position = pos
	world.add_child(node)

## Znak przywołania pod stopami — odpala się przy każdej umiejętności.
func cast_glyph(pos: Vector2, color: Color) -> void:
	var n := PxRing.new()
	n.color = color
	n.radius = 34.0
	n.life = 0.38
	n.squash = 0.45
	n.spin = 3.0
	n.shrink = true
	_px_add(n, pos)

func pixel_ring(pos: Vector2, color: Color, radius: float = 90.0, life: float = 0.35, squash: float = 1.0) -> void:
	var n := PxRing.new()
	n.color = color
	n.radius = radius
	n.life = life
	n.squash = squash
	_px_add(n, pos)

## Unoszące się znaczki: "arrow" (wzmocnienie), "plus" (leczenie), "diamond" (tarcza), "paw" (pupil).
func motes(pos: Vector2, color: Color, kind: String = "plus", count: int = 10, spread: float = 40.0, life: float = 0.9) -> void:
	var n := PxMotes.new()
	n.color = color
	n.kind = kind
	n.count = count
	n.spread = spread
	n.life = life
	_px_add(n, pos)

func muzzle(pos: Vector2, dir: Vector2, color: Color) -> void:
	var n := PxMuzzle.new()
	n.color = color
	n.dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	_px_add(n, pos)

func crosshair(pos: Vector2, color: Color = Color(1.0, 0.3, 0.3)) -> void:
	var n := PxCross.new()
	n.color = color
	_px_add(n, pos)

func speed_lines(pos: Vector2, dir: Vector2, color: Color) -> void:
	var n := PxSpeed.new()
	n.color = color
	n.dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	_px_add(n, pos)

func big_slash(pos: Vector2, dir: Vector2, color: Color, radius: float = 96.0) -> void:
	var n := PxSlash.new()
	n.color = color
	n.angle = dir.angle() if dir.length() > 0.01 else 0.0
	n.radius = radius
	_px_add(n, pos)

func flames(pos: Vector2, radius: float, color: Color, life: float = 0.9) -> void:
	var n := PxFlames.new()
	n.color = color
	n.radius = radius
	n.life = life
	_px_add(n, pos)

# ============================================================ wnętrza ========

class FloatText extends Node2D:
	var text := "0"
	var color := Color(1, 1, 1)
	var style := "normal"
	var _t := 0.0
	var _life := 0.85
	var _vel := Vector2(0, -70)
	var _scale := 1.0

	func _ready() -> void:
		z_index = 101
		z_as_relative = false
		scale = Vector2(0.4, 0.4)
		_vel = Vector2(randf_range(-30, 30), -randf_range(70, 100))

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / _life, 0.0, 1.0)
		position += _vel * delta
		_vel.y += 240.0 * delta
		_vel.x *= 0.94
		var pop := 1.0 + 0.35 * exp(-_t * 14.0)
		scale = Vector2(pop, pop)
		modulate.a = 1.0 - k * k
		if _t >= _life:
			queue_free()

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if font == null:
			return
		var size := 20
		if style == "crit":
			size = 30
		elif style == "popup":
			size = 18
		elif style == "player":
			size = 22
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos := Vector2(-w * 0.5, 0)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.85 * modulate.a))
		var c := color
		c.a = modulate.a
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)

class Ring extends Node2D:
	var color := Color(1, 1, 1)
	var radius := 60.0
	var life := 0.3
	var width := 4.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / life, 0.0, 1.0)
		var r := radius * (0.25 + 0.75 * sqrt(k))
		var a := (1.0 - k) * 0.9
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(color.r, color.g, color.b, a), width * (1.0 - k * 0.6), true)

class Slash extends Node2D:
	var facing := 1.0
	var color := Color(1, 1, 1)
	var scl := 1.0
	var _t := 0.0
	var _life := 0.18

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= _life:
			queue_free()

	func _draw() -> void:
		var k := clampf(_t / _life, 0.0, 1.0)
		var a := (1.0 - k) * 0.95
		var r := 46.0 * scl
		var start := deg_to_rad(-64.0)
		var end := deg_to_rad(58.0)
		var sweep := start + (end - start) * ease(k, 0.35)
		var pts := PackedVector2Array()
		for i in 14:
			var ang := lerpf(start, sweep, float(i) / 13.0)
			pts.append(Vector2(cos(ang) * r, sin(ang) * r))
		var prev := pts
		var thick := 7.0 * scl * (1.0 - k * 0.4)
		for i in pts.size():
			var outer := pts[i]
			var inner := outer.normalized() * (r - thick)
			draw_line(inner, outer, Color(color.r, color.g, color.b, a), 2.0, true)
		# biała iskra na czubku
		draw_circle(pts[pts.size() - 1], 3.5 * scl * (1.0 - k), Color(1, 1, 1, a))

class SpinArc extends Node2D:
	var color := Color(1, 1, 1)
	var radius := 68.0
	var angle := 0.0
	var life := 0.22
	var width := 5.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 82

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= life:
			queue_free()

	func _draw() -> void:
		var k := clampf(_t / life, 0.0, 1.0)
		var a := (1.0 - k) * 0.95
		var a0 := angle + k * 1.1
		var r := radius * (1.0 + k * 0.08)
		draw_arc(Vector2.ZERO, r, a0, a0 + 1.9, 20, Color(color.r, color.g, color.b, a), width * (1.0 - k * 0.55), true)
		draw_arc(Vector2.ZERO, r - width * 1.2, a0 + 0.2, a0 + 1.6, 16, Color(1.0, 0.9, 0.7, a * 0.45), 1.5, true)
		var tip := Vector2(cos(a0 + 1.9), sin(a0 + 1.9)) * r
		draw_circle(tip, width * 0.9 * (1.0 - k), Color(1.0, 0.95, 0.8, a))

class ParticleBurst extends Node2D:
	var color := Color(1, 1, 1)
	var count := 12
	var speed := 260.0
	var p_size := 3.0
	var life := 0.4
	var _t := 0.0
	var _parts: Array = []

	func _ready() -> void:
		z_index = 80
		for i in count:
			var a := randf() * TAU
			var v := speed * randf_range(0.35, 1.2)
			_parts.append({
				"p": Vector2.ZERO,
				"v": Vector2(cos(a) * v, sin(a) * v - speed * 0.25),
				"r": randf() * TAU,
				"rv": randf_range(-12, 12),
				"s": p_size * randf_range(0.6, 1.5),
			})

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / life, 0.0, 1.0)
		for d in _parts:
			d["v"].y += 900.0 * delta
			d["v"] *= 0.93
			d["p"] += d["v"] * delta
			d["r"] += d["rv"] * delta
		modulate.a = 1.0 - k * k
		queue_redraw()
		if _t >= life:
			queue_free()

	func _draw() -> void:
		for d in _parts:
			var s: float = d["s"]
			var r: float = d["r"]
			var c := color
			c.a *= 0.95
			draw_set_transform(d["p"], r, Vector2.ONE)
			draw_rect(Rect2(-s, -s, s * 2.0, s * 2.0), c)

class Sparkle extends Node2D:
	var color := Color(1, 1, 1)
	var _t := 0.0
	var _life := 0.4
	var _rays: Array = []

	func _ready() -> void:
		z_index = 85
		for i in 8:
			_rays.append({"a": TAU * float(i) / 8.0 + randf() * 0.3, "l": randf_range(10.0, 22.0)})

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= _life:
			queue_free()

	func _draw() -> void:
		var k := clampf(_t / _life, 0.0, 1.0)
		var a := (1.0 - k) * 0.9
		var c := Color(color.r, color.g, color.b, a)
		draw_line(Vector2(-26, 0), Vector2(26, 0), c, 2.0, true)
		draw_line(Vector2(0, -26), Vector2(0, 26), c, 2.0, true)
		for r in _rays:
			var dir: Vector2 = Vector2(cos(r["a"]), sin(r["a"])) * (r["l"] * (0.4 + k))
			draw_line(Vector2.ZERO, dir, c, 2.0, true)


# ------------------------------------------------ klasy efektów pikselowych ---
class PxBase extends Node2D:
	const OUT := Color(0.05, 0.04, 0.07, 0.95)
	var _cells: Array = []     # {p: Vector2, c: Color, s: float}

	func _ready() -> void:
		z_index = 90
		z_as_relative = false

	func _snap(p: Vector2) -> Vector2:
		return Vector2(roundf(p.x / 4.0) * 4.0, roundf(p.y / 4.0) * 4.0)

	func _sq(p: Vector2, c: Color, s: float = 4.0) -> void:
		_cells.append({"p": _snap(p), "c": c, "s": s})

	func _flush() -> void:
		for d in _cells:
			var s: float = d["s"]
			var o := Color(OUT.r, OUT.g, OUT.b, OUT.a * (d["c"] as Color).a)
			draw_rect(Rect2(d["p"] - Vector2(s, s) * 0.5 - Vector2(2, 2), Vector2(s + 4, s + 4)), o)
		for d in _cells:
			var s2: float = d["s"]
			draw_rect(Rect2(d["p"] - Vector2(s2, s2) * 0.5, Vector2(s2, s2)), d["c"])
		_cells.clear()

class PxRing extends PxBase:
	var color := Color(1, 1, 1)
	var radius := 80.0
	var life := 0.35
	var squash := 1.0
	var spin := 0.0
	var shrink := false
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / life, 0.0, 1.0)
		var r := radius * ((1.0 - k * 0.55) if shrink else (0.2 + 0.8 * sqrt(k)))
		var a := 1.0 - k * k
		var n := maxi(8, int(TAU * r / 9.0))
		for i in n:
			var ang := TAU * float(i) / float(n) + spin * _t
			var c := color.lightened(0.25 if i % 3 == 0 else 0.0)
			c.a = a
			_sq(Vector2(cos(ang) * r, sin(ang) * r * squash), c, 4.0 if i % 2 == 0 else 6.0)
		_flush()

class PxMotes extends PxBase:
	var color := Color(1, 1, 1)
	var kind := "plus"
	var count := 10
	var spread := 40.0
	var life := 0.9
	var _t := 0.0
	var _parts: Array = []

	func _ready() -> void:
		super._ready()
		for i in count:
			_parts.append({
				"x": randf_range(-spread, spread), "y": randf_range(-10.0, 18.0),
				"v": randf_range(36.0, 90.0), "d": randf_range(0.0, life * 0.5), "w": randf() * TAU,
			})

	func _shape() -> Array:
		match kind:
			"arrow": return [Vector2(0, -8), Vector2(-4, -4), Vector2(4, -4), Vector2(0, -4), Vector2(0, 0), Vector2(0, 4)]
			"diamond": return [Vector2(0, -6), Vector2(-5, 0), Vector2(5, 0), Vector2(0, 6), Vector2(0, 0)]
			"paw": return [Vector2(-5, -5), Vector2(0, -7), Vector2(5, -5), Vector2(0, 0), Vector2(-3, 3), Vector2(3, 3)]
		return [Vector2(0, -5), Vector2(0, 0), Vector2(0, 5), Vector2(-5, 0), Vector2(5, 0)]

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life * 1.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var shape := _shape()
		for p in _parts:
			var tt := _t - float(p["d"])
			if tt < 0.0:
				continue
			var k := clampf(tt / life, 0.0, 1.0)
			var pos := Vector2(float(p["x"]) + sin(tt * 4.0 + float(p["w"])) * 5.0, float(p["y"]) - float(p["v"]) * tt)
			var c := color
			c.a = 1.0 - k * k
			for o in shape:
				_sq(pos + o * 1.0, c, 3.0)
		_flush()

class PxMuzzle extends PxBase:
	var color := Color(1, 1, 1)
	var dir := Vector2.RIGHT
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 0.16:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / 0.16, 0.0, 1.0)
		var a := 1.0 - k
		for i in 5:
			var ang := dir.angle() + (float(i) - 2.0) * 0.5
			var len := (26.0 if i == 2 else 15.0) * (0.4 + k)
			var steps := int(len / 5.0)
			for j in range(1, steps + 1):
				var c := Color(1, 1, 0.9, a) if j == 1 else Color(color.r, color.g, color.b, a)
				_sq(Vector2(cos(ang), sin(ang)) * float(j) * 5.0, c, 4.0)
		_sq(Vector2.ZERO, Color(1, 1, 1, a), 8.0)
		_flush()

class PxCross extends PxBase:
	var color := Color(1.0, 0.3, 0.3)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 0.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / 0.5, 0.0, 1.0)
		var d := lerpf(40.0, 16.0, minf(k * 2.5, 1.0))
		var c := color
		c.a = 1.0 - maxf(0.0, k - 0.6) * 2.5
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for j in 3:
					_sq(Vector2(sx * (d - float(j) * 4.0), sy * d), c, 4.0)
					_sq(Vector2(sx * d, sy * (d - float(j) * 4.0)), c, 4.0)
		_sq(Vector2.ZERO, Color(1, 1, 1, c.a), 4.0)
		_flush()

class PxSpeed extends PxBase:
	var color := Color(1, 1, 1)
	var dir := Vector2.RIGHT
	var _t := 0.0
	var _lines: Array = []

	func _ready() -> void:
		super._ready()
		for i in 6:
			_lines.append({"o": randf_range(-26.0, 6.0), "l": randf_range(3.0, 7.0), "d": randf_range(0.0, 0.08)})

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 0.3:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var perp := Vector2(-dir.y, dir.x)
		for ln in _lines:
			var tt := _t - float(ln["d"])
			if tt < 0.0:
				continue
			var k := clampf(tt / 0.22, 0.0, 1.0)
			var c := color
			c.a = 1.0 - k
			var base := perp * float(ln["o"]) - dir * (10.0 + k * 40.0)
			for j in int(ln["l"]):
				_sq(base - dir * float(j) * 6.0, c, 4.0)
		_flush()

class PxSlash extends PxBase:
	var color := Color(1, 1, 1)
	var angle := 0.0
	var radius := 96.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 0.3:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / 0.3, 0.0, 1.0)
		var sweep := ease(minf(k * 2.0, 1.0), 0.4)
		var a0 := angle - 1.25
		var a1 := a0 + 2.5 * sweep
		var steps := 22
		var c := color
		c.a = 1.0 - maxf(0.0, k - 0.4) * 1.6
		for i in steps:
			var ang := lerpf(a0, a1, float(i) / float(steps - 1))
			for w in 3:
				var r := radius - float(w) * 6.0 + sin(float(i) * 0.4) * 3.0
				var cc := c.lightened(0.5) if w == 0 else (c if w == 1 else c.darkened(0.2))
				_sq(Vector2(cos(ang), sin(ang)) * r, cc, 5.0)
		_flush()

class PxFlames extends PxBase:
	var color := Color(1.0, 0.5, 0.2)
	var radius := 140.0
	var life := 0.9
	var _t := 0.0
	var _parts: Array = []

	func _ready() -> void:
		super._ready()
		for i in 46:
			var a := randf() * TAU
			var r := sqrt(randf()) * radius
			_parts.append({"p": Vector2(cos(a) * r, sin(a) * r * 0.6), "d": randf() * life * 0.6, "v": randf_range(40.0, 90.0)})

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life * 1.6:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for p in _parts:
			var tt := _t - float(p["d"])
			if tt < 0.0:
				continue
			var k := clampf(tt / (life * 0.9), 0.0, 1.0)
			var pos: Vector2 = (p["p"] as Vector2) + Vector2(sin(tt * 9.0 + float((p["p"] as Vector2).x)) * 3.0, -float(p["v"]) * tt)
			var c := Color(1.0, 0.9, 0.35, 1.0 - k) if k < 0.3 else (color if k < 0.7 else Color(0.35, 0.18, 0.12, 1.0 - k))
			c.a = minf(c.a, 1.0 - k * k)
			_sq(pos, c, 12.0 * (1.0 - k * 0.55))
		_flush()
