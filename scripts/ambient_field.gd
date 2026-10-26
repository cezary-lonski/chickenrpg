class_name AmbientField
extends Node2D

enum Mode { LEAVES, DUST, ASH, RAIN, EMBERS, SAND }

var mode := Mode.LEAVES
var bounds := Vector2(2200, 1500)
var wind := Vector2(26, 0)
var count := 140
var _parts: Array = []
var _rng := RandomNumberGenerator.new()
var _lightning_t := 5.0
var _bolt_t := 0.0
var _bolt: Array = []

func setup(mode_name: String, p_bounds: Vector2, seed_i: int = 3) -> void:
	bounds = p_bounds
	_rng.seed = seed_i
	match mode_name:
		"dust":
			mode = Mode.DUST
			count = 110
			wind = Vector2(44, 0)
		"ash":
			mode = Mode.ASH
			count = 130
			wind = Vector2(16, 22)
		"rain":
			mode = Mode.RAIN
			count = 190
			wind = Vector2(70, 0)
		"embers":
			mode = Mode.EMBERS
			count = 90
			wind = Vector2(10, -10)
		"sand":
			mode = Mode.SAND
			count = 150
			wind = Vector2(88, 10)
		_:
			mode = Mode.LEAVES
			count = 90
			wind = Vector2(30, 8)
	_parts.clear()
	for i in count:
		_parts.append(_new_part(true))
	_lightning_t = _rng.randf_range(3.0, 6.0)
	queue_redraw()

func _ready() -> void:
	z_index = 40
	z_as_relative = false
	if _parts.is_empty():
		setup("leaves", bounds, 3)

func _new_part(initial: bool = false) -> Dictionary:
	var p := Vector2(_rng.randf_range(0, bounds.x), _rng.randf_range(-bounds.y if not initial else 0, bounds.y))
	var speed := 12.0
	var size := 2.0
	match mode:
		Mode.RAIN:
			speed = _rng.randf_range(620, 920)
			size = _rng.randf_range(7, 14)
		Mode.SAND:
			speed = _rng.randf_range(60, 150)
			size = _rng.randf_range(1.0, 2.6)
		Mode.DUST:
			speed = _rng.randf_range(14, 42)
			size = _rng.randf_range(1.2, 3.0)
		Mode.ASH:
			speed = _rng.randf_range(12, 34)
			size = _rng.randf_range(1.0, 2.6)
		Mode.EMBERS:
			speed = _rng.randf_range(18, 54)
			size = _rng.randf_range(1.2, 2.8)
		_:
			speed = _rng.randf_range(22, 56)
			size = _rng.randf_range(2.0, 4.2)
	return {
		"p": p,
		"v": speed,
		"size": size,
		"phase": _rng.randf() * TAU,
		"spin": _rng.randf_range(-2.0, 2.0),
		"alpha": _rng.randf_range(0.25, 0.85),
	}

