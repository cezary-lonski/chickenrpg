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
	"sep": {"kind": "bird", "body": Vector2(23, 19), "head": 10.5, "neck": 4.0, "tail": "fan", "comb": 0.0, "wattle": 0.0, "beak": 1.5, "leg": 1.05},
	"sowa": {"kind": "bird", "body": Vector2(19, 17), "head": 13.0, "neck": 2.0, "tail": "wedge", "comb": 0.0, "wattle": 0.0, "beak": 0.7, "leg": 0.9},
	"sowa_wieszczka": {"kind": "bird", "body": Vector2(21, 19), "head": 15.0, "neck": 2.0, "tail": "long", "comb": 0.0, "wattle": 0.0, "beak": 0.75, "leg": 0.95},
	"sep_cesarski": {"kind": "bird", "body": Vector2(27, 23), "head": 13.0, "neck": 4.0, "tail": "fan", "comb": 0.0, "wattle": 0.0, "beak": 1.7, "leg": 1.15},
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
var spin_angle := 0.0
var spin_speed := 0.0
var remote_spin := false
var berserk := 0.0
## wygląd z kreatora (kolory, ubrania, emblemat) i wyposażenie widoczne na postaci
var look: Dictionary = {}
var gear: Dictionary = {}
var custom_anims: Dictionary = {}
var _anim_name := ""
var _anim_t := 0.0
var anim_hold := -1.0   # >= 0: zatrzymaj animację na tym czasie (edytor)
var anim_speed := 1.0
var support := 0.0            # 0..1: aura wsparcia (leczenie/ochrona), płynnie rośnie i gaśnie
var support_col := Color(0.5, 1.0, 0.7)
var _tail_rot := 0.0
var _tail_off := Vector2.ZERO

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

func apply_appearance(app: Dictionary) -> void:
	look = app.duplicate(true) if not app.is_empty() else {}
	queue_redraw()

func set_gear(g: Dictionary) -> void:
	gear = g
	queue_redraw()

func set_anim(anim_name: String) -> void:
	if anim_name == _anim_name:
		return
	_anim_name = anim_name
	_anim_t = 0.0

func has_anim(anim_name: String) -> bool:
	return custom_anims.has(anim_name)

## Przesunięcie/obrót części z aktywnej animacji użytkownika: Vector3(x, y, rot)
func _pf(part: String) -> Vector3:
	if _anim_name == "" or not custom_anims.has(_anim_name):
		return Vector3.ZERO
	var v := CosmeticDB.sample(custom_anims[_anim_name], part, _anim_t)
	return Vector3(v[0], v[1], v[2])

func _death_playing() -> bool:
	if not dead or not custom_anims.has("death"):
		return false
	return dead_t < float((custom_anims["death"] as Dictionary).get("duration", 0.8))

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
	_rb_t -= delta
	if _rb_t <= 0.0:
		_rebuild = true
		_rb_t = REBUILD_EVERY
	_anim_t = anim_hold if anim_hold >= 0.0 else _anim_t + delta * anim_speed
	if remote_spin and absf(spin_speed) > 0.01 and not dead:
		spin_angle = fmod(spin_angle + spin_speed * delta, TAU)
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
	var over: Dictionary = look.get("colors", {})
	if over.has(key) and String(over[key]) != "":
		return Color.html(String(over[key]))
	if key == "shade" and over.has("body") and String(over["body"]) != "":
		return Color.html(String(over["body"])).darkened(0.16)
	return pal.get(key, fallback)

# ------------------------------------------------------------------ rysunek --

