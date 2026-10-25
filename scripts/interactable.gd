class_name Interactable
extends PixelNode
## Obiekt, z którym gracz wchodzi w interakcję klawiszem E (skrzynia, dźwignia, wejście do
## jaskini, portal, dokument, klatka więźnia, skrzynia magazynowa, drogowskaz).
## Ukryte obiekty (hidden) pojawiają się dopiero, gdy gracz jest blisko.

signal activated(who: Node)

var kind := "chest"
var label_text := "Otwórz"
var radius := 78.0
var done := false
var hidden_until_near := false
var reveal_radius := 300.0
var uid := ""
var accent := Color(1.0, 0.8, 0.3)
var _t := 0.0
var _near := 0.0
var _vis := 1.0

func _ready() -> void:
	add_to_group("interactables")
	z_index = 101
	z_as_relative = false

func setup(p_kind: String, p_label: String, p_uid: String = "", hidden: bool = false) -> void:
	kind = p_kind
	label_text = p_label
	uid = p_uid
	hidden_until_near = hidden
	_vis = 0.0 if hidden else 1.0

func can_use() -> bool:
	return not done and _vis > 0.6

func interact(who: Node) -> void:
	if not can_use():
		return
	activated.emit(who)

func _nearest_player() -> Node2D:
	var best: Node2D = null
	var bd := 1.0e9
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if "net_ghost" in p and bool(p.get("net_ghost")):
			continue
		var d := (p as Node2D).global_position.distance_to(global_position)
		if d < bd:
			bd = d
			best = p
	return best

func distance_to_player() -> float:
	var p := _nearest_player()
	return 1.0e9 if p == null else p.global_position.distance_to(global_position)

func _process(delta: float) -> void:
	_t += delta
	var d := distance_to_player()
	_near = move_toward(_near, 1.0 if (d <= radius and can_use()) else 0.0, delta * 6.0)
	if hidden_until_near:
		var target := 1.0 if d <= reveal_radius else 0.0
		if done:
			target = 1.0
		_vis = move_toward(_vis, target, delta * 2.0)
	modulate.a = _vis
	queue_redraw()

func _init() -> void:
	px_origin = Vector2(-76, -100)
	px_w = 38
	px_h = 30

func _draw() -> void:
	if _vis <= 0.01:
		return
	_pbegin()
	match kind:
		"chest": _draw_chest()
		"lever": _draw_lever()
		"entrance": _draw_entrance()
		"portal": _draw_portal()
		"document": _draw_document()
		"cage": _draw_cage()
		"crate": _draw_crate()
		"sign": _draw_sign()
		"lab": _draw_lab()
		"board": _draw_board()
		"door": _draw_door()
		"stairs": _draw_stairs()
		"stash": _draw_stash()
		"herb": _draw_herb()
		"tracks": _draw_tracks()
	_pflush()
	if _near > 0.01:
		var f := ThemeDB.fallback_font
		var txt := "[E] " + label_text
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_rect(Rect2(-w * 0.5 - 8, -82, w + 16, 24), Color(0.05, 0.06, 0.1, 0.85 * _near))
		draw_string(f, Vector2(-w * 0.5, -65), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(accent.r, accent.g, accent.b, _near))

func _glint() -> void:
	if hidden_until_near and not done:
		var a := 0.5 + 0.5 * sin(_t * 5.0)
		_pc(Vector2(0, -30), 22.0 + 4.0 * a, Color(1.0, 0.9, 0.5, 0.12 * a))
		_pc(Vector2(10, -42), 2.0, Color(1, 1, 0.8, 0.9 * a))

func _draw_chest() -> void:
	_pp(PackedVector2Array([Vector2(-26, 0), Vector2(26, 0), Vector2(26, -20), Vector2(-26, -20)]), Color(0.45, 0.28, 0.14))
	var lid_open := 1.0 if done else 0.0
	var lid := PackedVector2Array([Vector2(-27, -20), Vector2(27, -20), Vector2(24, -34 - 10 * lid_open), Vector2(-24, -34 - 10 * lid_open)])
	_pp(lid, Color(0.55, 0.34, 0.17))
	_pr(Rect2(-27, -22, 54, 4), Color(0.85, 0.7, 0.25))
	_pr(Rect2(-4, -26, 8, 10), Color(0.9, 0.8, 0.3))
	_pa(Vector2.ZERO, 30.0, 0.0, PI, 12, Color(0, 0, 0, 0.2), 3.0)
	if done:
		_pc(Vector2(0, -26), 10.0, Color(1.0, 0.9, 0.5, 0.25))
	_glint()

func _draw_lever() -> void:
	_pr(Rect2(-18, -6, 36, 10), Color(0.35, 0.33, 0.36))
	var ang := -0.9 if done else 0.9
	var tip := Vector2(0, -6) + Vector2(0, -40).rotated(ang)
	_pl(Vector2(0, -6), tip, Color(0.6, 0.5, 0.35), 5.0, true)
	_pc(tip, 7.0, Color(0.85, 0.3, 0.25) if not done else Color(0.4, 0.85, 0.45))
	_glint()

