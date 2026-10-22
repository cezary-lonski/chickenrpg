class_name CreatureVisual
extends Node2D
## Rysuje kurczaka lub ptaka w całości z prymitywów (wielokąty, elipsy, koła).
## Zero plików graficznych, a postać animuje się przez zmianę pozycji.

enum Kind { CHICKEN, BIRD }

const PARAMS := {
	"kurczak": {"kind": "chicken", "body": Vector2(17, 15), "head": 10.0, "neck": 9.0, "tail": "feather", "comb": 1.0, "wattle": 0.9, "beak": 1.0, "leg": 1.0},
	"kogut": {"kind": "chicken", "body": Vector2(19, 16), "head": 10.0, "neck": 7.0, "tail": "long", "comb": 1.7, "wattle": 1.4, "beak": 1.05, "leg": 1.0},
	"kwoka": {"kind": "chicken", "body": Vector2(15, 13), "head": 9.0, "neck": 10.0, "tail": "feather", "comb": 0.7, "wattle": 0.7, "beak": 0.95, "leg": 1.05},
	"indyk": {"kind": "chicken", "body": Vector2(23, 20), "head": 12.0, "neck": 6.0, "tail": "fan", "comb": 1.2, "wattle": 1.2, "beak": 1.1, "leg": 1.1},
	"wrzos": {"kind": "bird", "body": Vector2(14, 11), "head": 7.5, "neck": 5.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 0.75, "leg": 0.85},
	"sroka": {"kind": "bird", "body": Vector2(15, 11), "head": 7.5, "neck": 5.0, "tail": "long", "comb": 0.0, "wattle": 0.0, "beak": 0.85, "leg": 0.8},
	"wronszek": {"kind": "bird", "body": Vector2(12, 9), "head": 6.5, "neck": 5.5, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 0.7, "leg": 0.8},
	"kawka": {"kind": "bird", "body": Vector2(16, 13), "head": 8.5, "neck": 5.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 1.0, "leg": 0.9},
	"jastrzab": {"kind": "bird", "body": Vector2(16, 13), "head": 8.0, "neck": 4.5, "tail": "long", "comb": 0.0, "wattle": 0.0, "beak": 0.8, "leg": 0.9},
	"kruk": {"kind": "bird", "body": Vector2(20, 16), "head": 10.0, "neck": 4.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 1.25, "leg": 0.95},
	"orzel_szarak": {"kind": "bird", "body": Vector2(19, 15), "head": 9.0, "neck": 4.5, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 0.95, "leg": 1.0},
	"bocian_gruby": {"kind": "bird", "body": Vector2(22, 19), "head": 9.5, "neck": 12.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 1.5, "leg": 1.15},
	"szpak": {"kind": "bird", "body": Vector2(18, 15), "head": 9.0, "neck": 5.0, "tail": "long", "comb": 0.0, "wattle": 0.0, "beak": 0.9, "leg": 0.95},
	"indyk_krolewski": {"kind": "chicken", "body": Vector2(24, 21), "head": 12.5, "neck": 6.0, "tail": "fan", "comb": 1.4, "wattle": 1.5, "beak": 1.15, "leg": 1.2},
	"gasior": {"kind": "chicken", "body": Vector2(22, 19), "head": 11.0, "neck": 13.0, "tail": "feather", "comb": 0.7, "wattle": 1.2, "beak": 1.25, "leg": 1.05},
	"paw": {"kind": "chicken", "body": Vector2(18, 15), "head": 10.0, "neck": 9.0, "tail": "fan", "comb": 0.9, "wattle": 0.9, "beak": 1.0, "leg": 1.05},
	"golab": {"kind": "bird", "body": Vector2(15, 11), "head": 7.5, "neck": 5.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 0.85, "leg": 0.85},
	"sokol": {"kind": "bird", "body": Vector2(16, 12), "head": 8.0, "neck": 4.5, "tail": "long", "comb": 0.0, "wattle": 0.0, "beak": 0.9, "leg": 0.9},
	"czajka": {"kind": "bird", "body": Vector2(14, 11), "head": 7.0, "neck": 5.5, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 1.05, "leg": 0.85},
	"puchacz": {"kind": "bird", "body": Vector2(21, 17), "head": 11.5, "neck": 3.5, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 1.1, "leg": 0.95},
	"krol_krukow": {"kind": "bird", "body": Vector2(24, 20), "head": 12.0, "neck": 4.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 1.4, "leg": 1.1},
}