func _draw() -> void:
	_begin_pixels()
	var fx := -1.0 if facing < 0.0 else 1.0
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

	# --- cień (nie obraca się razem z piruetem)
	_xf_set(Vector2.ZERO, 0.0, Vector2(fx, 1.0))
	var shadow_a := 0.0 if not grounded else 0.22
	if shadow_a > 0.0:
		_pp(_ellipse(Vector2(0, -1), Vector2(16 * s, 4.5 * s)), Color(0, 0, 0, shadow_a))

	# --- obrót wokół środka tułowia (piruet / szał)
	var spin := 0.0 if dead else spin_angle
	if is_zero_approx(spin):
		_xf_set(Vector2.ZERO, 0.0, Vector2(fx, 1.0))
	else:
		var pivot := Vector2(0.0, -((18.0 + neck * 0.25) * s + body_r.y * 0.85))
		_xf_set(pivot - pivot.rotated(spin), spin, Vector2(fx, 1.0))

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
	# animacje użytkownika (addytywne)
	var pb := _pf("body")
	var ph := _pf("head")
	var pw := _pf("wing")
	var pl := _pf("legs")
	var pt := _pf("tail")
	var pwp := _pf("weapon")
	body_c += Vector2(pb.x, pb.y) * s
	head_c += Vector2(pb.x, pb.y) * s
	head_c = body_c + (head_c - body_c).rotated(ph.z + pb.z * 0.6) + Vector2(ph.x, ph.y) * s
	_tail_rot = pt.z + pb.z
	_tail_off = Vector2(pt.x, pt.y) * s

	# --- martwy: leży na boku
	if dead and not _death_playing():
		_draw_corpse(P, s, body_c, body_r, head_c, head_r, body_col, shade_col, beak_col, leg_col)
		_flush_pixels()
		return

	# --- aura szału bojowego
	if berserk > 0.01:
		_draw_rage(body_c, body_r, s, berserk)

	if support > 0.02:
		_draw_support(body_c, body_r, s)

	# --- aura wyposażenia (np. fioletowe płomienie hiperlegendarnej zbroi)
	if String(gear.get("aura", "")) != "":
		_draw_flame_aura(body_c, body_r, s, String(gear["aura"]) == "gold_flame", float(gear.get("aura_radius", 0.0)))

	# --- peleryna / plecak (za postacią)
	var back_cl: Dictionary = look.get("clothes", {}).get("back", {})
	if not back_cl.is_empty():
		_draw_back_cloth(String(back_cl.get("id", "")), body_c, body_r, s, Color.html(String(back_cl.get("main", "#ffffff"))), Color.html(String(back_cl.get("trim", "#ffffff"))))

	# --- tylne skrzydło
	var wing_shoulder := body_c + Vector2(-body_r.x * 0.15, -body_r.y * 0.15) + Vector2(pw.x, pw.y) * s
	var flap_ang := lerpf(-0.15, -1.15, flap) + sin(_walk * 2.0) * 0.12 * float(moving) + arm * 0.5 - arm_back * 0.6 + pw.z
	_draw_wing(wing_shoulder, body_r.x, body_r.y, s, flap_ang, shade_col.darkened(0.08), true)

	# --- nogi
	var leg_swing := sin(_walk + PI) * 6.0 * s * (1.0 if moving else 0.0) + pl.x * s
	for side in [-1.0, 1.0]:
		var hip := body_c + Vector2(side * body_r.x * 0.28, body_r.y * 0.7 + pl.y * s)
		var knee := hip + Vector2(leg_swing * 0.5 * side + side * 2.0 * s, leg_len * 0.5)
		var foot := Vector2(hip.x + leg_swing * side + side * 3.0 * s, -2.0 * s)
		var w := 2.6 * s * float(P["leg"])
		_pl(hip, knee, leg_col.darkened(0.15), w, true)
		_pl(knee, foot, leg_col, w, true)
		# stopa
		var toe_dir := 1.0
		for i in 3:
			var t := float(i) - 1.0
			_pl(foot, foot + Vector2(toe_dir * 5.0 * s, t * 2.0 * s), leg_col, w * 0.8, true)
		_pl(foot, foot + Vector2(-toe_dir * 2.5 * s, 0), leg_col, w * 0.8, true)
		if gear.has("boots"):
			_pp(_ellipse(foot + Vector2(1.5 * s, -2.0 * s), Vector2(5.5 * s, 3.4 * s), 10), (gear["boots"] as Dictionary).get("col", Color(0.4, 0.3, 0.2)))

	# --- ogon
	_draw_tail(P, s, body_c, body_r, body_col, shade_col)

	# --- tułów
	_pp(_ellipse(body_c, body_r), body_col)
	# pierś jaśniejsza
	_pp(_ellipse(body_c + Vector2(body_r.x * 0.22, body_r.y * 0.12), Vector2(body_r.x * 0.62, body_r.y * 0.72)), body_col.lightened(0.06))
	# brzuch w cieniu
	_pp(_ellipse(body_c + Vector2(0, body_r.y * 0.5), Vector2(body_r.x * 0.8, body_r.y * 0.45)), shade_col)

	_draw_emblem(body_c, body_r)
	if gear.has("armor"):
		_draw_armor(gear["armor"], body_c, body_r, s)

	# --- szyja
	var neck_dir := (head_c - body_c).normalized()
	_pl(body_c + neck_dir * body_r.x * 0.2, head_c, body_col, body_r.y * 0.75, true)
	var neck_cl: Dictionary = look.get("clothes", {}).get("neck", {})
	if not neck_cl.is_empty():
		_draw_neck_cloth(String(neck_cl.get("id", "")), body_c, body_r, head_c, neck_dir, s, Color.html(String(neck_cl.get("main", "#ffffff"))), Color.html(String(neck_cl.get("trim", "#ffffff"))))
	if gear.has("amulet"):
		_draw_amulet(gear["amulet"], body_c, body_r, neck_dir, s)

	# --- grzbiet / czubek (kury)
	if is_chicken and float(P["comb"]) > 0.0:
		_draw_comb(head_c, head_r, comb_col, float(P["comb"]) * s)

	# --- głowa
	_pp(_ellipse(head_c, Vector2(head_r, head_r * 0.95)), body_col)
	# --- dziób
	_draw_beak(head_c, head_r, beak_col, float(P["beak"]) * s, is_chicken)
	# --- wolek
	if is_chicken and float(P["wattle"]) > 0.0:
		var ws := float(P["wattle"]) * s
		_pp(_ellipse(head_c + Vector2(head_r * 0.55, head_r * 0.62), Vector2(2.6 * ws, 3.4 * ws)), comb_col)
	# --- oko
	var eye_now := Color(1.0, 0.14, 0.06) if berserk > 0.05 else eye_col
	var eye_pos := head_c + Vector2(head_r * 0.3 + _look * head_r * 0.12, -head_r * 0.12)
	if _blink <= 0.0:
		var er := maxf(head_r * 0.26, CELL * 0.75)
		_pc(eye_pos, er, eye_now)
		_pc(eye_pos + Vector2(er * 0.55, -er * 0.55), CELL * 0.35, Color(1, 1, 1, 1))
	else:
		_pl(eye_pos + Vector2(-CELL, 0), eye_pos + Vector2(CELL, 0), eye_now, CELL)

	var head_cl: Dictionary = look.get("clothes", {}).get("head", {})
	if not head_cl.is_empty():
		_draw_hat(String(head_cl.get("id", "")), head_c, head_r, s, Color.html(String(head_cl.get("main", "#ffffff"))), Color.html(String(head_cl.get("trim", "#ffffff"))))
	if gear.has("helmet"):
		_draw_helmet(gear["helmet"], head_c, head_r, s)

	# --- przednie skrzydło (atakujące)
	var front_shoulder := wing_shoulder + Vector2(body_r.x * 0.1, -1.0 * s)
	_draw_wing(front_shoulder, body_r.x, body_r.y, s, flap_ang, shade_col.lightened(0.05), false)
	if gear.has("armor"):
		_pc(front_shoulder + Vector2(1.0, 0.0) * s, body_r.x * 0.3, (gear["armor"] as Dictionary).get("col", Color(0.7, 0.7, 0.75)).darkened(0.1))
	if gear.has("prop"):
		_draw_prop(String((gear["prop"] as Dictionary).get("kind", "")), front_shoulder, body_r, s, flap_ang)
	if gear.has("weapon"):
		var hand := front_shoulder + Vector2(body_r.x * 0.95, body_r.y * 0.55).rotated(flap_ang)
		_draw_weapon(gear["weapon"], hand, s, -1.0 + arm * 1.8 - arm_back * 0.5 + pwp.z + pw.z * 0.4, Vector2(pwp.x, pwp.y) * s)

	if charge_t > 0.0:
		var r := 26.0 * s * (0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.02))
		_pa(body_c, r, 0, TAU, 20, Color(1.0, 0.5, 0.25, 0.35 + 0.35 * charge_t), 3.0, true)
		_pa(body_c, r * 0.6, 0, TAU, 16, Color(1.0, 0.85, 0.4, 0.25 + 0.35 * charge_t), 2.0, true)
	_flush_pixels()

