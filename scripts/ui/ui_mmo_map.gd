class_name UiMmoMap
extends UiMmoPanel
## Mapa świata Aktu II na serwerze: wioski kontrolowane przez Czarnego Kruka. Wybierasz misję (kolejność dowolna;
## gniazdo odblokowuje się po wyzwoleniu pięciu wiosek). Stan (wyzwolone wioski, wdzięczność) pochodzi z serwera.

var _state: Dictionary = {"liberated": [], "rep": 0, "started": true, "avail": {}}
var _sel := ""
var _canvas: Canvas
var _info: VBoxContainer
var _head: Label

class Canvas extends Control:
	signal picked(id: String)
	var selected := ""
	var state: Dictionary = {}
	var _t := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(760, 520)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var k := size.x / 1000.0
			for id in Act2DB.MAP:
				if event.position.distance_to(Act2DB.MAP[id] * k) <= 34.0:
					picked.emit(String(id))
					return

	func _sc(pts: Array, k: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append((p as Vector2) * k)
		return out

	func _draw() -> void:
		var k := size.x / 1000.0
		var lib: Array = state.get("liberated", [])
		var avail: Dictionary = state.get("avail", {})
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.15, 0.12))
		draw_colored_polygon(_sc([Vector2(0, 280), Vector2(260, 220), Vector2(420, 330), Vector2(640, 300), Vector2(1000, 420), Vector2(1000, 520), Vector2(0, 520)], k), Color(0.2, 0.26, 0.17))
		draw_colored_polygon(_sc([Vector2(440, 360), Vector2(620, 340), Vector2(680, 470), Vector2(480, 520)], k), Color(0.15, 0.2, 0.2))
		draw_colored_polygon(_sc([Vector2(620, 120), Vector2(780, 90), Vector2(820, 240), Vector2(660, 280)], k), Color(0.27, 0.24, 0.22))
		draw_colored_polygon(_sc([Vector2(380, 0), Vector2(620, 0), Vector2(600, 120), Vector2(400, 130)], k), Color(0.2, 0.15, 0.22))
		var order := Act2DB.ORDER
		for i in order.size() - 1:
			draw_line(Act2DB.MAP[order[i]] * k, Act2DB.MAP[order[i + 1]] * k, Color(0.55, 0.45, 0.3, 0.55), 4.0, true)
		draw_line(Act2DB.MAP["akt2_bagniska"] * k, Act2DB.MAP["akt2_gniazdo"] * k, Color(0.55, 0.45, 0.3, 0.35), 3.0, true)
		var f := ThemeDB.fallback_font
		for id in Act2DB.MAP:
			var p: Vector2 = Act2DB.MAP[id] * k
			var done := String(id) in lib
			var av := bool(avail.get(id, false))
			var col := Color(0.4, 0.85, 0.5) if done else (Color(1.0, 0.75, 0.25) if av else Color(0.4, 0.4, 0.46))
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			if av:
				draw_circle(p, 34.0 + 5.0 * pulse, Color(col.r, col.g, col.b, 0.18))
			if String(id) == selected:
				draw_arc(p, 38.0, 0.0, TAU, 40, Color(1, 1, 1, 0.9), 3.0, true)
			draw_circle(p, 26.0, Color(0.08, 0.09, 0.12))
			draw_circle(p, 22.0, col)
			if String(id) == Act2DB.FINAL:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 8), p + Vector2(-8, -12), p + Vector2(0, -2), p + Vector2(8, -12), p + Vector2(12, 8)]), Color(0.12, 0.08, 0.15))
			elif done:
				draw_line(p + Vector2(-9, 0), p + Vector2(-2, 8), Color(0.08, 0.2, 0.1), 4.0, true)
				draw_line(p + Vector2(-2, 8), p + Vector2(10, -8), Color(0.08, 0.2, 0.1), 4.0, true)
			else:
				draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 12)), Color(0.15, 0.1, 0.05))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-11, -4), p + Vector2(0, -14), p + Vector2(11, -4)]), Color(0.3, 0.12, 0.08))
			var name_txt := String(QuestDB.get_data(String(id)).get("title", id)).split(":")[0]
			var w := f.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(f, p + Vector2(-w * 0.5, 50), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))
			if not av and not done:
				draw_string(f, p + Vector2(-34, 68), "zablokowane", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.5, 0.5))

func _init() -> void:
	super._init("AKT II — ZEMSTA NA CZARNYM KRUKU")

func apply_state(data: Dictionary) -> void:
	_state = data
	if _canvas != null:
		_pick_default()
		_refresh()

