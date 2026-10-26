class_name UiMmoForge
extends Control
## Kuźnia na serwerze: wybór receptury i metalu, minigra w trzech etapach (nagrzewanie, kucie, hartowanie)
## oraz zapis run. Ekwipunek i koszty trzyma serwer; klient wysyła wynik minigry, a serwer wylicza jakość.

signal closed

const HEAT_ZONE := Vector2(0.58, 0.78)
const HEAT_TIME := 6.0
const HEAT_NEEDED := 3.0
const HAMMER_STRIKES := 6
const QUENCH_ZONE := Vector2(0.62, 0.78)

var _phase := "select"
var _tab := "forge"
var _kind := "sword"
var _metal := "zelazo"
var _box: VBoxContainer
var _view: UiForge.ForgeView
var _msg: Label
var _bar: Control
var _state := {"metals": ["zelazo", "kurczal"], "runes": [], "gold": 0}
var _heat := 0.0
var _heat_in_zone := 0.0
var _heat_time := 0.0
var _hammer_x := 0.0
var _hammer_dir := 1.0
var _hits: Array = []
var _quench_g := 0.0
var _quench_score := 0.0
var _scores := {"heat": 0.0, "hammer": 0.0, "quench": 0.0}
var _rune_src := {}
var _awaiting := false
var _result: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	var solid := ColorRect.new()
	solid.color = Color(0.07, 0.055, 0.05, 1.0)
	UiKit.full(solid)
	add_child(solid)
	add_child(UiKit.bg_texture(Color(0.08, 0.06, 0.05)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_top = 10.0
	root.offset_bottom = -10.0
	add_child(root)
	root.add_child(UiKit.title("KUŹNIA", 38))
	var tabs := UiKit.hbox(8)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(tabs)
	var t1 := UiKit.button("Kucie", 18)
	t1.pressed.connect(func(): _tab = "forge"; _phase = "select"; _refresh())
	tabs.add_child(t1)
	var t2 := UiKit.button("Zapis run", 18, Color(1.0, 0.85, 0.4))
	t2.pressed.connect(func(): _tab = "runes"; _phase = "select"; _refresh())
	tabs.add_child(t2)
	var body := UiKit.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := UiKit.panel(UiKit.BG, 10)
	body.add_child(left)
	_view = UiForge.ForgeView.new()
	left.add_child(_view)
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	_box = UiKit.vbox(6)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_box)
	_msg = UiKit.label("", 15, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_msg)
	var back := UiKit.button("Wyjdź z kuźni", 20)
	back.pressed.connect(close)
	root.add_child(back)
	Mmo.me_received.connect(func(_i): if _phase == "select": _refresh())
	_refresh()

func close() -> void:
	Audio.play("back")
	closed.emit()

## Anuluje trwającą minigrę (Esc); zwraca true, gdy nic nie było do anulowania i można zamknąć okno.
func cancel_or_close() -> bool:
	if _phase in ["heat", "hammer", "quench"]:
		_msg.text = "Przerwano kucie — nic nie straciłeś."
		_phase = "select"
		_refresh()
		return false
	return true

func apply_state(st: Dictionary) -> void:
	_state = st
	if _phase == "select":
		_refresh()

func apply_result(r: Dictionary) -> void:
	_result = r
	_awaiting = false
	_phase = "result"
	_refresh()

func _count(id: String) -> int:
	var n := 0
	for e in Mmo.my_info.get("inv", []):
		if String(e["id"]) == id:
			n += int(e["n"])
	return n

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()
	_bar = null

func _refresh() -> void:
	_clear()
	match _phase:
		"select":
			if _tab == "forge":
				_build_select()
			else:
				_build_runes()
		"heat": _start_heat()
		"hammer": _start_hammer()
		"quench": _start_quench()
		"result": _build_result()

# -------------------------------------------------------------------- kucie ---

func _build_select() -> void:
	_view.heat = 0.0
	_view.metal = ForgeDB.METALS[_metal]["col"]
	_view.shape = _kind
	_box.add_child(UiKit.label("Co chcesz wykuć?", 18, UiKit.ACCENT))
	var kinds := UiKit.hbox(6)
	_box.add_child(kinds)
	for k in ForgeDB.KINDS:
		var kk := String(k)
		var b := UiKit.button(String(ForgeDB.KINDS[k]["name"]) + ("  ●" if kk == _kind else ""), 17)
		b.pressed.connect(func(): _kind = kk; Audio.play("select"); _refresh())
		kinds.add_child(b)
	_box.add_child(UiKit.label("Z jakiego metalu?", 18, UiKit.ACCENT))
	var metals := UiKit.hbox(6)
	_box.add_child(metals)
	for m in ForgeDB.METALS:
		var mk := String(m)
		var known := mk in (_state.get("metals", []) as Array)
		var mb := UiKit.button(String(ForgeDB.METALS[m]["name"]) + ("  ●" if mk == _metal else ""), 17, ForgeDB.METALS[m]["col"])
		mb.disabled = not known
		mb.tooltip_text = "" if known else "Receptura nieznana — znajdziesz ją w sekretnej jaskini lub poznasz w dalszej części kampanii."
		mb.pressed.connect(func(): _metal = mk; Audio.play("select"); _refresh())
		metals.add_child(mb)
	var result_id := ForgeDB.result_id(_kind, _metal)
	var d := ItemDB.get_data(result_id)
	var head := UiKit.hbox(8)
	_box.add_child(head)
	head.add_child(UiKit.icon(Art.item_icon(result_id, 48), 48))
	var hv := UiKit.vbox(0)
	head.add_child(hv)
	hv.add_child(UiKit.label(String(d.get("name", "?")), 20, ItemDB.rarity_color(result_id)))
	hv.add_child(UiKit.label(String(ItemDB.RARITY_NAMES.get(ItemDB.rarity_of(result_id), "")), 13, ItemDB.rarity_color(result_id)))
	_box.add_child(_wl(String(d.get("desc", "")), 13, UiKit.DIM))
	_box.add_child(UiKit.label("Składniki:", 16, UiKit.ACCENT))
	var cost := ForgeDB.cost(_kind, _metal)
	var can := _metal in (_state.get("metals", []) as Array)
	for id in cost:
		var have := _count(String(id))
		var ok := have >= int(cost[id])
		can = can and ok
		var line := UiKit.hbox(6)
		line.add_child(UiKit.icon(Art.item_icon(String(id), 24), 24))
		line.add_child(UiKit.label("%s: %d / %d" % [String(ItemDB.get_data(String(id)).get("name", id)), have, int(cost[id])], 15, UiKit.GOOD if ok else UiKit.BAD))
		_box.add_child(line)
	var loss := ForgeDB.fail_loss(_kind, _metal)
	var loss_txt := "nic" if loss.is_empty() else ", ".join(loss.keys().map(func(i): return "%s ×%d" % [String(ItemDB.get_data(String(i)).get("name", i)), int(loss[i])]))
	_box.add_child(_wl("Przy porażce stracisz: %s (resztę odzyskasz). Wcześniejsze wyjście niczego nie kosztuje." % loss_txt, 12, UiKit.DIM))
	var go := UiKit.button("Rozpocznij kucie", 22)
	go.disabled = not can
	go.pressed.connect(func():
		Audio.play("confirm")
		Mmo.send_act("forge_start", {"kind": _kind, "metal": _metal})
		_phase = "heat"
		_refresh())
	_box.add_child(go)
	for spec in [["iron", "Kup sztabkę żelaza (30 zł)", 30], ["coal", "Kup węgiel (25 zł)", 25], ["coal5", "Kup 5 węgla (110 zł)", 110]]:
		var key := String(spec[0])
		var bb := UiKit.button(String(spec[1]), 15, UiKit.ACCENT2)
		bb.disabled = int(Mmo.my_info.get("gold", 0)) < int(spec[2])
		bb.pressed.connect(func(): Audio.play("coin"); Mmo.send_act("forge_buy", {"what": key}))
		_box.add_child(bb)
	_box.add_child(UiKit.label("Złoto: %d" % int(Mmo.my_info.get("gold", 0)), 14, Color(1, 0.85, 0.4)))

# ---------------------------------------------------------------------- runy ---

func _sources() -> Array:
	var out: Array = []
	var eq: Dictionary = Mmo.my_info.get("equip", {})
	var eq_m: Dictionary = Mmo.my_info.get("equip_m", {})
	for slot in ItemDB.EQUIP_SLOTS:
		var id := String(eq.get(slot, ""))
		if id != "" and ItemDB.is_gear(id):
			out.append({"kind": "eq", "key": String(slot), "id": id, "meta": eq_m.get(slot, {})})
	var inv: Array = Mmo.my_info.get("inv", [])
	for i in inv.size():
		if ItemDB.is_gear(String(inv[i]["id"])):
			out.append({"kind": "inv", "key": str(i), "id": String(inv[i]["id"]), "meta": inv[i].get("m", {})})
	return out

func _can_pay(word: String) -> bool:
	var c: Dictionary = RuneDB.WORDS[word]["cost"]
	for id in c:
		if id == "gold":
			if int(Mmo.my_info.get("gold", 0)) < int(c[id]):
				return false
		elif _count(String(id)) < int(c[id]):
			return false
	return true

func _build_runes() -> void:
	_view.heat = 0.0
	_box.add_child(UiKit.label("WYBIERZ PRZEDMIOT", 16, UiKit.DIM))
	for s in _sources():
		var sd: Dictionary = s
		var id := String(sd["id"])
		var rar := ItemDB.meta_rarity(id, sd["meta"])
		var sel: bool = not _rune_src.is_empty() and _rune_src["kind"] == sd["kind"] and _rune_src["key"] == sd["key"]
		var row := UiKit.panel(UiKit.BG3 if sel else UiKit.BG2, 6)
		var h := UiKit.hbox(6)
		row.add_child(h)
		h.add_child(UiKit.icon(Art.item_icon(id, 32), 32))
		var v := UiKit.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UiKit.label(String(ItemDB.get_data(id).get("name", id)) + ("  (założone)" if sd["kind"] == "eq" else ""), 14, ItemDB.rarity_color_of(rar)))
		var ws: Array = (sd["meta"] as Dictionary).get("ws", [])
		v.add_child(UiKit.label(String(ItemDB.RARITY_NAMES.get(rar, "")) + ("  ·  " + " ".join(ws) if not ws.is_empty() else ""), 11, UiKit.DIM))
		var b := UiKit.button("Wybierz", 13)
		b.pressed.connect(func(): _rune_src = {"kind": sd["kind"], "key": sd["key"], "id": id, "meta": sd["meta"]}; Audio.play("select"); _refresh())
		h.add_child(b)
		_box.add_child(row)
	if _rune_src.is_empty():
		_box.add_child(_wl("Runy zapisane na przedmiocie zmieniają jego rzadkość, wzmacniają statystyki albo dodają kradzież życia. Wzór słowa poznaje kowal po przekazaniu wzorca (z potworów, skrzyń, jaskiń, bossów albo ze sklepu).", 13, UiKit.DIM))
		return
	_box.add_child(UiKit.label("WYBIERZ SŁOWO", 16, UiKit.DIM))
	for w in RuneDB.WORDS:
		var word := String(w)
		var chk := RuneDB.check(String(_rune_src["id"]), _rune_src["meta"], word)
		var known := word in (_state.get("runes", []) as Array)
		var ok := known and bool(chk["ok"]) and _can_pay(word)
		var row2 := UiKit.panel(UiKit.BG2, 6)
		var v2 := UiKit.vbox(1)
		row2.add_child(v2)
		v2.add_child(UiKit.label(word, 18, UiKit.ACCENT if ok else UiKit.DIM))
		v2.add_child(_wl(String(RuneDB.WORDS[word]["desc"]), 12, UiKit.TEXT))
		v2.add_child(_wl("Koszt: " + RuneDB.cost_text(word), 12, UiKit.GOOD if _can_pay(word) else UiKit.BAD))
		if not known:
			v2.add_child(_wl("Kowal nie zna tego wzoru — potrzebujesz wzorca.", 12, UiKit.BAD))
		elif not bool(chk["ok"]):
			v2.add_child(_wl(String(chk["msg"]), 12, UiKit.BAD))
		var bb := UiKit.button("Zapisz runy", 14)
		bb.disabled = not ok
		bb.pressed.connect(func():
			Audio.play("confirm")
			Mmo.send_act("rune_apply", {"kind": _rune_src["kind"], "key": _rune_src["key"], "word": word})
			_rune_src = {})
		v2.add_child(bb)
		_box.add_child(row2)

