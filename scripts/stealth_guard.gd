class_name StealthGuard
extends Node2D
## Strażnik do zadań skradankowych: patroluje między punktami i widzi tylko w stożku przed sobą.
## Gdy gracz stoi w stożku, pasek wykrycia rośnie (szybciej z bliska); po wypełnieniu strażnik
## wysyła `spotted`. Poza stożkiem pasek opada, więc można przemknąć za plecami.

signal spotted

const SPEED := 70.0
const WAIT := 1.1

var path: Array = []
var view_range := 250.0
var half_angle := deg_to_rad(32.0)
var facing := Vector2.RIGHT
var alert := 0.0
var active := true

var _i := 0
var _wait := 0.0
var _t := 0.0
var _start := Vector2.ZERO

func setup(p_path: Array, p_range: float = 250.0) -> void:
	path = p_path
	view_range = p_range

func _ready() -> void:
	z_index = 95
	z_as_relative = false
	_start = path[0] if not path.is_empty() else position
	position = _start
	if path.size() > 1:
		facing = (path[1] - path[0]).normalized()

func reset() -> void:
	position = _start
	_i = 0
	alert = 0.0
	_wait = 0.0
	if path.size() > 1:
		facing = (path[1] - path[0]).normalized()

func _process(delta: float) -> void:
	_t += delta
	if not active:
		queue_redraw()
		return
	_patrol(delta)
	_watch(delta)
	queue_redraw()

func _patrol(delta: float) -> void:
	if path.size() < 2:
		facing = facing.rotated(delta * 0.8)
		return
	if _wait > 0.0:
		_wait -= delta
		# na postoju rozgląda się na boki
		facing = facing.rotated(sin(_t * 3.0) * delta * 1.2)
		return
	var target: Vector2 = path[(_i + 1) % path.size()]
	var to := target - position
	if to.length() <= SPEED * delta:
		position = target
		_i = (_i + 1) % path.size()
		_wait = WAIT
		return
	facing = facing.lerp(to.normalized(), minf(1.0, delta * 8.0)).normalized()
	position += to.normalized() * SPEED * delta

func _watch(delta: float) -> void:
	var seen := false
	var closeness := 0.0
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if "net_ghost" in p and bool(p.get("net_ghost")):
			continue
		var to: Vector2 = (p as Node2D).global_position - global_position
		var d := to.length()
		if d > view_range:
			continue
		if d > 40.0 and absf(facing.angle_to(to)) > half_angle:
			continue
		seen = true
		closeness = maxf(closeness, 1.0 - d / view_range)
	if seen:
		alert += delta * (0.9 + 1.6 * closeness)
	else:
		alert = maxf(0.0, alert - delta * 0.7)
	if alert >= 1.0:
		alert = 0.0
		spotted.emit()

func _draw() -> void:
	var a := clampf(alert, 0.0, 1.0)
	var col := Color(1.0, 0.9, 0.35, 0.16).lerp(Color(1.0, 0.2, 0.15, 0.4), a)
	var pts := PackedVector2Array([Vector2.ZERO])
	var base := facing.angle()
	for k in range(13):
		var ang := base - half_angle + (2.0 * half_angle) * float(k) / 12.0
		pts.append(Vector2.from_angle(ang) * view_range)
	draw_colored_polygon(pts, col)
	# strażnik: cień, korpus, hełm i dziób wskazujący kierunek patrzenia
	draw_circle(Vector2(0, 8), 16.0, Color(0, 0, 0, 0.3))
	draw_circle(Vector2(0, -6), 15.0, Color(0.42, 0.45, 0.55))
	draw_circle(Vector2(0, -16), 11.0, Color(0.62, 0.65, 0.75))
	draw_circle(facing * 10.0 + Vector2(0, -16), 4.0, Color(1.0, 0.7, 0.2))
	if a > 0.05:
		draw_rect(Rect2(-18, -44, 36.0 * a, 5), Color(1.0, 0.25, 0.2))
		draw_rect(Rect2(-18, -44, 36, 5), Color(1, 1, 1, 0.6), false, 1.0)