func _draw_entrance() -> void:
	var open := 1.0 if done else 0.0
	_pp(PackedVector2Array([Vector2(-44, 4), Vector2(-34, -52), Vector2(0, -74), Vector2(34, -52), Vector2(44, 4)]), Color(0.22, 0.2, 0.22))
	_pp(PackedVector2Array([Vector2(-28, 2), Vector2(-22, -42), Vector2(0, -58), Vector2(22, -42), Vector2(28, 2)]), Color(0.02, 0.02, 0.04, 0.6 + 0.4 * open))
	_pc(Vector2(0, -26), 40.0, Color(0.5, 0.35, 0.9, 0.08 + 0.1 * sin(_t * 3.0)))

func _draw_portal() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	_pc(Vector2(0, -34), 40.0 + 4.0 * pulse, Color(0.4, 0.8, 1.0, 0.18))
	_pa(Vector2(0, -34), 36.0, 0.0, TAU, 40, Color(0.6, 0.95, 1.0, 0.85), 4.0, true)
	_pa(Vector2(0, -34), 24.0, _t * 2.0, _t * 2.0 + 3.5, 20, Color(1, 1, 1, 0.6), 3.0, true)

func _draw_document() -> void:
	_pp(PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(16, -26), Vector2(-16, -26)]), Color(0.92, 0.88, 0.7) if not done else Color(0.6, 0.58, 0.5))
	for i in 4:
		_pl(Vector2(-10, -20 + i * 5), Vector2(10, -20 + i * 5), Color(0.35, 0.3, 0.25), 1.5)
	if not done:
		_pc(Vector2(0, -13), 24.0, Color(1.0, 0.9, 0.5, 0.08 + 0.08 * sin(_t * 4.0)))
	_glint()

func _draw_cage() -> void:
	var col := Color(0.35, 0.34, 0.38)
	if done:
		_pl(Vector2(-26, 0), Vector2(-26, -50), col, 3.0)
		_pl(Vector2(26, 0), Vector2(26, -50), col, 3.0)
		_pl(Vector2(-26, -50), Vector2(26, -62), col, 3.0)
		return
	_pr(Rect2(-28, -52, 56, 52), Color(0.1, 0.1, 0.12, 0.5))
	for i in 5:
		var x := -24.0 + i * 12.0
		_pl(Vector2(x, 0), Vector2(x, -52), col, 3.0)
	_pl(Vector2(-28, -52), Vector2(28, -52), col, 4.0)
	_pl(Vector2(-28, -2), Vector2(28, -2), col, 4.0)
	# więzień w środku
	_pc(Vector2(0, -22), 9.0, Color(0.95, 0.92, 0.82))
	_pc(Vector2(5, -26), 2.0, Color(0.1, 0.1, 0.12))

func _draw_crate() -> void:
	var broken := 1.0 if done else 0.0
	_pr(Rect2(-22, -34, 44, 34), Color(0.5, 0.36, 0.2) if not done else Color(0.35, 0.26, 0.15))
	_pr(Rect2(-22, -34, 44, 34), Color(0.3, 0.2, 0.1), false, 3.0)
	_pl(Vector2(-22, -34), Vector2(22, 0), Color(0.3, 0.2, 0.1), 3.0)
	_pl(Vector2(22, -34), Vector2(-22, 0), Color(0.3, 0.2, 0.1), 3.0)
	if broken > 0.0:
		_pl(Vector2(-22, -34), Vector2(0, -44), Color(0.35, 0.26, 0.15), 3.0)
	_glint()

func _draw_sign() -> void:
	_pl(Vector2(0, 0), Vector2(0, -44), Color(0.45, 0.3, 0.16), 5.0)
	_pp(PackedVector2Array([Vector2(-30, -44), Vector2(30, -44), Vector2(36, -56), Vector2(-30, -56)]), Color(0.6, 0.42, 0.22))
	_pp(PackedVector2Array([Vector2(-30, -38), Vector2(26, -38), Vector2(32, -48), Vector2(-30, -48)]), Color(0.55, 0.38, 0.2))

func _draw_lab() -> void:
	_pr(Rect2(-46, -50, 92, 50), Color(0.2, 0.26, 0.3))
	_pr(Rect2(-46, -50, 92, 8), Color(0.12, 0.16, 0.2))
	_pr(Rect2(-34, -34, 24, 22), Color(0.08, 0.1, 0.14))
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	# kolby
	_pp(PackedVector2Array([Vector2(8, -44), Vector2(22, -44), Vector2(30, -24), Vector2(0, -24)]), Color(0.3, 0.9, 1.0, 0.35 + 0.35 * pulse))
	_pr(Rect2(13, -56, 4, 14), Color(0.7, 0.85, 0.9))
	_pc(Vector2(-22, -24), 7.0, Color(0.8, 0.4, 1.0, 0.5 + 0.3 * pulse))
	_pc(Vector2(15, -62 - 6 * pulse), 3.0, Color(0.5, 1.0, 1.0, 0.5))