# ------------------------------------------------------------------- minigra ---

func _make_bar(zone: Vector2, zone_col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(400, 40)
	c.set_meta("zone", zone)
	c.set_meta("zcol", zone_col)
	c.set_meta("v", 0.0)
	c.set_meta("cursor", -1.0)
	c.draw.connect(func():
		var w := c.size.x
		var h := c.size.y
		c.draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.13, 0.18))
		var z: Vector2 = c.get_meta("zone")
		var zc: Color = c.get_meta("zcol")
		c.draw_rect(Rect2(w * z.x, 0, w * (z.y - z.x), h), Color(zc.r, zc.g, zc.b, 0.55))
		var v := float(c.get_meta("v"))
		if float(c.get_meta("cursor")) >= 0.0:
			var cx := w * float(c.get_meta("cursor"))
			c.draw_rect(Rect2(cx - 3, 0, 6, h), Color(1, 1, 1))
		else:
			c.draw_rect(Rect2(0, 4, w * clampf(v, 0.0, 1.0), h - 8), Color(1.0, 0.55, 0.15, 0.9))
		c.draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0), false, 2.0))
	return c

func _start_heat() -> void:
	_heat = 0.15
	_heat_in_zone = 0.0
	_heat_time = 0.0
	_view.metal = ForgeDB.METALS[_metal]["col"]
	_box.add_child(UiKit.label("ETAP 1/3 — NAGRZEWANIE", 20, UiKit.ACCENT))
	_box.add_child(_wl("Trzymaj SPACJĘ lub przycisk myszy, aby podgrzewać. Utrzymaj żar w pomarańczowej strefie przez %.0f s (z %.0f s)." % [HEAT_NEEDED, HEAT_TIME], 14, UiKit.TEXT))
	_bar = _make_bar(HEAT_ZONE, Color(1.0, 0.6, 0.1))
	_box.add_child(_bar)

