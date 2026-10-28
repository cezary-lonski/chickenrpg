class_name UiMmoLab
extends UiMmoPanel
## Laboratorium na serwerze: synteza pierwiastka BU (minigra: zjadanie jąder atomowych poświęconej broni) i warzenie sztabki kurczalium (mieszanie kotła). Wyniki sprawdza i księguje serwer.

const KURCZALIUM_COST := {"wegiel": 1, "krysztal_cienia": 1, "sztabka_kurczalu": 2, "pierwiastek_bu": 3}
const TIME_LIMIT := 30.0
const ARENA := Vector2(900, 360)
const STORY := [
	{"text": "Rozpalasz ogień pod kotłem i wrzucasz kawałek węgla. Kocioł syczy i puszcza czarny dym — mieszaj, żeby się nie przypalił!", "col": Color(0.25, 0.22, 0.24)},
	{"text": "Diament rozpuszcza się w gęstniejącej mazi i cała zawartość zaczyna lśnić fioletem. Mieszaj dalej!", "col": Color(0.5, 0.3, 0.8)},
	{"text": "Dwie sztabki kurczalu topią się w srebrną ciecz. Kury w całej wsi gdaczą ze strachu. Mieszaj mocniej!", "col": Color(0.7, 0.75, 0.85)},
	{"text": "Na koniec wpuszczasz trzy pierwiastki BU. Kocioł huczy, bąble pękają tęczą… Mieszaj, aż wszystko zastygnie w kurczalium!", "col": Color(1.0, 0.7, 0.2)},
]
const STIR_TURNS := 1.6

var _phase := "menu"
var _gold := 0
var _arena: Control
var _info: Label
# jądra
var _item_idx := -1
var _tier_bonus := 3
var _atoms: Array = []
var _total := 0
var _eaten := 0
var _t := 0.0
var _pp := Vector2.ZERO
# kocioł
var _stage := 0
var _stir := 0.0
var _last_a := 0.0
var _have_a := false
var _bubbles: Array = []

func _init() -> void:
	super._init("LABORATORIUM")

func apply_state(data: Dictionary) -> void:
	_gold = int(data.get("gold", _gold))
	if _box != null and _phase == "menu":
		_menu()

func _build() -> void:
	Mmo.me_received.connect(func(_i): if _phase == "menu": _menu())
	_menu()

func cancel_or_close() -> bool:
	if _phase != "menu":
		_msg.text = "Przerwano — nic nie straciłeś."
		_phase = "menu"
		_menu()
		return false
	return true

func _menu() -> void:
	_phase = "menu"
	_clear()
	_arena = null
	_gold = int(Mmo.my_info.get("gold", _gold))
	_box.add_child(UiKit.label("SYNTEZA PIERWIASTKA BU", 20, UiKit.ACCENT))
	_box.add_child(_wl("Aby wytworzyć BU, POŚWIĘĆ broń (rzadką lub lepszą) z plecaka: zjedz wszystkie jądra atomowe, nim minie czas. 1 broń daje 1 BU, a sztabka kurczalium kosztuje 3 BU.", 14, UiKit.DIM))
	var any := false
	var inv: Array = Mmo.my_info.get("inv", [])
	for i in inv.size():
		var id := String(inv[i]["id"])
		var rar := ItemDB.rarity_of(id)
		if not ItemDB.bu_sacrifice_ok(id):
			continue
		any = true
		var row := UiKit.panel(UiKit.BG2, 8)
		_box.add_child(row)
		var h := UiKit.hbox(8)
		row.add_child(h)
		h.add_child(UiKit.icon(Art.item_icon(id, 40), 40))
		var v := UiKit.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UiKit.label(String(ItemDB.get_data(id).get("name", "?")), 16, ItemDB.rarity_color(id)))
		v.add_child(UiKit.label(String(ItemDB.RARITY_NAMES.get(rar, "")) + " → 1 BU", 12, UiKit.DIM))
		var b := UiKit.button("Poświęć", 16, UiKit.BAD)
		var idx := i
		b.pressed.connect(func(): Audio.play("deny"); _start_eat(idx, rar))
		h.add_child(b)
	if not any:
		_box.add_child(_wl("Nie masz w plecaku broni rzadkiej lub lepszej (założone nie liczą się — zdejmij je).", 14, UiKit.BAD))
	_box.add_child(UiKit.sep(10))
	_box.add_child(UiKit.label("WYTWARZANIE KURCZALIUM", 20, UiKit.ACCENT))
	_box.add_child(_wl("Receptura: węgiel + diament + 2 sztabki kurczalu + 3 pierwiastki BU = sztabka kurczalium.", 14, UiKit.DIM))
	var can := true
	for id in KURCZALIUM_COST:
		var have := _count(String(id))
		var ok := have >= int(KURCZALIUM_COST[id])
		can = can and ok
		var line := UiKit.hbox(6)
		line.add_child(UiKit.icon(Art.item_icon(String(id), 24), 24))
		line.add_child(UiKit.label("%s: %d / %d" % [String(ItemDB.get_data(String(id)).get("name", id)), have, int(KURCZALIUM_COST[id])], 15, UiKit.GOOD if ok else UiKit.BAD))
		_box.add_child(line)
	var mk := UiKit.button("Stwórz sztabkę kurczalium", 20, Color(0.8, 0.45, 1.0))
	mk.disabled = not can
	mk.pressed.connect(_start_kociol)
	_box.add_child(mk)
	var buy := UiKit.button("Kup węgiel (25 zł)", 15, UiKit.ACCENT2)
	buy.disabled = _gold < 25
	buy.pressed.connect(func(): Audio.play("coin"); Mmo.send_act("lab_buy"))
	_box.add_child(buy)
	_box.add_child(UiKit.label("Złoto: %d" % _gold, 14, Color(1, 0.85, 0.4)))