# stan wejściowy
var species := "kurczak"
var pal: Dictionary = {}
var body_scale := 1.0
var facing := 1.0
var moving := false
var grounded := true
var crouch := 0.0
var arm := 0.0          # 0..1 wysunięcie atakującego skrzydła
var arm_back := 0.0     # 0..1 cofnięcie (przygotowanie)
var lean := 0.0         # pochylenie tułowia
var flap := 0.0         # 0..1 unoszenie skrzydeł
var flash_t := 0.0
var dead := false
var dead_t := 0.0
var hurt_t := 0.0
var charge_t := 0.0     # 0..1 naładowanie ciężkiego ataku
var idle_seed := 0.0

var _walk := 0.0
var _bob := 0.0
var _blink := 0.0
var _blink_t := 2.0
var _look := 0.0

func _ready() -> void:
	_blink_t = randf_range(1.0, 4.0)
	_bob = randf() * TAU
	queue_redraw()

func configure(p_species: String, p_pal: Dictionary, p_scale: float = 1.0) -> void:
	species = p_species
	pal = p_pal
	body_scale = p_scale
	queue_redraw()

func set_facing(dir: float) -> void:
	if dir != 0.0 and sign(dir) != sign(facing):
		facing = sign(dir)
		queue_redraw()

func flash(amount: float = 1.0) -> void:
	flash_t = maxf(flash_t, 0.12 * amount)
	queue_redraw()

func die() -> void:
	dead = true
	dead_t = 0.0

func revive() -> void:
	dead = false
	dead_t = 0.0

