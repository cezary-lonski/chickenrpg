class_name UiForge
extends Control
## Kuźnia: wybór receptury i metalu, potem minigra w trzech etapach:
## nagrzewanie (trzymaj spację/mysz), kucie (trafiaj w środek) i hartowanie (jeden strzał).
## Wynik minigry wyznacza jakość przedmiotu. Przedmiot powstaje dopiero po zakończeniu.

signal on_close

var _phase := "select"
var _kind := "sword"
var _metal := "zelazo"
var _box: VBoxContainer
var _view: ForgeView
var _msg: Label
var _bar: Control
var _t := 0.0

# stan minigry
var _heat := 0.0
var _heat_in_zone := 0.0
var _heat_time := 0.0
var _hammer_x := 0.0
var _hammer_dir := 1.0
var _hits: Array = []
var _quench_g := 0.0
var _quench_score := 0.0
var _scores := {"heat": 0.0, "hammer": 0.0, "quench": 0.0}
var _result: Dictionary = {}
var _holding := false

const HEAT_ZONE := Vector2(0.58, 0.78)
const HEAT_TIME := 6.0
const HEAT_NEEDED := 3.0
const HAMMER_STRIKES := 6
const QUENCH_ZONE := Vector2(0.62, 0.78)

# ---------------------------------------------------------------- widok ---

class ForgeView extends Control:
	var heat := 0.0        # 0..1: żar przedmiotu
	var swing := 0.0       # 0..1: animacja młota
	var metal := Color(0.75, 0.78, 0.85)
	var shape := "sword"
	var glow_boost := 0.0
	var sparks: Array = []
	var cooled := 0.0      # 0..1: hartowanie (para)

	func _init() -> void:
		custom_minimum_size = Vector2(400, 300)
		clip_contents = true

	func spark_burst(n: int) -> void:
		for i in n:
			sparks.append({"p": Vector2(size.x * 0.5, size.y * 0.62), "v": Vector2(randf_range(-160, 160), randf_range(-240, -60)), "t": randf_range(0.3, 0.7)})

	func _process(delta: float) -> void:
		for s in sparks:
			s["t"] -= delta
			s["v"].y += 520.0 * delta
			s["p"] += s["v"] * delta
		sparks = sparks.filter(func(s): return s["t"] > 0.0)
		swing = maxf(0.0, swing - delta * 5.0)
		cooled = maxf(0.0, cooled - delta * 0.8)
		queue_redraw()

	func _hot_color() -> Color:
		var h := clampf(heat, 0.0, 1.0)
		if h < 0.35:
			return metal.lerp(Color(0.7, 0.2, 0.1), h / 0.35)
		return Color(0.7, 0.2, 0.1).lerp(Color(1.0, 0.85, 0.5), (h - 0.35) / 0.65)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.09, 0.07, 0.07))
		# palenisko
		var fc := Vector2(w * 0.18, h * 0.62)
		draw_rect(Rect2(fc.x - 50, fc.y - 20, 100, 70), Color(0.2, 0.17, 0.16))
		var fl := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.012)
		var fcol := Color(1.0, 0.45 + 0.2 * fl, 0.1, 0.9)
		draw_colored_polygon(PackedVector2Array([fc + Vector2(-34, -4), fc + Vector2(-12, -44 * fl - 20), fc + Vector2(10, -4)]), fcol)
		draw_colored_polygon(PackedVector2Array([fc + Vector2(0, -4), fc + Vector2(18, -52 * fl - 14), fc + Vector2(40, -4)]), fcol)
		draw_circle(fc + Vector2(0, -8), 60.0, Color(1.0, 0.5, 0.1, 0.07 + 0.05 * fl + 0.1 * clampf(heat, 0, 1)))
		# kowadło
		var ac := Vector2(w * 0.62, h * 0.7)
		draw_rect(Rect2(ac.x - 38, ac.y + 10, 76, 46), Color(0.25, 0.25, 0.3))
		draw_colored_polygon(PackedVector2Array([ac + Vector2(-90, -6), ac + Vector2(70, -6), ac + Vector2(50, 20), ac + Vector2(-34, 20), ac + Vector2(-60, 12)]), Color(0.42, 0.44, 0.5))
		draw_rect(Rect2(ac.x - 90, ac.y - 12, 160, 8), Color(0.55, 0.57, 0.63))
		# przedmiot na kowadle
		var col := _hot_color()
		var pc := ac + Vector2(-10, -22)
		match shape:
			"sword":
				draw_colored_polygon(PackedVector2Array([pc + Vector2(-70, -4), pc + Vector2(60, -8), pc + Vector2(82, 0), pc + Vector2(60, 8), pc + Vector2(-70, 6)]), col)
				draw_rect(Rect2(pc.x - 84, pc.y - 12, 14, 22), col.darkened(0.3))
			"armor":
				draw_colored_polygon(PackedVector2Array([pc + Vector2(-48, -10), pc + Vector2(-20, -18), pc + Vector2(20, -18), pc + Vector2(48, -10), pc + Vector2(40, 8), pc + Vector2(-40, 8)]), col)
			_:
				draw_circle(pc, 18.0, col)
				draw_circle(pc, 8.0, col.lightened(0.3))
		if heat > 0.4:
			draw_circle(pc, 60.0, Color(col.r, col.g, col.b, 0.1 * heat))
		# młot
		var ang := lerpf(-1.1, 0.35, swing)
		var hd := Vector2.RIGHT.rotated(ang)
		var handle_start := ac + Vector2(30, -80)
		draw_line(handle_start, handle_start + hd * 78.0 + Vector2(-30, 40), Color(0.5, 0.35, 0.2), 6.0, true)
		var hend := handle_start + hd * 78.0 + Vector2(-30, 40)
		draw_rect(Rect2(hend.x - 20, hend.y - 12, 40, 24), Color(0.5, 0.52, 0.58))
		# iskry
		for s in sparks:
			draw_circle(s["p"], 2.4, Color(1.0, 0.8, 0.3, clampf(float(s["t"]) * 2.0, 0.0, 1.0)))
		# para po hartowaniu
		if cooled > 0.0:
			for i in 7:
				var x := ac.x - 60 + float(i) * 22.0
				draw_circle(Vector2(x + sin(Time.get_ticks_msec() * 0.004 + i) * 6.0, ac.y - 50 - (1.0 - cooled) * 50.0 - float(i % 3) * 8.0), 10.0, Color(0.85, 0.9, 1.0, 0.25 * cooled))