func _draw_rage(body_c: Vector2, body_r: Vector2, s: float, amount: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 0.5 + 0.5 * sin(t * 16.0)
	var glow := body_c + Vector2(0.0, body_r.y * 0.78)
	_pp(_ellipse(glow, Vector2(body_r.x * 1.25, body_r.y * 0.32)), Color(1.0, 0.12, 0.04, 0.10 + 0.10 * amount))
	for i in 6:
		var a := t * 5.0 + TAU * float(i) / 6.0
		var base := body_c + Vector2(cos(a) * body_r.x * 1.15, sin(a) * body_r.y * 0.55 + body_r.y * 0.25)
		var h := (9.0 + 8.0 * pulse + 5.0 * sin(t * 11.0 + float(i))) * s
		var tip := base + Vector2(cos(a) * 6.0 * s, -h)
		var mid := (base + tip) * 0.5 + Vector2(sin(t * 9.0 + float(i)) * 3.0 * s, 0.0)
		_pl(base, mid, Color(1.0, 0.18, 0.03, 0.30 * amount), 4.0 * s, true)
		_pl(mid, tip, Color(1.0, 0.42, 0.06, 0.42 * amount), 2.5 * s, true)
		_pc(tip, 2.6 * s, Color(1.0, 0.65, 0.12, 0.38 * amount))
	for j in 2:
		var a0 := t * 13.0 + PI * float(j)
		_pa(body_c, body_r.x * (1.45 + 0.22 * float(j)), a0, a0 + 1.45, 16,
			Color(1.0, 0.24, 0.06, 0.20 + 0.16 * pulse), 2.5 * s, true)

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
	_pp(pts, c)
	_pl(shoulder, tip, c.darkened(0.25), 1.5 * s, true)

func _draw_tail(P: Dictionary, s: float, body_c: Vector2, body_r: Vector2, body_col: Color, shade_col: Color) -> void:
	var style := String(P["tail"])
	var base := body_c + Vector2(-body_r.x * 0.85, -body_r.y * 0.1) + _tail_off
	var col := shade_col
	match style:
		"feather":
			for i in 3:
				var a := deg_to_rad(200.0 - i * 12.0) + lean * 0.2 + _tail_rot
				var len := (14.0 - i * 2.0) * s
				var tip := base + Vector2(cos(a), sin(a)) * len
				var w := 3.2 * s
				var perp := Vector2(-sin(a), cos(a)) * w
				_pp(_poly([base, tip + perp, tip - perp]), col.lightened(0.05 * i))
		"long":
			for i in 4:
				var a := deg_to_rad(196.0 - i * 9.0) + lean * 0.2 + _tail_rot
				var len := (20.0 - i * 2.5) * s
				var tip := base + Vector2(cos(a), sin(a)) * len
				var w := 3.0 * s
				var perp := Vector2(-sin(a), cos(a)) * w
				_pp(_poly([base, tip + perp, tip - perp]), col.darkened(0.05 * i))
		"wedge":
			_pp(_poly([
				base,
				base + Vector2(-16.0, -6.0) * s,
				base + Vector2(-20.0, 2.0) * s,
				base + Vector2(-8.0, 5.0) * s,
			]), col.darkened(0.1))
			_pp(_poly([
				base + Vector2(-4.0, 0),
				base + Vector2(-15.0, -3.0) * s,
				base + Vector2(-16.0, 1.0) * s,
			]), col.lightened(0.08))
		"fan":
			for i in 7:
				var t := float(i) / 6.0
				var a := deg_to_rad(168.0 - t * 66.0) + lean * 0.2 + _tail_rot
				var len := (16.0 + sin(t * PI) * 8.0) * s
				var tip := base + Vector2(cos(a), sin(a)) * len
				var w := 4.0 * s
				var perp := Vector2(-sin(a), cos(a)) * w
				_pp(_poly([base, tip + perp, tip - perp]), col.darkened(0.02 * i))
				# jasna krawędź pióra
				_pl(tip - perp, tip + perp, body_col.lightened(0.1), 1.0, true)

func _draw_beak(head_c: Vector2, head_r: float, col: Color, sz: float, is_chicken: bool) -> void:
	var o := head_c + Vector2(head_r * 0.55, head_r * 0.05)
	if is_chicken:
		_pp(_poly([
			o,
			o + Vector2(sz * 1.15, sz * 0.32),
			o + Vector2(sz * 0.35, sz * 0.75),
		]), col)
		_pl(o + Vector2(sz * 0.15, sz * 0.3), o + Vector2(sz * 0.95, sz * 0.34), col.darkened(0.25), 1.2)
	else:
		# dłuższy, ostrzejszy dziób ptaka
		_pp(_poly([
			o + Vector2(0, -sz * 0.18),
			o + Vector2(sz * 1.5, sz * 0.12),
			o + Vector2(0, sz * 0.5),
		]), col)
		_pl(o + Vector2(0, sz * 0.12), o + Vector2(sz * 1.4, sz * 0.14), col.darkened(0.3), 1.1)

func _draw_comb(head_c: Vector2, head_r: float, col: Color, sz: float) -> void:
	for i in 3:
		var x := head_c.x + (i - 1.0) * head_r * 0.42
		var h := head_r * (0.42 + 0.16 * (1.0 if i == 1 else 0.0)) * sz
		_pp(_ellipse(Vector2(x, head_c.y - head_r * 0.78 - h * 0.35), Vector2(head_r * 0.26 * sz, h * 0.6), 10), col)
	_pp(_poly([
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
	_pp(_poly([
		flat + Vector2(-body_r.x * 0.9, 0),
		flat + Vector2(-body_r.x * 0.2, -body_r.y * 0.9 * k - 3.0),
		flat + Vector2(body_r.x * 0.2, -body_r.y * 0.7 * k - 2.0),
		flat + Vector2(-body_r.x * 0.5, 4.0),
	]), shade_col.lightened(0.05))
	_pp(_ellipse(flat, Vector2(body_r.x, body_r.y * 0.8)), c)
	var h := flat + Vector2(body_r.x * 0.85 + head_r * 0.5, -head_r * 0.3)
	_pp(_ellipse(h, Vector2(head_r, head_r * 0.9)), c)
	_pl(h + Vector2(head_r * 0.3, -head_r * 0.1), h + Vector2(head_r * 0.7, -head_r * 0.35), Color(0, 0, 0, 0.75), 2.0)
	_pl(h + Vector2(head_r * 0.3, -head_r * 0.3), h + Vector2(head_r * 0.7, -head_r * 0.05), Color(0, 0, 0, 0.75), 2.0)
	# nóżki w powietrzu
	_pl(flat + Vector2(-body_r.x * 0.2, 0), flat + Vector2(-body_r.x * 0.4, -14.0 * s - 8.0 * k), leg_col, 2.6 * s, true)
	_pl(flat + Vector2(-body_r.x * 0.2, 0), flat + Vector2(body_r.x * 0.1, -12.0 * s - 6.0 * k), leg_col, 2.6 * s, true)
	# gwiazdki
	if dead_t > 0.1:
		var spin := dead_t * 3.0
		for i in 3:
			var a := spin + TAU * float(i) / 3.0
			var c2 := flat + Vector2(-body_r.x * 0.3, -body_r.y * 1.6 - 6.0) + Vector2(cos(a), sin(a) * 0.4) * 9.0
			_pc(c2, 2.4, Color(1, 0.95, 0.5, clampf(1.0 - dead_t * 0.6, 0.0, 1.0)))


# -------------------------------------------------------- ubrania i wyposażenie ---

func _draw_emblem(body_c: Vector2, body_r: Vector2) -> void:
	var em: Array = look.get("emblem", [])
	var n := CosmeticDB.EMBLEM_SIZE
	if em.size() < n * n:
		return
	var cell := body_r.x * 0.95 / float(n)
	var origin := body_c + Vector2(body_r.x * 0.2, body_r.y * 0.05) - Vector2(n, n) * cell * 0.5
	for i in n * n:
		var c := String(em[i])
		if c == "":
			continue
		_pr(Rect2(origin + Vector2(i % n, i / n) * cell, Vector2(cell + 0.2, cell + 0.2)), Color.html(c))

func _dome(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	_pp(pts, col)

func _draw_hat(id: String, head_c: Vector2, hr: float, s: float, main: Color, trim: Color) -> void:
	match id:
		"czapka":
			_dome(head_c + Vector2(0, -hr * 0.18), hr * 1.04, hr * 1.0, main)
			_pr(Rect2(head_c + Vector2(-hr * 1.04, -hr * 0.3), Vector2(hr * 2.08, hr * 0.28)), trim)
			_pc(head_c + Vector2(0, -hr * 1.28), hr * 0.3, trim)
		"cylinder":
			_pp(_ellipse(head_c + Vector2(0, -hr * 0.82), Vector2(hr * 1.35, hr * 0.26), 14), main.darkened(0.1))
			_pr(Rect2(head_c + Vector2(-hr * 0.7, -hr * 2.05), Vector2(hr * 1.4, hr * 1.25)), main)
			_pr(Rect2(head_c + Vector2(-hr * 0.7, -hr * 1.1), Vector2(hr * 1.4, hr * 0.26)), trim)
		"korona":
			var base := head_c + Vector2(0, -hr * 0.85)
			_pr(Rect2(base + Vector2(-hr * 0.8, -hr * 0.3), Vector2(hr * 1.6, hr * 0.42)), main)
			for i in 3:
				var x := -hr * 0.6 + hr * 0.6 * float(i)
				_pp(PackedVector2Array([base + Vector2(x - hr * 0.26, -hr * 0.3), base + Vector2(x, -hr * 0.85), base + Vector2(x + hr * 0.26, -hr * 0.3)]), main)
				_pc(base + Vector2(x, -hr * 0.88), hr * 0.12, trim)
		"chustka":
			var band := PackedVector2Array([head_c + Vector2(-hr * 0.98, -hr * 0.3), head_c + Vector2(hr * 0.9, -hr * 0.42), head_c + Vector2(hr * 0.9, -hr * 0.12), head_c + Vector2(-hr * 0.98, 0.0)])
			_pp(band, main)
			_pp(PackedVector2Array([head_c + Vector2(-hr * 0.98, -hr * 0.15), head_c + Vector2(-hr * 1.7, -hr * 0.5), head_c + Vector2(-hr * 1.5, hr * 0.2)]), trim)

func _draw_neck_cloth(id: String, body_c: Vector2, body_r: Vector2, head_c: Vector2, neck_dir: Vector2, s: float, main: Color, trim: Color) -> void:
	var a := body_c + neck_dir * body_r.x * 0.5
	var b := head_c - neck_dir * 3.0 * s
	match id:
		"szalik":
			_pl(a, b, main, body_r.y * 0.62, true)
			_pl(a.lerp(b, 0.3), a.lerp(b, 0.35), trim, body_r.y * 0.64, true)
			_pl(a.lerp(b, 0.65), a.lerp(b, 0.7), trim, body_r.y * 0.64, true)
			var sway := sin(_walk * 2.0) * 2.0 * s * (1.0 if moving else 0.4)
			_pp(PackedVector2Array([a + Vector2(-2, 0) * s, a + Vector2(-9 * s + sway, 9 * s), a + Vector2(-4 * s + sway, 11 * s), a + Vector2(3, 2) * s]), main)
		"muszka":
			var m := a.lerp(b, 0.55)
			_pp(PackedVector2Array([m, m + Vector2(-6, -4) * s, m + Vector2(-6, 4) * s]), main)
			_pp(PackedVector2Array([m, m + Vector2(6, -4) * s, m + Vector2(6, 4) * s]), main)
			_pc(m, 2.0 * s, trim)

func _draw_back_cloth(id: String, body_c: Vector2, body_r: Vector2, s: float, main: Color, trim: Color) -> void:
	match id:
		"peleryna":
			var wave := sin(_walk * 1.5) * 3.0 * s * (1.0 if moving else 0.3)
			var top := body_c + Vector2(-body_r.x * 0.1, -body_r.y * 0.75)
			var pts := PackedVector2Array([
				top, top + Vector2(body_r.x * 0.35, body_r.y * 0.3),
				body_c + Vector2(-body_r.x * 0.9 + wave, body_r.y * 1.25),
				body_c + Vector2(-body_r.x * 1.7 + wave * 1.4, body_r.y * 0.9),
			])
			_pp(pts, main)
			_pl(pts[3], pts[2], trim, 2.0 * s, true)
		"plecak":
			var o := body_c + Vector2(-body_r.x * 1.0, -body_r.y * 0.45)
			_pr(Rect2(o, Vector2(body_r.x * 0.75, body_r.y * 1.1)), main)
			_pr(Rect2(o, Vector2(body_r.x * 0.75, body_r.y * 0.35)), trim)
			_pl(o + Vector2(body_r.x * 0.7, 2.0 * s), body_c + Vector2(body_r.x * 0.1, -body_r.y * 0.1), trim, 1.5 * s, true)

func _draw_armor(v: Dictionary, body_c: Vector2, body_r: Vector2, s: float) -> void:
	var col: Color = v.get("col", Color(0.7, 0.7, 0.75))
	_pp(_ellipse(body_c + Vector2(body_r.x * 0.1, body_r.y * 0.05), Vector2(body_r.x * 0.78, body_r.y * 0.82), 18), col.darkened(0.1))
	_pp(_ellipse(body_c + Vector2(body_r.x * 0.16, -body_r.y * 0.02), Vector2(body_r.x * 0.62, body_r.y * 0.64), 16), col)
	_pa(body_c + Vector2(body_r.x * 0.1, body_r.y * 0.05), body_r.x * 0.78, 0.0, TAU, 20, col.darkened(0.35), 1.6 * s, true)
	_pl(body_c + Vector2(body_r.x * 0.16, -body_r.y * 0.6), body_c + Vector2(body_r.x * 0.16, body_r.y * 0.6), col.lightened(0.25), 1.4 * s, true)
	var trim: Color = v.get("trim", Color(0, 0, 0, 0))
	if trim.a > 0.0:
		_pa(body_c + Vector2(body_r.x * 0.16, -body_r.y * 0.02), body_r.x * 0.62, 0.0, TAU, 20, trim, 1.4 * s, true)

func _draw_helmet(v: Dictionary, head_c: Vector2, hr: float, s: float) -> void:
	var col: Color = v.get("col", Color(0.7, 0.7, 0.75))
	_dome(head_c + Vector2(0, -hr * 0.08), hr * 1.06, hr * 1.05, col)
	_pr(Rect2(head_c + Vector2(-hr * 1.06, -hr * 0.12), Vector2(hr * 2.12, hr * 0.2)), col.darkened(0.25))
	_pl(head_c + Vector2(hr * 0.1, -hr * 1.1), head_c + Vector2(hr * 0.1, -hr * 0.15), col.lightened(0.25), 1.5 * s, true)

func _draw_amulet(v: Dictionary, body_c: Vector2, body_r: Vector2, neck_dir: Vector2, s: float) -> void:
	var col: Color = v.get("col", Color(0.4, 0.9, 1.0))
	var start := body_c + neck_dir * body_r.x * 0.45 + Vector2(-2.0, 0.0) * s
	var gem := body_c + Vector2(body_r.x * 0.5, -body_r.y * 0.02)
	_pl(start, gem, Color(0.85, 0.75, 0.4), 1.2 * s, true)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	_pc(gem, 4.8 * s, Color(col.r, col.g, col.b, 0.22 + 0.16 * pulse))
	_pc(gem, 2.9 * s, col)
	_pc(gem + Vector2(-0.8, -0.8) * s, 1.0 * s, Color(1, 1, 1, 0.85))

func _draw_weapon(v: Dictionary, hand: Vector2, s: float, ang: float, off: Vector2) -> void:
	var col: Color = v.get("col", Color(0.8, 0.82, 0.88))
	var style := String(v.get("style", "sword"))
	var h := hand + off
	var d := Vector2.RIGHT.rotated(ang)
	var perp := Vector2(-d.y, d.x)
	match style:
		"club":
			_pl(h - d * 3.0 * s, h + d * 22.0 * s, Color(0.45, 0.3, 0.18), 3.6 * s, true)
			_pc(h + d * 22.0 * s, 4.2 * s, Color(0.4, 0.27, 0.16))
		"fork":
			_pl(h - d * 3.0 * s, h + d * 18.0 * s, Color(0.5, 0.36, 0.2), 2.2 * s, true)
			for i in 3:
				var o := perp * (float(i) - 1.0) * 3.0 * s
				_pl(h + d * 18.0 * s + o, h + d * 27.0 * s + o, col, 1.6 * s, true)
			_pl(h + d * 18.0 * s - perp * 3.0 * s, h + d * 18.0 * s + perp * 3.0 * s, col, 1.6 * s, true)
		"staff":
			_pl(h - d * 6.0 * s, h + d * 30.0 * s, Color(0.5, 0.36, 0.2), 2.4 * s, true)
			_pc(h + d * 31.0 * s, 3.6 * s, col)
		"spear":
			var sl := float(v.get("len", 34.0)) * s
			_pl(h - d * 8.0 * s, h + d * sl, Color(0.5, 0.36, 0.2), 2.2 * s, true)
			_pp(PackedVector2Array([h + d * sl + perp * 3.0 * s, h + d * (sl + 10.0 * s), h + d * sl - perp * 3.0 * s]), col)
		"bow":
			var bl := float(v.get("len", 22.0)) * s
			_pa(h + d * 6.0 * s, bl * 0.55, ang - 1.2, ang + 1.2, 10, col, 2.4 * s, true)
			_pl(h + d * 6.0 * s + perp * bl * 0.5, h + d * 6.0 * s - perp * bl * 0.5, Color(0.9, 0.9, 0.85), 0.9 * s, true)
		_:
			_pl(h - d * 4.0 * s, h + d * 2.0 * s, Color(0.45, 0.3, 0.18), 2.6 * s, true)
			_pl(h + d * 2.0 * s - perp * 4.5 * s, h + d * 2.0 * s + perp * 4.5 * s, Color(0.85, 0.7, 0.3), 2.2 * s, true)
			var blade_len := float(v.get("len", 24.0)) * s
			_pp(PackedVector2Array([h + d * 2.0 * s + perp * 2.2 * s, h + d * blade_len, h + d * 2.0 * s - perp * 2.2 * s]), col)
			_pl(h + d * 3.0 * s, h + d * (blade_len - 2.0 * s), col.lightened(0.35), 1.0 * s, true)
	if bool(v.get("glow", false)):
		_pc(h + d * 16.0 * s, 9.0 * s, Color(col.r, col.g, col.b, 0.16))

func _draw_flame_aura(body_c: Vector2, body_r: Vector2, s: float, gold: bool = false, big_r: float = 0.0) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if big_r > 0.0:
		_draw_sun_aura(body_c, big_r, gold, t)
	var pulse := 0.5 + 0.5 * sin(t * 9.0)
	_pp(_ellipse(body_c + Vector2(0.0, body_r.y * 0.7), Vector2(body_r.x * 1.2, body_r.y * 0.3)), (Color(1.0, 0.8, 0.2, 0.16) if gold else Color(0.6, 0.15, 0.95, 0.14)))
	for i in 7:
		var a := t * 3.0 + TAU * float(i) / 7.0
		var base := body_c + Vector2(cos(a) * body_r.x * 1.05, sin(a) * body_r.y * 0.5 + body_r.y * 0.3)
		var h := (8.0 + 7.0 * pulse + 4.0 * sin(t * 8.0 + float(i) * 1.7)) * s
		var tip := base + Vector2(sin(t * 6.0 + float(i)) * 3.0 * s, -h)
		var mid := (base + tip) * 0.5 + Vector2(cos(t * 7.0 + float(i)) * 2.5 * s, 0.0)
		_pl(base, mid, (Color(1.0, 0.6, 0.1, 0.34) if gold else Color(0.55, 0.12, 0.9, 0.32)), 3.6 * s, true)
		_pl(mid, tip, (Color(1.0, 0.92, 0.5, 0.5) if gold else Color(0.85, 0.45, 1.0, 0.45)), 2.2 * s, true)
		_pc(tip, 2.2 * s, (Color(1.0, 1.0, 0.8, 0.45) if gold else Color(0.95, 0.7, 1.0, 0.4)))

func _draw_support(body_c: Vector2, body_r: Vector2, s: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var a := support
	var c := support_col
	for i in 3:
		var ph := fposmod(t * 0.9 + float(i) / 3.0, 1.0)
		var r := body_r.x * (1.1 + 1.6 * ph)
		_pa(body_c, r, 0.0, TAU, 40, Color(c.r, c.g, c.b, (1.0 - ph) * 0.55 * a), 3.0 * s, true)
	for i in 6:
		var ang := t * 1.6 + TAU * float(i) / 6.0
		var rise := fposmod(t * 0.7 + float(i) * 0.31, 1.0)
		var p := body_c + Vector2(cos(ang) * body_r.x * 1.3, body_r.y * 0.9 - rise * body_r.y * 3.0)
		_pc(p, 2.4 * s, Color(c.r, c.g, c.b, (1.0 - rise) * 0.8 * a))
	_pc(body_c, body_r.x * 1.35, Color(c.r, c.g, c.b, 0.08 * a))


# ---------------------------------------------------------------- piksele ---
## Postać jest rysowana jako prawdziwy pixel art: wszystkie kształty trafiają do siatki
## komórek (CELL px), dostają płaskie cieniowanie (jasna góra-lewo, ciemny dół-prawo)
## i czarny kontur, a gotowy sprite jest jedną teksturą. Odświeża się ~20 razy na sekundę.

const CELL := 4.0
const GW := 80
const GH := 96
const GOX := -160.0
const GOY := -264.0
const REBUILD_EVERY := 0.1
const OUTLINE := Color(0.05, 0.04, 0.07, 1.0)

var _img: Image
var _tex: ImageTexture
var _bytes := PackedByteArray()
var _kind := PackedByteArray()      # 0 puste, 1 półprzezroczyste, 2 pełne
var _xf := Transform2D.IDENTITY
var _drawn_once := false
static var _budget_frame := -1
static var _budget_left := 0
var _rebuild := true
var _painting := false
var _rb_t := 0.0
var _bx0 := GW
var _bx1 := -1
var _by0 := GH
var _by1 := -1

func _begin_pixels() -> void:
	_xf = Transform2D.IDENTITY
	if _img == null:
		_bytes.resize(GW * GH * 4)
		_kind.resize(GW * GH)
		_img = Image.create(GW, GH, false, Image.FORMAT_RGBA8)
		_tex = ImageTexture.create_from_image(_img)
		_rb_t = randf() * REBUILD_EVERY
		_rebuild = true
	_painting = _rebuild
	if _painting and _drawn_once:
		# oszczędzamy CPU: ograniczona liczba odświeżeń na klatkę i brak odświeżania poza ekranem
		var fr := Engine.get_process_frames()
		if fr != _budget_frame:
			_budget_frame = fr
			_budget_left = 3
		var o := get_global_transform_with_canvas().origin
		var vs := get_viewport_rect().size
		if _budget_left <= 0 or o.x < -400.0 or o.y < -300.0 or o.x > vs.x + 400.0 or o.y > vs.y + 500.0:
			_painting = false
		else:
			_budget_left -= 1
	if _painting:
		_drawn_once = true
		_bytes.fill(0)
		_kind.fill(0)
		_bx0 = GW
		_bx1 = -1
		_by0 = GH
		_by1 = -1

func _flush_pixels() -> void:
	if _painting:
		_outline_pass()
		_img.set_data(GW, GH, false, Image.FORMAT_RGBA8, _bytes)
		_tex.update(_img)
		_painting = false
		_rebuild = false
	elif _rebuild and _drawn_once:
		pass
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect(_tex, Rect2(Vector2(GOX, GOY), Vector2(GW, GH) * CELL), false)

func _outline_pass() -> void:
	if _bx1 < 0:
		return
	var x0 := maxi(0, _bx0 - 1)
	var x1 := mini(GW - 1, _bx1 + 1)
	var y0 := maxi(0, _by0 - 1)
	var y1 := mini(GH - 1, _by1 + 1)
	var mark: Array = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var i := y * GW + x
			if _kind[i] == 2:
				continue
			if (x > 0 and _kind[i - 1] == 2) or (x < GW - 1 and _kind[i + 1] == 2) or (y > 0 and _kind[i - GW] == 2) or (y < GH - 1 and _kind[i + GW] == 2):
				mark.append(i)
	for i in mark:
		_write(i, OUTLINE, 2)
	# błysk trafienia: biały nalot na całym sprite'ie
	if flash_t > 0.0:
		var a := clampf(flash_t / 0.12, 0.0, 1.0) * 0.7
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var i := y * GW + x
				if _kind[i] == 2:
					var o := i * 4
					_bytes[o] = int(lerpf(float(_bytes[o]), 255.0, a))
					_bytes[o + 1] = int(lerpf(float(_bytes[o + 1]), 255.0, a))
					_bytes[o + 2] = int(lerpf(float(_bytes[o + 2]), 255.0, a))

func _write(i: int, col: Color, kind: int) -> void:
	var o := i * 4
	_bytes[o] = int(col.r * 255.0 + 0.5)
	_bytes[o + 1] = int(col.g * 255.0 + 0.5)
	_bytes[o + 2] = int(col.b * 255.0 + 0.5)
	_bytes[o + 3] = int(col.a * 255.0 + 0.5)
	_kind[i] = kind

func _put(x: int, y: int, col: Color) -> void:
	if x < 0 or y < 0 or x >= GW or y >= GH:
		return
	var i := y * GW + x
	if col.a >= 0.9:
		_write(i, col, 2)
	elif _kind[i] != 2:
		_write(i, col, 1)
	else:
		return
	if x < _bx0: _bx0 = x
	if x > _bx1: _bx1 = x
	if y < _by0: _by0 = y
	if y > _by1: _by1 = y

func _xf_set(pos: Vector2, rot: float, scl: Vector2) -> void:
	_xf = Transform2D(rot, scl, 0.0, pos)

func _to_cells(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var w := _xf * p
		out.append(Vector2((w.x - GOX) / CELL, (w.y - GOY) / CELL))
	return out

## Wypełnia wielokąt (w komórkach); ciemniejszy dół-prawo, jaśniejsza góra-lewo.
func _fill_cells(q: PackedVector2Array, col: Color, shade: bool) -> void:
	var n := q.size()
	if n < 3:
		return
	var minx := INF
	var maxx := -INF
	var miny := INF
	var maxy := -INF
	for p in q:
		if p.x < minx: minx = p.x
		if p.x > maxx: maxx = p.x
		if p.y < miny: miny = p.y
		if p.y > maxy: maxy = p.y
	var w := maxx - minx
	var h := maxy - miny
	var opaque := col.a >= 0.9
	var do_shade := shade and opaque and w >= 4.0 and h >= 4.0
	var tones: Array = [col, col.lightened(0.14), col.darkened(0.16)]
	var tb: Array = []
	for t in tones:
		tb.append([int(t.r * 255.0 + 0.5), int(t.g * 255.0 + 0.5), int(t.b * 255.0 + 0.5), int(t.a * 255.0 + 0.5)])
	var kind_new := 2 if opaque else 1
	var any := false
	var y0 := maxi(0, int(floor(miny)))
	var y1 := mini(GH - 1, int(ceil(maxy)))
	var inv_w := 1.0 / maxf(w, 0.001)
	var inv_h := 1.0 / maxf(h, 0.001)
	var xs: Array[float] = []
	for y in range(y0, y1 + 1):
		var yc := float(y) + 0.5
		xs.clear()
		var prev := q[n - 1]
		for i in n:
			var cur := q[i]
			if (prev.y <= yc and cur.y > yc) or (cur.y <= yc and prev.y > yc):
				xs.append(prev.x + (yc - prev.y) / (cur.y - prev.y) * (cur.x - prev.x))
			prev = cur
		xs.sort()
		var k := 0
		var vy := (yc - miny) * inv_h
		while k + 1 < xs.size():
			var sx := maxi(0, int(ceil(xs[k] - 0.5)))
			var ex := mini(GW - 1, int(floor(xs[k + 1] - 0.5)))
			for x in range(sx, ex + 1):
				var ti := 0
				if do_shade:
					var t := ((float(x) + 0.5 - minx) * inv_w + vy) * 0.5
					if t < 0.27:
						ti = 1
					elif t > 0.78:
						ti = 2
				var i2 := y * GW + x
				if not opaque and _kind[i2] == 2:
					continue
				var o := i2 * 4
				var c: Array = tb[ti]
				_bytes[o] = c[0]
				_bytes[o + 1] = c[1]
				_bytes[o + 2] = c[2]
				_bytes[o + 3] = c[3]
				_kind[i2] = kind_new
				any = true
			if ex >= sx:
				if sx < _bx0: _bx0 = sx
				if ex > _bx1: _bx1 = ex
				if y < _by0: _by0 = y
				if y > _by1: _by1 = y
			k += 2
	if not any:
		_put(int(floor((minx + maxx) * 0.5)), int(floor((miny + maxy) * 0.5)), col)

func _pp(pts: PackedVector2Array, col: Color) -> void:
	if _painting:
		_fill_cells(_to_cells(pts), col, true)

func _pc(c: Vector2, r: float, col: Color) -> void:
	if _painting:
		_fill_cells(_to_cells(_ellipse(c, Vector2(r, r), 12)), col, r >= CELL * 2.0)

func _pl(a: Vector2, b: Vector2, col: Color, width: float = 1.0, _aa: bool = false) -> void:
	if not _painting:
		return
	var d := b - a
	if d.length() < 0.01:
		return
	var nrm := Vector2(-d.y, d.x).normalized() * maxf(width, CELL * 0.95) * 0.5
	_fill_cells(_to_cells(PackedVector2Array([a + nrm, b + nrm, b - nrm, a - nrm])), col, false)

func _pr(r: Rect2, col: Color) -> void:
	if _painting:
		_fill_cells(_to_cells(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])), col, false)

func _pa(c: Vector2, r: float, a0: float, a1: float, pts: int, col: Color, width: float = 1.0, _aa: bool = false) -> void:
	if not _painting:
		return
	var prev := c + Vector2(cos(a0), sin(a0)) * r
	for i in range(1, pts + 1):
		var a := lerpf(a0, a1, float(i) / float(pts))
		var cur := c + Vector2(cos(a), sin(a)) * r
		_pl(prev, cur, col, width)
		prev = cur

## Ogromna aura: płomienne słońce (złote) albo fioletowy wir, z obracającymi się promieniami i językami ognia.
func _draw_sun_aura(c: Vector2, r: float, gold: bool, t: float) -> void:
	var core := Color(1.0, 0.95, 0.55) if gold else Color(0.9, 0.6, 1.0)
	var mid := Color(1.0, 0.75, 0.2) if gold else Color(0.65, 0.25, 0.95)
	var edge := Color(1.0, 0.5, 0.1) if gold else Color(0.4, 0.1, 0.8)
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	_pc(c, r * (1.0 + 0.06 * pulse), Color(edge.r, edge.g, edge.b, 0.14))
	_pc(c, r * 0.78, Color(mid.r, mid.g, mid.b, 0.18))
	_pc(c, r * 0.5, Color(core.r, core.g, core.b, 0.24))
	# promienie
	var rays := 14
	for i in rays:
		var a := t * 0.9 + TAU * float(i) / float(rays)
		var len := r * (1.25 + 0.25 * sin(t * 5.0 + float(i) * 1.3))
		var p0 := c + Vector2(cos(a), sin(a)) * r * 0.72
		var p1 := c + Vector2(cos(a), sin(a)) * len
		_pl(p0, p1, Color(mid.r, mid.g, mid.b, 0.42), r * 0.13, true)
		_pc(p1, r * 0.06, Color(core.r, core.g, core.b, 0.6))
	# języki ognia unoszące się wokół
	for i in 12:
		var a2 := t * 2.2 + TAU * float(i) / 12.0
		var base := c + Vector2(cos(a2) * r * 0.85, sin(a2) * r * 0.55)
		var h := r * (0.45 + 0.25 * sin(t * 7.0 + float(i) * 2.1))
		_pl(base, base + Vector2(sin(t * 6.0 + float(i)) * r * 0.08, -h), Color(edge.r, edge.g, edge.b, 0.5), r * 0.1, true)
		_pl(base, base + Vector2(0.0, -h * 0.6), Color(core.r, core.g, core.b, 0.55), r * 0.05, true)

## Rekwizyty niesione przez wrogów (księga, taca, pędzel…), zależnie od przebrania.
func _draw_prop(kind: String, shoulder: Vector2, body_r: Vector2, s: float, ang: float) -> void:
	var hand := shoulder + Vector2(body_r.x * 0.9, body_r.y * 0.4).rotated(ang)
	match kind:
		"book":
			_pr(Rect2(hand + Vector2(-6, -14) * s, Vector2(13, 10) * s), Color(0.2, 0.3, 0.65))
			_pr(Rect2(hand + Vector2(-4, -12) * s, Vector2(9, 6) * s), Color(0.95, 0.92, 0.8))
		"tome":
			_pr(Rect2(hand + Vector2(-9, -18) * s, Vector2(19, 15) * s), Color(0.45, 0.18, 0.15))
			_pr(Rect2(hand + Vector2(-7, -16) * s, Vector2(15, 11) * s), Color(0.9, 0.85, 0.65))
			_pr(Rect2(hand + Vector2(-1, -16) * s, Vector2(2, 11) * s), Color(0.4, 0.3, 0.2))
		"tray":
			_pl(hand + Vector2(-9, -9) * s, hand + Vector2(10, -9) * s, Color(0.85, 0.87, 0.92), 3.0 * s, true)
			_pc(hand + Vector2(0, -13) * s, 5.0 * s, Color(0.9, 0.9, 0.95))
		"brush":
			_pl(hand + Vector2(-2, 0) * s, hand + Vector2(12, -16) * s, Color(0.5, 0.35, 0.2), 2.4 * s, true)
			_pc(hand + Vector2(13, -17) * s, 3.4 * s, Color(0.85, 0.2, 0.25))
		"frame":
			_pr(Rect2(hand + Vector2(-10, -22) * s, Vector2(20, 24) * s), Color(0.85, 0.7, 0.25))
			_pr(Rect2(hand + Vector2(-7, -19) * s, Vector2(14, 18) * s), Color(0.35, 0.3, 0.5))