func _process(delta: float) -> void:
	var rate := 9.0
	if moving and grounded:
		_walk += delta * rate
	else:
		_walk = lerpf(_walk, roundf(_walk / PI) * PI, 0.2)
	if grounded and not dead:
		_bob += delta * 2.0
	# mruganie
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = 0.09
		_blink_t = randf_range(1.6, 5.0)
	if _blink > 0.0:
		_blink -= delta
	# spojrzenie: lekki zygzak głowy
	_look = sin(_bob * 0.7 + idle_seed) * 0.6 + sin(_bob * 1.9) * 0.25
	flash_t = maxf(0.0, flash_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	if dead:
		dead_t += delta
	queue_redraw()

# ------------------------------------------------------------- geometria ----

func _p() -> Dictionary:
	return PARAMS.get(species, PARAMS["kurczak"])

func _ellipse(c: Vector2, r: Vector2, steps: int = 18) -> PackedVector2Array:
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

func _rot(p: Vector2, origin: Vector2, a: float) -> Vector2:
	return origin + (p - origin).rotated(a)

func _c(key: String, fallback: Color) -> Color:
	return pal.get(key, fallback)

# ------------------------------------------------------------------ rysunek --

func _draw() -> void:
	var P := _p()
	var s := body_scale
	var is_chicken := String(P["kind"]) == "chicken"
	var body_r := Vector2(P["body"]) * s
	var head_r := float(P["head"]) * s
	var neck := float(P["neck"]) * s

	var body_col := _c("body", Color(0.97, 0.95, 0.9))
	var shade_col := _c("shade", body_col.darkened(0.18))
	var comb_col := _c("comb", Color(0.9, 0.2, 0.24))
	var beak_col := _c("beak", Color(0.97, 0.72, 0.16))
	var leg_col := _c("leg", Color(0.95, 0.72, 0.15))
	var eye_col := _c("eye", Color(0.08, 0.08, 0.1))

	# --- pozycje bazowe (pochód w stopach = (0,0))
	var crouch_dy := crouch * 7.0 * s
	var leg_len := (18.0 + neck * 0.25) * s
	var body_c := Vector2(0.0, -(leg_len + body_r.y * 0.85) + crouch_dy)
	var lean_rot := lean * 0.35
	var head_c := body_c + Vector2(neck + head_r * 0.4, -(neck + head_r * 0.5) + crouch_dy * 0.4)
	head_c = _rot(head_c, body_c, lean_rot * 0.6)
	body_c = _rot(body_c, Vector2(0, 0), lean_rot * 0.25)
	# krok
	var bob := absf(sin(_walk)) * 2.4 * s * (1.0 if moving else 0.0)
	body_c.y -= bob

	# --- cień (prosty, zanika w powietrzu)
	var shadow_a := 0.0 if not grounded else 0.22
	if shadow_a > 0.0:
		draw_colored_polygon(_ellipse(Vector2(0, -1), Vector2(16 * s, 4.5 * s)), Color(0, 0, 0, shadow_a))

	# --- martwy: leży na boku
	if dead:
		_draw_corpse(P, s, body_c, body_r, head_c, head_r, body_col, shade_col, beak_col, leg_col)
		return

	# --- tylne skrzydło
	var wing_shoulder := body_c + Vector2(-body_r.x * 0.15, -body_r.y * 0.15)
	var flap_ang := lerpf(-0.15, -1.15, flap) + sin(_walk * 2.0) * 0.12 * float(moving) + arm * 0.5 - arm_back * 0.6
	_draw_wing(wing_shoulder, body_r.x, body_r.y, s, flap_ang, shade_col.darkened(0.08), true)

	# --- nogi
	var leg_swing := sin(_walk + PI) * 6.0 * s * (1.0 if moving else 0.0)
	for side in [-1.0, 1.0]:
		var hip := body_c + Vector2(side * body_r.x * 0.28, body_r.y * 0.7)
		var knee := hip + Vector2(leg_swing * 0.5 * side + side * 2.0 * s, leg_len * 0.5)
		var foot := Vector2(hip.x + leg_swing * side + side * 3.0 * s, -2.0 * s)
		var w := 2.6 * s * float(P["leg"])
		draw_line(hip, knee, leg_col.darkened(0.15), w, true)
		draw_line(knee, foot, leg_col, w, true)
		# stopa
		var toe_dir := 1.0
		for i in 3:
			var t := float(i) - 1.0
			draw_line(foot, foot + Vector2(toe_dir * 5.0 * s, t * 2.0 * s), leg_col, w * 0.8, true)
		draw_line(foot, foot + Vector2(-toe_dir * 2.5 * s, 0), leg_col, w * 0.8, true)

	# --- ogon
	_draw_tail(P, s, body_c, body_r, body_col, shade_col)

	# --- tułów
	draw_colored_polygon(_ellipse(body_c, body_r), body_col)
	# pierś jaśniejsza
	draw_colored_polygon(_ellipse(body_c + Vector2(body_r.x * 0.22, body_r.y * 0.12), Vector2(body_r.x * 0.62, body_r.y * 0.72)), body_col.lightened(0.06))
	# brzuch w cieniu
	draw_colored_polygon(_ellipse(body_c + Vector2(0, body_r.y * 0.5), Vector2(body_r.x * 0.8, body_r.y * 0.45)), shade_col)

	# --- szyja
	var neck_dir := (head_c - body_c).normalized()
	draw_line(body_c + neck_dir * body_r.x * 0.2, head_c, body_col, body_r.y * 0.75, true)

	# --- grzbiet / czubek (kury)
	if is_chicken and float(P["comb"]) > 0.0:
		_draw_comb(head_c, head_r, comb_col, float(P["comb"]) * s)

	# --- głowa
	draw_colored_polygon(_ellipse(head_c, Vector2(head_r, head_r * 0.95)), body_col)
	# --- dziób
	_draw_beak(head_c, head_r, beak_col, float(P["beak"]) * s, is_chicken)
	# --- wolek
	if is_chicken and float(P["wattle"]) > 0.0:
		var ws := float(P["wattle"]) * s
		draw_colored_polygon(_ellipse(head_c + Vector2(head_r * 0.55, head_r * 0.62), Vector2(2.6 * ws, 3.4 * ws)), comb_col)
	# --- oko
	if _blink <= 0.0:
		var eye_off := head_c + Vector2(head_r * 0.3 + _look * head_r * 0.12, -head_r * 0.12)
		draw_circle(eye_off, head_r * 0.24, eye_col)
		draw_circle(eye_off + Vector2(head_r * 0.09, -head_r * 0.09), head_r * 0.09, Color(1, 1, 1, 0.85))
		if hurt_t > 0.0:
			draw_line(eye_off + Vector2(-3, -3) * s, eye_off + Vector2(3, 3) * s, Color(0, 0, 0, 0.6), 1.5)
	else:
		var eo := head_c + Vector2(head_r * 0.3, -head_r * 0.12)
		draw_line(eo + Vector2(-3, 0) * s, eo + Vector2(3, 0) * s, eye_col, 1.5 * s)

	# --- przednie skrzydło (atakujące)
	_draw_wing(wing_shoulder + Vector2(body_r.x * 0.1, -1.0 * s), body_r.x, body_r.y, s, flap_ang, shade_col.lightened(0.05), false)

	# --- błysk trafienia
	if flash_t > 0.0:
		var a := clampf(flash_t / 0.12, 0.0, 1.0)
		draw_circle(body_c, body_r.length() * 1.25, Color(1, 1, 1, a * 0.5))
	if charge_t > 0.0:
		var r := 26.0 * s * (0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.02))
		draw_arc(body_c, r, 0, TAU, 20, Color(1.0, 0.5, 0.25, 0.35 + 0.35 * charge_t), 3.0, true)
		draw_arc(body_c, r * 0.6, 0, TAU, 16, Color(1.0, 0.85, 0.4, 0.25 + 0.35 * charge_t), 2.0, true)