func _draw_board() -> void:
	var wood := Color(0.5, 0.34, 0.2)
	_pr(Rect2(-30, -10, 7, 12), wood.darkened(0.2))
	_pr(Rect2(23, -10, 7, 12), wood.darkened(0.2))
	_pr(Rect2(-38, -66, 76, 56), wood)
	_pr(Rect2(-33, -61, 66, 46), Color(0.82, 0.7, 0.48))
	for i in 3:
		var c := Color(0.97, 0.95, 0.85) if i != 1 else Color(0.95, 0.85, 0.55)
		_pr(Rect2(-28 + i * 20, -57 + (i % 2) * 8, 16, 20), c)
		_pc(Vector2(-20 + i * 20, -57 + (i % 2) * 8), 2.0, Color(0.85, 0.2, 0.2))
	var any_ready := false
	for q in SideDB.active():
		if SideDB.is_complete(q):
			any_ready = true
	if any_ready:
		var b := 0.5 + 0.5 * sin(_t * 6.0)
		_pc(Vector2(0, -80 - 3.0 * b), 7.0, Color(1.0, 0.85, 0.3))
	_glint()

func _draw_herb() -> void:
	var g := Color(0.35, 0.72, 0.3)
	for i in 5:
		var a := -PI / 2.0 + (float(i) - 2.0) * 0.45
		_pl(Vector2(0, 0), Vector2(cos(a), sin(a)) * 24.0, g.darkened(0.1 * float(i % 2)), 4.0)
	_pc(Vector2(-8, -22), 5.0, Color(0.95, 0.9, 0.4))
	_pc(Vector2(9, -26), 5.0, Color(0.95, 0.5, 0.7))
	if not done:
		_pc(Vector2(0, -20), 22.0 + 3.0 * sin(_t * 4.0), Color(0.6, 1.0, 0.6, 0.12))

func _draw_tracks() -> void:
	var c := Color(0.35, 0.26, 0.18)
	for i in 3:
		var o := Vector2(-18.0 + float(i) * 16.0, -4.0 - float(i % 2) * 10.0)
		_pc(o, 5.0, c)
		for j in 3:
			_pc(o + Vector2(-6.0 + float(j) * 6.0, -9.0), 2.0, c)
	if not done:
		_pc(Vector2(0, -10), 24.0 + 3.0 * sin(_t * 4.0), Color(1.0, 0.9, 0.5, 0.1))

func _draw_door() -> void:
	var wood := Color(0.42, 0.28, 0.17)
	_pr(Rect2(-30, -76, 60, 78), Color(0.3, 0.3, 0.34))
	_pr(Rect2(-24, -70, 48, 72), wood)
	_pr(Rect2(-24, -70, 48, 8), wood.darkened(0.25))
	_pr(Rect2(-2, -66, 4, 66), wood.darkened(0.4))
	_pc(Vector2(12, -34), 3.0, Color(0.95, 0.8, 0.3))
	if not done:
		var g := 0.5 + 0.5 * sin(_t * 4.0)
		_pc(Vector2(0, -38), 30.0 + 3.0 * g, Color(1.0, 0.9, 0.5, 0.12))

func _draw_stairs() -> void:
	for i in 5:
		var w := 120.0 - float(i) * 16.0
		_pr(Rect2(-w * 0.5, -float(i + 1) * 14.0, w, 14.0), Color(0.62, 0.6, 0.66).lightened(0.05 * float(i)))
	var b := 0.5 + 0.5 * sin(_t * 5.0)
	_pp(PackedVector2Array([Vector2(-14, -92 - 4.0 * b), Vector2(14, -92 - 4.0 * b), Vector2(0, -112 - 4.0 * b)]), Color(1.0, 0.85, 0.3))
	_pc(Vector2(0, -50), 54.0 + 4.0 * b, Color(1.0, 0.9, 0.4, 0.1))

func _draw_stash() -> void:
	var wood := Color(0.5, 0.33, 0.18)
	var iron := Color(0.55, 0.57, 0.64)
	_pr(Rect2(-40, -44, 80, 46), wood)
	_pr(Rect2(-44, -64, 88, 24), wood.lightened(0.08))
	for x in [-30.0, 22.0]:
		_pr(Rect2(x, -64, 8, 66), iron)
	_pr(Rect2(-44, -42, 88, 5), iron)
	_pr(Rect2(-8, -50, 16, 18), Color(0.95, 0.8, 0.3))
	_pr(Rect2(-3, -45, 6, 8), Color(0.1, 0.08, 0.06))
	var g := 0.5 + 0.5 * sin(_t * 3.0)
	_pc(Vector2(0, -34), 38.0 + 2.0 * g, Color(1.0, 0.85, 0.4, 0.1))