func _start_hammer() -> void:
	_hammer_x = 0.0
	_hammer_dir = 1.0
	_hits.clear()
	_view.heat = 0.8
	_box.add_child(UiKit.label("ETAP 2/3 — KUCIE", 20, UiKit.ACCENT))
	_box.add_child(_wl("Naciśnij SPACJĘ lub kliknij, gdy biały znacznik jest w zielonej strefie. Uderzeń: %d." % HAMMER_STRIKES, 14, UiKit.TEXT))
	_bar = _make_bar(Vector2(0.42, 0.58), Color(0.3, 0.9, 0.4))
	_box.add_child(_bar)

func _start_quench() -> void:
	_quench_g = 0.0
	_quench_score = -1.0
	_view.heat = 0.7
	_box.add_child(UiKit.label("ETAP 3/3 — HARTOWANIE", 20, UiKit.ACCENT))
	_box.add_child(_wl("Wanna napełnia się wodą. Naciśnij SPACJĘ lub kliknij, gdy poziom jest w niebieskiej strefie — masz jedną próbę.", 14, UiKit.TEXT))
	_bar = _make_bar(QUENCH_ZONE, Color(0.3, 0.6, 1.0))
	_box.add_child(_bar)

func _score_label(score: float) -> String:
	return "%d%%" % int(score * 100.0)

