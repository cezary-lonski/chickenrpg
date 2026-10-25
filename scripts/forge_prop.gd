class_name ForgeProp
extends PixelNode
## Kowadło i palenisko obok kowala (dekoracja z płonącym paleniskiem).

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _init() -> void:
	px_origin = Vector2(-136, -100)
	px_w = 42
	px_h = 30

func _draw() -> void:
	_pbegin()
	# palenisko
	_pr(Rect2(-92, -34, 56, 42), Color(0.27, 0.22, 0.2))
	_pr(Rect2(-92, -34, 56, 8), Color(0.18, 0.15, 0.14))
	var fl := 0.6 + 0.4 * sin(_t * 11.0)
	var fcol := Color(1.0, 0.45 + 0.2 * fl, 0.1, 0.9)
	_pp(PackedVector2Array([Vector2(-84, -34), Vector2(-74, -60 * fl - 10), Vector2(-62, -34)]), fcol)
	_pp(PackedVector2Array([Vector2(-66, -34), Vector2(-54, -66 * fl - 6), Vector2(-42, -34)]), fcol)
	_pc(Vector2(-64, -40), 38.0, Color(1.0, 0.5, 0.1, 0.07 + 0.05 * fl))
	# kowadło
	_pr(Rect2(-14, -8, 28, 18), Color(0.25, 0.25, 0.3))
	_pp(PackedVector2Array([Vector2(-34, -22), Vector2(26, -22), Vector2(16, -8), Vector2(-10, -8), Vector2(-24, -14)]), Color(0.42, 0.44, 0.5))
	_pr(Rect2(-34, -28, 60, 6), Color(0.58, 0.6, 0.66))
	_pflush()
