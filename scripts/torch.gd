class_name Torch
extends PixelNode

var flame_col := Color(1.0, 0.62, 0.22)
var _t := 0.0
var _phase := 0.0

func setup(color: Color, phase: float = 0.0) -> void:
	flame_col = color
	_phase = phase
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _init() -> void:
	px_origin = Vector2(-60, -148)
	px_w = 30
	px_h = 40

func _draw() -> void:
	_pbegin()
	var flick := sin(_t * 9.0 + _phase) * 0.12 + sin(_t * 17.0 + _phase * 2.0) * 0.06
	_pp(PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(9, -66), Vector2(-9, -66),
	]), Color(0.3, 0.22, 0.16))
	_pr(Rect2(Vector2(-13, -72), Vector2(26, 8)), Color(0.4, 0.3, 0.2))
	var glow := 0.75 + 0.25 * sin(_t * 6.0 + _phase)
	_pc(Vector2(0, -84), 38.0, Color(flame_col.r, flame_col.g, flame_col.b, 0.1 * glow))
	_pc(Vector2(0, -84), 24.0, Color(flame_col.r, flame_col.g, flame_col.b, 0.18 * glow))
	var sway := sin(_t * 7.0 + _phase) * 4.0
	_pp(PackedVector2Array([
		Vector2(-9, -74),
		Vector2(9, -74),
		Vector2(8 + sway, -94 - flick * 12.0),
		Vector2(0 + sway * 1.5, -112 - flick * 18.0),
		Vector2(-8 + sway, -94 - flick * 10.0),
	]), flame_col)
	_pp(PackedVector2Array([
		Vector2(-4, -76),
		Vector2(4, -76),
		Vector2(2 + sway * 0.5, -90 - flick * 10.0),
		Vector2(-2 + sway * 0.5, -88 - flick * 8.0),
	]), Color(1.0, 0.9, 0.55, 0.9))
	_pflush()