func _finish_heat() -> void:
	_scores["heat"] = clampf(_heat_in_zone / HEAT_NEEDED, 0.0, 1.0)
	_msg.text = "Nagrzewanie: %s" % _score_label(_scores["heat"])
	_phase = "hammer"
	_refresh()

func _finish_hammer() -> void:
	var sum := 0.0
	for h in _hits:
		sum += float(h)
	_scores["hammer"] = sum / float(HAMMER_STRIKES)
	_msg.text = "Kucie: %s" % _score_label(_scores["hammer"])
	_phase = "quench"
	_refresh()

func _finish_quench() -> void:
	_scores["quench"] = maxf(0.0, _quench_score)
	_view.cooled = 1.0
	Audio.play("drink", 0.7, -2.0)
	var total: float = 0.3 * float(_scores["heat"]) + 0.5 * float(_scores["hammer"]) + 0.2 * float(_scores["quench"])
	_awaiting = true
	_phase = "wait"
	_refresh()
	_box.add_child(UiKit.label("Sprawdzam wynik…", 20, UiKit.ACCENT))
	Mmo.send_act("forge_finish", {"score": total})

func _build_result() -> void:
	var r := _result
	_view.heat = 0.1
	_box.add_child(UiKit.label("WYNIK KUCIA", 22, UiKit.ACCENT))
	_box.add_child(UiKit.label("Nagrzewanie: %s   Kucie: %s   Hartowanie: %s" % [_score_label(_scores["heat"]), _score_label(_scores["hammer"]), _score_label(_scores["quench"])], 14, UiKit.DIM))
	_box.add_child(UiKit.label("Wynik łączny (serwer): %s" % _score_label(float(r.get("score", 0.0))), 18, UiKit.TEXT))
	if bool(r.get("failed", false)):
		_box.add_child(UiKit.label("NIEUDANE!", 30, UiKit.BAD))
		var loss: Dictionary = r.get("loss", {})
		_box.add_child(_wl("Metal pękł. Traci się część składników, resztę odzyskujesz." + ("" if loss.is_empty() else " Utracone: " + ", ".join(loss.keys().map(func(i): return "%s ×%d" % [String(ItemDB.get_data(String(i)).get("name", i)), int(loss[i])]))), 14, UiKit.BAD))
	else:
		var rid := String(r.get("item", ""))
		var head := UiKit.hbox(8)
		_box.add_child(head)
		head.add_child(UiKit.icon(Art.item_icon(rid, 56), 56))
		var hv := UiKit.vbox(0)
		head.add_child(hv)
		hv.add_child(UiKit.label(String(ItemDB.get_data(rid).get("name", "?")), 22, ItemDB.rarity_color(rid)))
		hv.add_child(UiKit.label("Jakość: %s (%.0f%% statystyk)" % [String(r.get("quality", "")), float(r.get("mult", 1.0)) * 100.0], 16, UiKit.GOOD))
		_box.add_child(_wl("Przedmiot trafił do plecaka.", 14, UiKit.DIM))
	var ok := UiKit.button("Dalej", 20)
	ok.pressed.connect(func(): _phase = "select"; _refresh())
	_box.add_child(ok)