func _make_arena(draw_cb: Callable) -> void:
	_clear()
	_arena = Control.new()
	_arena.custom_minimum_size = ARENA
	_arena.draw.connect(draw_cb)
	_box.add_child(_arena)

# ------------------------------------------------------------ minigra: jądra ---

func _start_eat(idx: int, rar: String) -> void:
	_item_idx = idx
	_tier_bonus = 3
	_total = 10 + _tier_bonus * 2
	_eaten = 0
	_t = 0.0
	_pp = ARENA * 0.5
	_atoms.clear()
	for i in _total:
		_atoms.append({"p": Vector2(randf_range(60, ARENA.x - 60), randf_range(60, ARENA.y - 60)), "v": Vector2.from_angle(randf() * TAU) * randf_range(10, 35)})
	Mmo.send_act("lab_start")
	_phase = "eat"
	_clear()
	_box.add_child(UiKit.label("ZJEDZ WSZYSTKIE JĄDRA", 20, UiKit.ACCENT))
	_info = _wl("Steruj myszą (lub WASD) i pochłoń jądra przedmiotu. Jądra uciekają, gdy się zbliżysz!", 14, UiKit.TEXT)
	_box.add_child(_info)
	_arena = Control.new()
	_arena.custom_minimum_size = ARENA
	_arena.draw.connect(_draw_eat)
	_box.add_child(_arena)

func _draw_eat() -> void:
	if _arena == null:
		return
	_arena.draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0.03, 0.05, 0.08))
	for a in _atoms:
		_arena.draw_circle(a["p"], 9.0, Color(1.0, 0.8, 0.3))
		_arena.draw_circle(a["p"], 15.0, Color(1.0, 0.8, 0.3, 0.15))
	_arena.draw_circle(_pp, 22.0, Color(0.4, 0.95, 0.85, 0.9))
	_arena.draw_arc(_pp, 28.0, 0.0, TAU, 24, Color(0.7, 1.0, 0.95, 0.6), 2.0)