func _draw_wing(shoulder: Vector2, brx: float, bry: float, s: float, ang: float, col: Color, behind: bool) -> void:
	var base := _poly([
		Vector2(0, 0),
		Vector2(brx * 0.85, bry * 0.1),
		Vector2(brx * 0.95, bry * 0.55),
		Vector2(brx * 0.25, bry * 0.75),
	])
	var a := ang if not behind else ang - 0.25
	var pts := PackedVector2Array()
	for p in base:
		pts.append(shoulder + p.rotated(a))
	var c := col
	if behind:
		c = col.darkened(0.22)
	# sierpowate nacięcia
	var tip := shoulder + Vector2(brx * 0.95, bry * 0.55).rotated(a)
	draw_colored_polygon(pts, c)
	draw_line(shoulder, tip, c.darkened(0.25), 1.5 * s, true)

func _draw_tail(P: Dictionary, s: float, body_c: Vector2, body_r: Vector2, body_col: Color, shade_col: Color) -> void:
	var style := String(P["tail"])
	var base := body_c + Vector2(-body_r.x * 0.85, -body_r.y * 0.1)
	var col := shade_col
	match style:
		"feather":
			for i in 3:
				var a := deg_to_rad(200.0 - i * 12.0) + lean * 0.2
				var len := (14.0 - i * 2.0) * s
				var tip := base + Vector2(cos(a), sin(a)) * len
				var w := 3.2 * s
				var perp := Vector2(-sin(a), cos(a)) * w
				draw_colored_polygon(_poly([base, tip + perp, tip - perp]), col.lightened(0.05 * i))
		"long":
			for i in 4:
				var a := deg_to_rad(196.0 - i * 9.0) + lean * 0.2
				var len := (20.0 - i * 2.5) * s
				var tip := base + Vector2(cos(a), sin(a)) * len
				var w := 3.0 * s
				var perp := Vector2(-sin(a), cos(a)) * w
				draw_colored_polygon(_poly([base, tip + perp, tip - perp]), col.darkened(0.05 * i))
		"wedge":
			draw_colored_polygon(_poly([
				base,
				base + Vector2(-16.0, -6.0) * s,
				base + Vector2(-20.0, 2.0) * s,
				base + Vector2(-8.0, 5.0) * s,
			]), col.darkened(0.1))
			draw_colored_polygon(_poly([
				base + Vector2(-4.0, 0),
				base + Vector2(-15.0, -3.0) * s,
				base + Vector2(-16.0, 1.0) * s,
			]), col.lightened(0.08))
		"fan":
			for i in 7:
				var t := float(i) / 6.0
				var a := deg_to_rad(168.0 - t * 66.0) + lean * 0.2
				var len := (16.0 + sin(t * PI) * 8.0) * s
				var tip := base + Vector2(cos(a), sin(a)) * len
				var w := 4.0 * s
				var perp := Vector2(-sin(a), cos(a)) * w
				draw_colored_polygon(_poly([base, tip + perp, tip - perp]), col.darkened(0.02 * i))
				# jasna krawędź pióra
				draw_line(tip - perp, tip + perp, body_col.lightened(0.1), 1.0, true)