# ----------------------------------------------------------------- pętla ---

func _process(delta: float) -> void:
	match _phase:
		"heat":
			var hold := Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			_heat += (0.5 if hold else -0.32) * delta
			_heat = clampf(_heat, 0.0, 1.0)
			if _heat >= HEAT_ZONE.x and _heat <= HEAT_ZONE.y:
				_heat_in_zone += delta
			_heat_time += delta
			_view.heat = _heat
			if _bar:
				_bar.set_meta("v", _heat)
				_bar.queue_redraw()
			if _heat_time >= HEAT_TIME or _heat_in_zone >= HEAT_NEEDED:
				_finish_heat()
		"hammer":
			var spd := 1.3 + 0.18 * float(_hits.size())
			_hammer_x += _hammer_dir * spd * delta
			if _hammer_x >= 1.0:
				_hammer_x = 1.0
				_hammer_dir = -1.0
			elif _hammer_x <= 0.0:
				_hammer_x = 0.0
				_hammer_dir = 1.0
			if _bar:
				_bar.set_meta("cursor", _hammer_x)
				_bar.queue_redraw()
		"quench":
			if _quench_score < 0.0:
				_quench_g += (0.28 + 0.35 * _quench_g) * delta
				if _bar:
					_bar.set_meta("cursor", -1.0)
					_bar.set_meta("v", _quench_g)
					_bar.queue_redraw()
				if _quench_g >= 1.0:
					_quench_score = 0.0
					_msg.text = "Za późno!"
					_finish_quench()

func _action() -> void:
	match _phase:
		"hammer":
			var d := absf(_hammer_x - 0.5)
			var s := 0.05
			var txt := "Chybione"
			if d <= 0.04:
				s = 1.0
				txt = "Idealnie!"
			elif d <= 0.08:
				s = 0.75
				txt = "Dobrze"
			elif d <= 0.16:
				s = 0.4
				txt = "Prawie"
			_hits.append(s)
			_view.swing = 1.0
			_view.spark_burst(int(4 + s * 12.0))
			Audio.play("hit_heavy" if s >= 0.75 else "hit", 0.8 + s * 0.4, -6.0)
			_msg.text = "%s  (uderzenie %d / %d)" % [txt, _hits.size(), HAMMER_STRIKES]
			if _hits.size() >= HAMMER_STRIKES:
				_finish_hammer()
		"quench":
			if _quench_score < 0.0:
				var d2 := absf(_quench_g - (QUENCH_ZONE.x + QUENCH_ZONE.y) * 0.5)
				_quench_score = clampf(1.0 - maxf(0.0, d2 - 0.04) / 0.28, 0.0, 1.0)
				_finish_quench()

func _input(event: InputEvent) -> void:
	if _phase not in ["hammer", "quench"]:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _bar != null and _bar.get_global_rect().grow(120.0).has_point(event.position))
	if pressed:
		get_viewport().set_input_as_handled()
		_action()