func _pick_default() -> void:
	_sel = ""
	for id in Act2DB.ORDER:
		if bool((_state.get("avail", {}) as Dictionary).get(id, false)):
			_sel = String(id)
			break
	_canvas.selected = _sel
	_canvas.state = _state

func _build() -> void:
	_head = UiKit.label("", 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_box.add_child(_head)
	var body := UiKit.hbox(12)
	_box.add_child(body)
	var left := UiKit.panel(UiKit.BG, 8)
	body.add_child(left)
	_canvas = Canvas.new()
	_canvas.picked.connect(func(id: String): _sel = id; _canvas.selected = id; Audio.play("select"); _refresh())
	left.add_child(_canvas)
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(340, 0)
	body.add_child(right)
	_info = UiKit.vbox(6)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_info)
	_pick_default()
	_refresh()
	if not bool(_state.get("started", true)):
		_show_intro()

func _show_intro() -> void:
	var p := UiKit.panel(Color(0.04, 0.04, 0.07, 0.97), 14)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.custom_minimum_size = Vector2(760, 0)
	add_child(p)
	var v := UiKit.vbox(10)
	p.add_child(v)
	v.add_child(UiKit.title("AKT II", 48))
	v.add_child(_wl("Czarny Kruk uciekł z fortecy, ranny, lecz żywy. Jego pazury wciąż trzymają wioski królestwa: wrony zbierają daninę, pilnują szlaków i kują pancerze dla jego armii.", 18, UiKit.TEXT))
	v.add_child(_wl("Tym razem to ty prowadzisz atak. Wybieraj wioski w dowolnej kolejności, uwalniaj jeńców, niszcz posterunki i podejmuj decyzje, które zapamiętają mieszkańcy. Gdy wyzwolisz pięć wiosek, otworzy się droga do Gniazda.", 16, UiKit.DIM))
	var b := UiKit.button("Zaczynajmy!", 22)
	b.pressed.connect(func():
		_state["started"] = true
		Mmo.send_act("act2_started")
		Audio.play("confirm")
		p.queue_free())
	v.add_child(b)

func _refresh() -> void:
	_head.text = "Wyzwolone wioski: %d / %d   ·   Wdzięczność wiosek: %d" % [(_state.get("liberated", []) as Array).size(), Act2DB.ORDER.size(), int(_state.get("rep", 0))]
	for c in _info.get_children():
		c.queue_free()
	if _sel == "":
		_info.add_child(UiKit.label("Wszystkie wioski wyzwolone!", 20, UiKit.GOOD))
		return
	var q := QuestDB.get_data(_sel)
	var done := _sel in (_state.get("liberated", []) as Array)
	var avail := bool((_state.get("avail", {}) as Dictionary).get(_sel, false))
	_info.add_child(UiKit.label(String(q.get("label", "")), 14, UiKit.DIM))
	_info.add_child(_wl(String(q.get("title", "")), 22, UiKit.ACCENT))
	_info.add_child(_wl(String(q.get("intro", "")), 15, UiKit.TEXT))
	var boss := BossDB.get_data(BossDB.for_zone(_sel))
	if not boss.is_empty():
		_info.add_child(_wl("Boss: %s — %s" % [String(boss.get("name", "")), String(boss.get("title", ""))], 15, Color(1.0, 0.5, 0.45)))
	_info.add_child(UiKit.label("Cele misji:", 15, UiKit.ACCENT2))
	for o in ChapterExtras.objectives(_sel):
		var req := bool(o.get("required", false))
		var st := "✓ " if done else ("▶ " if req else "· ")
		_info.add_child(_wl(st + String(o["text"]), 14, UiKit.GOOD if done else (UiKit.TEXT if req else UiKit.DIM)))
	_info.add_child(_wl("Nagroda: %s" % QuestDB.reward_text(_sel), 14, Color(1, 0.85, 0.4)))
	if _sel == Act2DB.FINAL:
		var rep := int(_state.get("rep", 0))
		_info.add_child(_wl("Wdzięczność wiosek: %d. Przy 3 lub więcej wioski wesprą cię w finale (boss słabszy o 10%% i większa nagroda)." % rep, 13, UiKit.ACCENT2 if rep >= 3 else UiKit.DIM))
	if done:
		_info.add_child(UiKit.label("Wioska wyzwolona", 18, UiKit.GOOD))
		return
	var go := UiKit.button("Wyrusz na misję" if avail else "Zablokowane", 20)
	go.disabled = not avail
	if not avail:
		_info.add_child(_wl("Wyzwól najpierw pozostałe pięć wiosek.", 13, UiKit.BAD))
	go.pressed.connect(func(): Audio.play("confirm"); Mmo.send_act("act2_pick", {"id": _sel}))
	_info.add_child(go)
