class_name StealthGuard
extends Node2D
## Strażnik do zadań skradankowych: patroluje między punktami i widzi tylko w stożku przed sobą.
## Ruch zależy wyłącznie od zegara (state_at), więc serwer MMO i klienci liczą go tak samo:
## serwer wykrywa graczy, klient tylko rysuje strażnika. W grze jednoosobowej wykrycie liczy sam węzeł.
## Gdy gracz stoi w stożku, pasek wykrycia rośnie (szybciej z bliska); po wypełnieniu strażnik
## wysyła `spotted`. Poza stożkiem pasek opada, więc można przemknąć za plecami.

signal spotted

const SPEED := 70.0
const WAIT := 1.1
const HALF_ANGLE := 0.56    # ~32°

var path: Array = []
var view_range := 250.0
var facing := Vector2.RIGHT
var alert := 0.0
var active := true
var detect := true          # false: tylko rysuje (klient MMO)
var clock := 0.0            # czas patrolu; w MMO ustawiany z zegara serwera

var _t := 0.0

## Pozycja i kierunek patrzenia strażnika po czasie `t` od startu (patrol w pętli z postojami).
static func state_at(p: Array, t: float) -> Dictionary:
	if p.size() < 2:
		return {"pos": p[0] if not p.is_empty() else Vector2.ZERO, "dir": Vector2.RIGHT.rotated(t * 0.8)}
	var legs: Array = []
	var total := 0.0
	for i in p.size():
		var len: float = (p[(i + 1) % p.size()] - p[i]).length()
		legs.append(len / SPEED + WAIT)
		total += legs[i]
	var m := fposmod(t, total)
	for i in p.size():
		var a: Vector2 = p[i]
		var b: Vector2 = p[(i + 1) % p.size()]
		var dir := (b - a).normalized()
		var move_t: float = legs[i] - WAIT
		if m < move_t:
			return {"pos": a + dir * SPEED * m, "dir": dir}
		if m < legs[i]:
			# na postoju rozgląda się na boki
			return {"pos": b, "dir": dir.rotated(sin((m - move_t) * 6.0) * 0.9)}
		m -= legs[i]
	return {"pos": p[0], "dir": Vector2.RIGHT}

## Czy punkt `at` leży w stożku wzroku strażnika (pos, dir, zasięg).
static func sees(pos: Vector2, dir: Vector2, rng: float, at: Vector2) -> float:
	var to := at - pos
	var d := to.length()
	if d > rng:
		return 0.0
	if d > 40.0 and absf(dir.angle_to(to)) > HALF_ANGLE:
		return 0.0
	return 1.0 - d / rng

func setup(p_path: Array, p_range: float = 250.0) -> void:
	path = p_path
	view_range = p_range
	_apply()

func _ready() -> void:
	z_index = 95
	z_as_relative = false
	_apply()

func _apply() -> void:
	var s := state_at(path, clock)
	position = s["pos"]
	facing = s["dir"]

func reset() -> void:
	clock = 0.0
	alert = 0.0
	_apply()

func _process(delta: float) -> void:
	_t += delta
	if active:
		clock += delta
		_apply()
		if detect:
			_watch(delta)
	queue_redraw()

func _watch(delta: float) -> void:
	var closeness := 0.0
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if "net_ghost" in p and bool(p.get("net_ghost")):
			continue
		closeness = maxf(closeness, sees(global_position, facing, view_range, (p as Node2D).global_position))
	if closeness > 0.0:
		alert += delta * (0.9 + 1.6 * closeness)
	else:
		alert = maxf(0.0, alert - delta * 0.7)
	if alert >= 1.0:
		alert = 0.0
		spotted.emit()

func _draw() -> void:
	var a := clampf(alert, 0.0, 1.0)
	var col := Color(1.0, 0.9, 0.35, 0.16).lerp(Color(1.0, 0.2, 0.15, 0.4), a)
	if not active:
		col.a = 0.0
	var pts := PackedVector2Array([Vector2.ZERO])
	var base := facing.angle()
	for k in range(13):
		var ang := base - HALF_ANGLE + (2.0 * HALF_ANGLE) * float(k) / 12.0
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
