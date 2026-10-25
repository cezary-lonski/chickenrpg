class_name Ambulance
extends PixelNode
## Karetka w pixel arcie. Zabiera poległego towarzysza (pickup) albo przywozi go z powrotem (deliver):
## wjeżdża z boku, staje przy celu z migającym kogutem, wywołuje on_arrive i odjeżdża.

var dir := 1.0
var target_x := 0.0
var on_arrive: Callable = Callable()
var _t := 0.0
var _phase := 0   # 0 dojazd, 1 postój, 2 odjazd
var _wait := 0.0
var _speed := 0.0
var _arrived_called := false

static func dispatch(parent: Node, pos: Vector2, arrive_cb: Callable) -> Ambulance:
	var a := Ambulance.new()
	a.dir = 1.0 if randf() < 0.5 else -1.0
	a.on_arrive = arrive_cb
	a.target_x = pos.x - a.dir * 70.0
	parent.add_child(a)
	a.global_position = Vector2(a.target_x - a.dir * 1000.0, pos.y + 6.0)
	return a

func _init() -> void:
	px_origin = Vector2(-96, -88)
	px_w = 48
	px_h = 28
	z_index = 60
	z_as_relative = false

func _ready() -> void:
	Audio.play("gate", 1.2, -8.0)

func _process(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			var rem := (target_x - global_position.x) * dir
			_speed = clampf(rem * 2.4, 90.0, 620.0)
			global_position.x += dir * _speed * delta
			if rem <= 4.0:
				_phase = 1
				_wait = 1.1
				_speed = 0.0
		1:
			_wait -= delta
			if not _arrived_called:
				_arrived_called = true
				Fx.popup(global_position + Vector2(0, -110), "KARETKA!", Color(1.0, 0.4, 0.4))
				if on_arrive.is_valid():
					on_arrive.call()
			if _wait <= 0.0:
				_phase = 2
		2:
			_speed = minf(_speed + 900.0 * delta, 700.0)
			global_position.x += dir * _speed * delta
			if absf(global_position.x - target_x) > 1100.0:
				queue_free()
	if int(_t * 5.0) % 4 == 0 and _phase != 1:
		pass
	queue_redraw()

func _draw() -> void:
	_pbegin()
	_xf_set(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	var bob := sin(_t * 30.0) * 1.2 if _speed > 10.0 else 0.0
	var white := Color(0.95, 0.95, 0.97)
	var red := Color(0.86, 0.14, 0.16)
	# cień
	_pp(PackedVector2Array([Vector2(-60, 4), Vector2(66, 4), Vector2(58, -2), Vector2(-52, -2)]), Color(0, 0, 0, 0.3))
	# nadwozie i kabina
	_pr(Rect2(-58, -50 + bob, 92, 38), white)
	_pp(PackedVector2Array([Vector2(34, -50 + bob), Vector2(54, -50 + bob), Vector2(68, -30 + bob), Vector2(68, -12 + bob), Vector2(34, -12 + bob)]), Color(0.86, 0.88, 0.92))
	_pp(PackedVector2Array([Vector2(40, -45 + bob), Vector2(52, -45 + bob), Vector2(62, -31 + bob), Vector2(40, -31 + bob)]), Color(0.45, 0.75, 0.95))
	_pr(Rect2(-58, -26 + bob, 126, 6), red)
	# krzyż
	_pr(Rect2(-33, -44 + bob, 8, 22), red)
	_pr(Rect2(-40, -37 + bob, 22, 8), red)
	# koguty
	var blink := int(_t * 7.0) % 2 == 0
	var ca := Color(1.0, 0.15, 0.15) if blink else Color(0.45, 0.1, 0.1)
	var cb := Color(0.2, 0.45, 1.0) if not blink else Color(0.1, 0.18, 0.4)
	_pr(Rect2(-24, -58 + bob, 14, 8), ca)
	_pr(Rect2(-6, -58 + bob, 14, 8), cb)
	_pc(Vector2(-17, -54 + bob), 22.0, Color(ca.r, ca.g, ca.b, 0.22 if blink else 0.05))
	_pc(Vector2(1, -54 + bob), 22.0, Color(cb.r, cb.g, cb.b, 0.05 if blink else 0.22))
	# koła
	for wx in [-34.0, 44.0]:
		_pc(Vector2(wx, -9 + bob * 0.5), 11.0, Color(0.12, 0.12, 0.14))
		_pc(Vector2(wx, -9 + bob * 0.5), 5.0, Color(0.7, 0.72, 0.78))
		var a := _t * 22.0
		_pl(Vector2(wx, -9) + Vector2(cos(a), sin(a)) * 3.0, Vector2(wx, -9) - Vector2(cos(a), sin(a)) * 3.0, Color(0.3, 0.3, 0.35), 2.0)
	_pflush()