# --------------------------------------------------------------- interfejs ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.08, 0.06, 0.05)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.5)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_top = 10.0
	root.offset_bottom = -10.0
	add_child(root)
	root.add_child(UiKit.title("KUŹNIA", 40))
	var body := UiKit.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := UiKit.panel(UiKit.BG, 10)
	body.add_child(left)
	_view = ForgeView.new()
	left.add_child(_view)
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv := UiKit.vbox(6)
	right.add_child(rv)
	_box = UiKit.vbox(6)
	_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(_box)
	_msg = UiKit.label("", 15, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_msg)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wyjdź z kuźni", 20)
	back.pressed.connect(_leave)
	row.add_child(back)
	_enter("select")

func _leave() -> void:
	Audio.play("back")
	on_close.emit()

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _clear_box() -> void:
	for c in _box.get_children():
		c.queue_free()

# -------------------------------------------------------------------- fazy ---

func _enter(phase: String) -> void:
	_phase = phase
	_t = 0.0
	_clear_box()
	_bar = null
	match phase:
		"select": _build_select()
		"heat": _start_heat()
		"hammer": _start_hammer()
		"quench": _start_quench()
		"result": _build_result()

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
		b.pressed.connect(func(): _kind = kk; Audio.play("select"); _enter("select"))
		kinds.add_child(b)
	_box.add_child(UiKit.label("Z jakiego metalu?", 18, UiKit.ACCENT))
	var metals := UiKit.hbox(6)
	_box.add_child(metals)
	for m in ForgeDB.METALS:
		var mk := String(m)
		var known := ForgeDB.metal_known(mk)
		var mb := UiKit.button(String(ForgeDB.METALS[m]["name"]) + ("  ●" if mk == _metal else ""), 17, ForgeDB.METALS[m]["col"])
		mb.disabled = not known
		mb.tooltip_text = "" if known else "Receptura nieznana — znajdziesz ją w sekretnej jaskini lub poznasz w dalszej części kampanii."
		mb.pressed.connect(func(): _metal = mk; Audio.play("select"); _enter("select"))
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
	var st: Dictionary = d.get("stats", {})
	var parts: Array = []
	for k in st:
		parts.append("%s %s" % [String(UiLoadout.STAT_NAMES.get(k, k)), ("%+.0f" % float(st[k])) if k in ["health", "energy"] else ("%+.0f%%" % (float(st[k]) * 100.0))])
	if not parts.is_empty():
		_box.add_child(_wl("  ".join(parts), 13, UiKit.GOOD))
	_box.add_child(UiKit.label("Składniki:", 16, UiKit.ACCENT))
	var cost := ForgeDB.cost(_kind, _metal)
	var can := true
	for id in cost:
		var have := GameState.item_count(String(id))
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
	if not can:
		go.tooltip_text = "Brakuje składników."
	go.pressed.connect(func(): Audio.play("confirm"); _enter("heat"))
	_box.add_child(go)
	var runes := UiKit.button("Zapis run…", 18, Color(1.0, 0.85, 0.4))
	runes.pressed.connect(_open_runes)
	_box.add_child(runes)
	var buy := UiKit.button("Kup sztabkę żelaza (30 zł)", 15, UiKit.ACCENT2)
	buy.disabled = GameState.gold() < 30
	buy.pressed.connect(func():
		if GameState.spend(30):
			GameState.add_item("sztabka_zelaza", 1)
			Audio.play("coin")
			_enter("select"))
	_box.add_child(buy)
	var coal := UiKit.button("Kup węgiel (25 zł)", 15, UiKit.ACCENT2)
	coal.disabled = GameState.gold() < 25
	coal.pressed.connect(func():
		if GameState.spend(25):
			GameState.add_item("wegiel", 1)
			Audio.play("coin")
			_enter("select"))
	_box.add_child(coal)
	var coal5 := UiKit.button("Kup 5 węgla (110 zł)", 15, UiKit.ACCENT2)
	coal5.disabled = GameState.gold() < 110
	coal5.pressed.connect(func():
		if GameState.spend(110):
			GameState.add_item("wegiel", 5)
			Audio.play("coin")
			_enter("select"))
	_box.add_child(coal5)
	_box.add_child(UiKit.label("Złoto: %d" % GameState.gold(), 14, Color(1, 0.85, 0.4)))