func _process(delta: float) -> void:
	visible = GameState.setting("animations")
	if not visible:
		return
	var t := Time.get_ticks_msec() * 0.001
	for i in _parts.size():
		var d: Dictionary = _parts[i]
		var p: Vector2 = d["p"]
		var v: float = d["v"]
		match mode:
			Mode.RAIN:
				p.y += v * delta
				p.x += wind.x * delta
			Mode.SAND:
				p.x += v * delta
				p.y += sin(t * 2.0 + float(d["phase"])) * 18.0 * delta + wind.y * delta
			Mode.DUST, Mode.ASH:
				p.x += (v * 0.4 + wind.x) * delta
				p.y += (v * 0.55 + wind.y) * delta + sin(t * 1.3 + float(d["phase"])) * 11.0 * delta
			Mode.EMBERS:
				p.x += (wind.x + sin(t * 1.6 + float(d["phase"])) * 14.0) * delta
				p.y -= v * delta
			_:
				p.x += (wind.x + sin(t + float(d["phase"])) * 22.0) * delta
				p.y += (v + sin(t * 1.9 + float(d["phase"])) * 18.0) * delta
		if p.y > bounds.y + 30.0 or p.y < -60.0 or p.x > bounds.x + 50.0 or p.x < -50.0:
			d = _new_part(false)
			if mode == Mode.RAIN:
				d["p"] = Vector2(_rng.randf_range(-80, bounds.x), -_rng.randf_range(10, 120))
			elif mode == Mode.SAND:
				d["p"] = Vector2(-_rng.randf_range(10, 120), _rng.randf_range(0, bounds.y))
			elif mode == Mode.EMBERS:
				d["p"] = Vector2(_rng.randf_range(0, bounds.x), bounds.y + _rng.randf_range(0, 60))
			else:
				d["p"] = Vector2(_rng.randf_range(-60, bounds.x), _rng.randf_range(-80, 0))
			_parts[i] = d
			continue
		d["p"] = p
		d["phase"] = float(d["phase"]) + float(d["spin"]) * delta
	if mode == Mode.RAIN:
		_lightning_t -= delta
		if _lightning_t <= 0.0:
			_lightning_t = _rng.randf_range(4.0, 9.0)
			_make_bolt()
			Fx.flash(Color(0.72, 0.8, 1.0), 0.26, 0.2)
		if _bolt_t > 0.0:
			_bolt_t -= delta
			if _bolt_t <= 0.0:
				_bolt.clear()
	queue_redraw()

func _make_bolt() -> void:
	_bolt.clear()
	_bolt_t = 0.32
	var x := _rng.randf_range(bounds.x * 0.2, bounds.x * 0.8)
	var y := 0.0
	for i in 9:
		_bolt.append(Vector2(x, y))
		x += _rng.randf_range(-34, 34)
		y += _rng.randf_range(45, 95)

func _draw() -> void:
	var c := Color.WHITE
	match mode:
		Mode.RAIN:
			c = Color(0.68, 0.8, 1.0, 0.32)
		Mode.SAND:
			c = Color(0.92, 0.78, 0.52, 0.55)
		Mode.DUST:
			c = Color(0.82, 0.74, 0.55, 0.32)
		Mode.ASH:
			c = Color(0.72, 0.7, 0.72, 0.45)
		Mode.EMBERS:
			c = Color(1.0, 0.62, 0.22, 0.62)
		_:
			c = Color(0.62, 0.78, 0.4, 0.45)
	for d in _parts:
		var p: Vector2 = d["p"]
		var s: float = d["size"]
		var a: float = d["alpha"]
		match mode:
			Mode.RAIN:
				draw_line(p, p + Vector2(wind.x * 0.045, s), Color(c.r, c.g, c.b, c.a * a), 1.1, true)
			Mode.SAND, Mode.DUST:
				draw_line(p, p + Vector2(s * 2.4, 0), Color(c.r, c.g, c.b, c.a * a), 1.0, true)
			Mode.ASH:
				draw_circle(p, s * 0.7, Color(c.r, c.g, c.b, c.a * a))
			Mode.EMBERS:
				var glow := 0.55 + 0.45 * sin(float(d["phase"]) * 2.2)
				draw_circle(p, s * (0.7 + 0.3 * glow), Color(c.r, c.g, c.b, c.a * a * glow))
			_:
				var ang: float = d["phase"]
				var dir := Vector2(cos(ang), sin(ang))
				var perp := Vector2(-dir.y, dir.x)
				draw_colored_polygon(PackedVector2Array([
					p + dir * s * 1.8,
					p + perp * s * 0.7,
					p - dir * s * 1.8,
					p - perp * s * 0.7,
				]), Color(c.r, c.g, c.b, c.a * a))
	if mode == Mode.RAIN and _bolt_t > 0.0 and _bolt.size() > 1:
		for i in _bolt.size() - 1:
			var a: Vector2 = _bolt[i]
			var b: Vector2 = _bolt[i + 1]
			draw_line(a, b, Color(0.8, 0.88, 1.0, 0.55), 2.2, true)
