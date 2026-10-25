class_name BossArena
extends Node2D
## Własna arena bossa: okrągły krąg z runami i barierą, która nie pozwala uciec.
## Pojawia się z animacją przy wejściu bossa i znika po jego pokonaniu.

var center := Vector2(1100, 750)
var radius := 560.0
var col := Color(0.7, 0.25, 0.9)
var _t := 0.0
var _alpha := 0.0
var _target := 1.0
var _body: StaticBody2D

func _ready() -> void:
	z_index = -3
	position = center
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	# bariera: pierścień złożony z prostokątów stycznych do okręgu
	var segs := 36
	for i in segs:
		var a := TAU * float(i) / float(segs)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(60.0, TAU * (radius + 40.0) / float(segs) + 8.0)
		cs.shape = sh
		cs.position = Vector2.RIGHT.rotated(a) * (radius + 30.0)
		cs.rotation = a
		_body.add_child(cs)

func lower() -> void:
	_target = 0.0
	if _body:
		_body.process_mode = Node.PROCESS_MODE_DISABLED
		for c in _body.get_children():
			(c as CollisionShape2D).set_deferred("disabled", true)

func _process(delta: float) -> void:
	_t += delta
	_alpha = move_toward(_alpha, _target, delta * 0.8)
	if _target <= 0.0 and _alpha <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var a := _alpha
	draw_circle(Vector2.ZERO, radius, Color(0.05, 0.02, 0.08, 0.35 * a))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, Color(col.r, col.g, col.b, 0.9 * a), 6.0, true)
	draw_arc(Vector2.ZERO, radius - 14.0, 0.0, TAU, 128, Color(1.0, 0.8, 1.0, 0.35 * a), 2.0, true)
	for i in 12:
		var ang := _t * 0.15 + TAU * float(i) / 12.0
		var p := Vector2.RIGHT.rotated(ang) * (radius - 34.0)
		draw_circle(p, 6.0 + 2.0 * sin(_t * 3.0 + float(i)), Color(col.r, col.g, col.b, 0.6 * a))
		draw_line(p, p * 0.93, Color(col.r, col.g, col.b, 0.5 * a), 2.0)
	for k in 3:
		var r2 := radius * (0.35 + 0.22 * float(k))
		draw_arc(Vector2.ZERO, r2, _t * 0.2 * (1 if k % 2 == 0 else -1), _t * 0.2 * (1 if k % 2 == 0 else -1) + PI * 1.3, 48, Color(col.r, col.g, col.b, 0.18 * a), 3.0, true)