func _open_runes() -> void:
	Audio.play("confirm")
	var r := UiRunes.new()
	add_child(r)
	r.on_close.connect(func():
		r.queue_free()
		_enter("select"))

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
	_enter("hammer")

func _finish_hammer() -> void:
	var sum := 0.0
	for h in _hits:
		sum += float(h)
	_scores["hammer"] = sum / float(HAMMER_STRIKES)
	_msg.text = "Kucie: %s" % _score_label(_scores["hammer"])
	_enter("quench")

func _finish_quench() -> void:
	_scores["quench"] = maxf(0.0, _quench_score)
	_view.cooled = 1.0
	Audio.play("drink", 0.7, -2.0)
	_result = {}
	_enter("result")

func _build_result() -> void:
	var total: float = 0.3 * float(_scores["heat"]) + 0.5 * float(_scores["hammer"]) + 0.2 * float(_scores["quench"])
	var q := ForgeDB.quality_of(total)
	var rid := ForgeDB.result_id(_kind, _metal)
	var failed: bool = float(q["mult"]) <= 0.0
	_result = {"score": total, "quality": q, "failed": failed}
	_view.heat = 0.1
	_box.add_child(UiKit.label("WYNIK KUCIA", 22, UiKit.ACCENT))
	_box.add_child(UiKit.label("Nagrzewanie: %s   Kucie: %s   Hartowanie: %s" % [_score_label(_scores["heat"]), _score_label(_scores["hammer"]), _score_label(_scores["quench"])], 14, UiKit.DIM))
	_box.add_child(UiKit.label("Wynik łączny: %s" % _score_label(total), 18, UiKit.TEXT))
	if failed:
		_box.add_child(UiKit.label("NIEUDANE!", 30, UiKit.BAD))
		var loss := ForgeDB.fail_loss(_kind, _metal)
		_box.add_child(_wl("Metal pękł. Traci się część składników, resztę odzyskujesz." + ("" if loss.is_empty() else " Utracone: " + ", ".join(loss.keys().map(func(i): return "%s ×%d" % [String(ItemDB.get_data(String(i)).get("name", i)), int(loss[i])]))), 14, UiKit.BAD))
		var ok := UiKit.button("Rozumiem", 20)
		ok.pressed.connect(func():
			for id in loss:
				GameState.remove_item(String(id), int(loss[id]))
			GameState.save_game()
			Audio.play("deny")
			_msg.text = "Kucie się nie udało."
			_enter("select"))
		_box.add_child(ok)
		return
	var head := UiKit.hbox(8)
	_box.add_child(head)
	head.add_child(UiKit.icon(Art.item_icon(rid, 56), 56))
	var hv := UiKit.vbox(0)
	head.add_child(hv)
	hv.add_child(UiKit.label(String(ItemDB.get_data(rid).get("name", "?")), 22, ItemDB.rarity_color(rid)))
	hv.add_child(UiKit.label("Jakość: %s (%.0f%% statystyk)" % [String(q["name"]), float(q["mult"]) * 100.0], 16, UiKit.GOOD))
	var take := UiKit.button("Odbierz przedmiot", 22)
	take.pressed.connect(func():
		var cost := ForgeDB.cost(_kind, _metal)
		for id in cost:
			GameState.remove_item(String(id), int(cost[id]))
		var left := GameState.add_item(rid, 1, float(q["mult"]))
		GameState.save_game()
		Audio.play("levelup", 1.0, -4.0)
		GameState.toast.emit("Wykuto: %s (%s)" % [String(ItemDB.get_data(rid).get("name", "?")), String(q["name"])], UiKit.GOOD)
		_msg.text = "Wykuto %s — jakość: %s." % [String(ItemDB.get_data(rid).get("name", "?")), String(q["name"])] + (" Ekwipunek pełny — przedmiot czeka w skrytce." if left > 0 else "")
		_enter("select"))
	_box.add_child(take)

# ----------------------------------------------------------------- pętla ---

func _process(delta: float) -> void:
	_t += delta
	match _phase:
		"heat":
			var hold := Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _holding
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
			Fx.shake(2.0 + s * 2.0, 0.08)
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
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _is_over_play_area(event.position))
	if pressed:
		get_viewport().set_input_as_handled()
		_action()

func _is_over_play_area(p: Vector2) -> bool:
	return _bar != null and _bar.get_global_rect().grow(120.0).has_point(p)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		if _phase == "select":
			_leave()
		else:
			Audio.play("back")
			_msg.text = "Przerwano kucie — nic nie straciłeś."
			_enter("select")