func _draw_beak(head_c: Vector2, head_r: float, col: Color, sz: float, is_chicken: bool) -> void:
	var o := head_c + Vector2(head_r * 0.55, head_r * 0.05)
	if is_chicken:
		draw_colored_polygon(_poly([
			o,
			o + Vector2(sz * 1.15, sz * 0.32),
			o + Vector2(sz * 0.35, sz * 0.75),
		]), col)
		draw_line(o + Vector2(sz * 0.15, sz * 0.3), o + Vector2(sz * 0.95, sz * 0.34), col.darkened(0.25), 1.2)
	else:
		# dłuższy, ostrzejszy dziób ptaka
		draw_colored_polygon(_poly([
			o + Vector2(0, -sz * 0.18),
			o + Vector2(sz * 1.5, sz * 0.12),
			o + Vector2(0, sz * 0.5),
		]), col)
		draw_line(o + Vector2(0, sz * 0.12), o + Vector2(sz * 1.4, sz * 0.14), col.darkened(0.3), 1.1)

func _draw_comb(head_c: Vector2, head_r: float, col: Color, sz: float) -> void:
	for i in 3:
		var x := head_c.x + (i - 1.0) * head_r * 0.42
		var h := head_r * (0.42 + 0.16 * (1.0 if i == 1 else 0.0)) * sz
		draw_colored_polygon(_ellipse(Vector2(x, head_c.y - head_r * 0.78 - h * 0.35), Vector2(head_r * 0.26 * sz, h * 0.6), 10), col)
	draw_colored_polygon(_poly([
		head_c + Vector2(-head_r * 0.5, -head_r * 0.5),
		head_c + Vector2(head_r * 0.4, -head_r * 0.55),
		head_c + Vector2(head_r * 0.2, -head_r * 0.2),
		head_c + Vector2(-head_r * 0.4, -head_r * 0.1),
	]), col.darkened(0.08))

func _draw_corpse(P: Dictionary, s: float, body_c: Vector2, body_r: Vector2, head_c: Vector2, head_r: float, body_col: Color, shade_col: Color, beak_col: Color, leg_col: Color) -> void:
	var k := clampf(dead_t / 0.45, 0.0, 1.0)
	var flat := body_c + Vector2(0, -body_r.y * 0.35)
	var c := body_col.lerp(Color(0.75, 0.75, 0.78), 0.35)
	# skrzydła rozkładane
	draw_colored_polygon(_poly([
		flat + Vector2(-body_r.x * 0.9, 0),
		flat + Vector2(-body_r.x * 0.2, -body_r.y * 0.9 * k - 3.0),
		flat + Vector2(body_r.x * 0.2, -body_r.y * 0.7 * k - 2.0),
		flat + Vector2(-body_r.x * 0.5, 4.0),
	]), shade_col.lightened(0.05))
	draw_colored_polygon(_ellipse(flat, Vector2(body_r.x, body_r.y * 0.8)), c)
	var h := flat + Vector2(body_r.x * 0.85 + head_r * 0.5, -head_r * 0.3)
	draw_colored_polygon(_ellipse(h, Vector2(head_r, head_r * 0.9)), c)
	draw_line(h + Vector2(head_r * 0.3, -head_r * 0.1), h + Vector2(head_r * 0.7, -head_r * 0.35), Color(0, 0, 0, 0.75), 2.0)
	draw_line(h + Vector2(head_r * 0.3, -head_r * 0.3), h + Vector2(head_r * 0.7, -head_r * 0.05), Color(0, 0, 0, 0.75), 2.0)
	# nóżki w powietrzu
	draw_line(flat + Vector2(-body_r.x * 0.2, 0), flat + Vector2(-body_r.x * 0.4, -14.0 * s - 8.0 * k), leg_col, 2.6 * s, true)
	draw_line(flat + Vector2(-body_r.x * 0.2, 0), flat + Vector2(body_r.x * 0.1, -12.0 * s - 6.0 * k), leg_col, 2.6 * s, true)
	# gwiazdki
	if dead_t > 0.1:
		var spin := dead_t * 3.0
		for i in 3:
			var a := spin + TAU * float(i) / 3.0
			var c2 := flat + Vector2(-body_r.x * 0.3, -body_r.y * 1.6 - 6.0) + Vector2(cos(a), sin(a) * 0.4) * 9.0
			draw_circle(c2, 2.4, Color(1, 0.95, 0.5, clampf(1.0 - dead_t * 0.6, 0.0, 1.0)))