func _process_eat(delta: float) -> void:
	_t += delta
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move != Vector2.ZERO:
		_pp += move * 260.0 * delta
	elif _arena != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pp = _pp.move_toward(_arena.get_local_mouse_position(), 320.0 * delta)
	_pp = _pp.clamp(Vector2(20, 20), ARENA - Vector2(20, 20))
	for a in _atoms:
		var d: Vector2 = a["p"] - _pp
		if d.length() < 150.0:
			a["v"] = a["v"].lerp(d.normalized() * 120.0, 0.08)
		a["p"] += a["v"] * delta
		if a["p"].x < 20 or a["p"].x > ARENA.x - 20:
			a["v"].x = -a["v"].x
		if a["p"].y < 20 or a["p"].y > ARENA.y - 20:
			a["v"].y = -a["v"].y
		a["p"] = a["p"].clamp(Vector2(15, 15), ARENA - Vector2(15, 15))
	var before := _atoms.size()
	_atoms = _atoms.filter(func(a): return (a["p"] as Vector2).distance_to(_pp) > 26.0)
	_eaten += before - _atoms.size()
	if _info != null:
		_info.text = "Jąder: %d / %d   ·   czas: %.0f s" % [_eaten, _total, maxf(0.0, TIME_LIMIT - _t)]
	_arena.queue_redraw()
	if _atoms.is_empty() or _t >= TIME_LIMIT:
		Mmo.send_act("lab_bu", {"idx": _item_idx, "ratio": float(_eaten) / float(_total), "secs": _t})
		_msg.text = "Wybuch! Przedmiot zamienia się w pierwiastek BU (zjedzone jądra: %d%%)." % int(100.0 * float(_eaten) / float(_total))
		_phase = "menu"
		_menu()

# ----------------------------------------------------------------- kocioł ---

func _start_kociol() -> void:
	_stage = 0
	_stir = 0.0
	_have_a = false
	_bubbles.clear()
	Mmo.send_act("lab_start")
	_phase = "kociol"
	_clear()
	_box.add_child(UiKit.label("KOCIOŁ KURCZALIUM", 20, UiKit.ACCENT))
	_info = _wl(String(STORY[0]["text"]), 15, UiKit.TEXT)
	_box.add_child(_info)
	_arena = Control.new()
	_arena.custom_minimum_size = ARENA
	_arena.draw.connect(_draw_kociol)
	_box.add_child(_arena)

func _draw_kociol() -> void:
	if _arena == null:
		return
	var c := ARENA * 0.5
	_arena.draw_rect(Rect2(Vector2.ZERO, ARENA), Color(0.06, 0.05, 0.07))
	var liq: Color = STORY[mini(_stage, STORY.size() - 1)]["col"]
	_arena.draw_circle(c, 130.0, Color(0.15, 0.13, 0.15))
	_arena.draw_circle(c, 112.0, liq)
	for b in _bubbles:
		_arena.draw_circle(c + b["p"], float(b["r"]), Color(1, 1, 1, 0.35))
	var ang := _stir * TAU
	_arena.draw_line(c, c + Vector2.from_angle(ang) * 105.0, Color(0.7, 0.5, 0.3), 8.0, true)
	var k := clampf(_stir / STIR_TURNS, 0.0, 1.0)
	_arena.draw_rect(Rect2(c.x - 150, ARENA.y - 40, 300, 16), Color(0.15, 0.15, 0.2))
	_arena.draw_rect(Rect2(c.x - 150, ARENA.y - 40, 300.0 * k, 16), Color(1.0, 0.7, 0.2))

func _process_kociol(delta: float) -> void:
	var c := ARENA * 0.5
	var turned := 0.0
	var keys := (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
	if keys != 0.0:
		turned = absf(keys) * 0.55 * delta
	elif _arena != null:
		var m := _arena.get_local_mouse_position() - c
		if m.length() > 30.0:
			var a := m.angle()
			if _have_a:
				turned = absf(angle_difference(_last_a, a)) / TAU
			_last_a = a
			_have_a = true
	_stir += minf(turned, 0.02)
	for b in _bubbles:
		b["r"] = float(b["r"]) + delta * 6.0
	_bubbles = _bubbles.filter(func(b): return float(b["r"]) < 14.0)
	if randf() < 0.3:
		_bubbles.append({"p": Vector2.from_angle(randf() * TAU) * randf_range(0, 90), "r": 3.0})
	if _stir >= STIR_TURNS:
		_stage += 1
		_stir = 0.0
		Audio.play("coin", 0.8 + 0.12 * float(_stage), -4.0)
		if _stage >= STORY.size():
			Mmo.send_act("lab_kurcz")
			_msg.text = "Kocioł ucichł — sprawdzam, czy powstała sztabka kurczalium…"
			_phase = "menu"
			_menu()
			return
		_info.text = String(STORY[_stage]["text"])
	_arena.queue_redraw()

func _process(delta: float) -> void:
	match _phase:
		"eat": _process_eat(delta)
		"kociol": _process_kociol(delta)
