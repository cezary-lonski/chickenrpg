class_name UiWorldMap
extends Control
## Mapa świata Aktu II: wioski kontrolowane przez Czarnego Kruka. Gracz wybiera misję
## (kolejność dowolna; gniazdo odblokowuje się po wyzwoleniu pięciu wiosek).

signal on_start(mission_id: String)
signal on_menu

var _sel := ""
var _canvas: MapCanvas
var _info: VBoxContainer
var _intro_panel: Control

# ----------------------------------------------------------------- płótno mapy ---

class MapCanvas extends Control:
	signal picked(id: String)
	var selected := ""
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
				var p: Vector2 = Act2DB.MAP[id] * k
				if event.position.distance_to(p) <= 34.0:
					picked.emit(String(id))
					return

	func _sc(pts: Array, k: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append((p as Vector2) * k)
		return out

	func _draw() -> void:
		var k := size.x / 1000.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.15, 0.12))
		# tereny
		draw_colored_polygon(_sc([Vector2(0, 280), Vector2(260, 220), Vector2(420, 330), Vector2(640, 300), Vector2(1000, 420), Vector2(1000, 520), Vector2(0, 520)], k), Color(0.2, 0.26, 0.17))
		draw_colored_polygon(_sc([Vector2(440, 360), Vector2(620, 340), Vector2(680, 470), Vector2(480, 520)], k), Color(0.15, 0.2, 0.2))
		draw_colored_polygon(_sc([Vector2(620, 120), Vector2(780, 90), Vector2(820, 240), Vector2(660, 280)], k), Color(0.27, 0.24, 0.22))
		draw_colored_polygon(_sc([Vector2(380, 0), Vector2(620, 0), Vector2(600, 120), Vector2(400, 130)], k), Color(0.2, 0.15, 0.22))
		# drogi
		var order := Act2DB.ORDER
		for i in order.size() - 1:
			var a: Vector2 = Act2DB.MAP[order[i]] * k
			var b: Vector2 = Act2DB.MAP[order[i + 1]] * k
			draw_line(a, b, Color(0.55, 0.45, 0.3, 0.55), 4.0, true)
		draw_line(Act2DB.MAP["akt2_bagniska"] * k, Act2DB.MAP["akt2_gniazdo"] * k, Color(0.55, 0.45, 0.3, 0.35), 3.0, true)
		var f := ThemeDB.fallback_font
		for id in Act2DB.MAP:
			var p: Vector2 = Act2DB.MAP[id] * k
			var done := Act2DB.is_liberated(String(id))
			var avail := Act2DB.is_available(String(id))
			var col := Color(0.4, 0.85, 0.5) if done else (Color(1.0, 0.75, 0.25) if avail else Color(0.4, 0.4, 0.46))
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			if avail:
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
			if not avail and not done:
				draw_string(f, p + Vector2(-34, 68), "zablokowane", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.5, 0.5))

# --------------------------------------------------------------------- UI ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.06, 0.07, 0.06)))
	var root := UiKit.vbox(6)
	UiKit.full(root)
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_top = 10.0
	root.offset_bottom = -10.0
	add_child(root)
	root.add_child(UiKit.title("AKT II — ZEMSTA NA CZARNYM KRUKU", 34))
	root.add_child(UiKit.label("Wyzwolone wioski: %d / %d   ·   Wdzięczność wiosek: %d" % [Act2DB.liberated().size(), Act2DB.ORDER.size(), Act2DB.rep()], 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var body := UiKit.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := UiKit.panel(UiKit.BG, 8)
	body.add_child(left)
	_canvas = MapCanvas.new()
	_canvas.picked.connect(func(id: String): _select(id))
	left.add_child(_canvas)
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(340, 0)
	body.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	_info = UiKit.vbox(6)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(_info)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Menu główne", 18)
	back.pressed.connect(func(): Audio.play("back"); on_menu.emit())
	row.add_child(back)
	# pierwsza dostępna misja zaznaczona
	for id in Act2DB.ORDER:
		if Act2DB.is_available(String(id)):
			_sel = String(id)
			break
	_canvas.selected = _sel
	_refresh()
	if not bool(Act2DB.state().get("started", false)):
		_show_intro()
	Audio.play_music("menu")

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _show_intro() -> void:
	_intro_panel = Control.new()
	UiKit.full(_intro_panel)
	_intro_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_intro_panel)
	_intro_panel.add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.8)))
	var c := UiKit.vbox(10)
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(c)
	_intro_panel.add_child(c)
	var p := UiKit.panel(UiKit.BG, 14)
	p.custom_minimum_size = Vector2(760, 0)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_child(p)
	var v := UiKit.vbox(10)
	p.add_child(v)
	v.add_child(UiKit.title("AKT II", 48))
	v.add_child(_wl("Czarny Kruk uciekł z fortecy, ranny, lecz żywy. Jego pazury wciąż trzymają wioski królestwa: wrony zbierają daninę, pilnują szlaków i kują pancerze dla jego armii.", 18, UiKit.TEXT))
	v.add_child(_wl("Tym razem to ty prowadzisz atak. Wybieraj wioski w dowolnej kolejności, uwalniaj jeńców, niszcz posterunki i podejmuj decyzje, które zapamiętają mieszkańcy. Gdy wyzwolisz pięć wiosek, otworzy się droga do Gniazda.", 16, UiKit.DIM))
	var b := UiKit.button("Zaczynajmy!", 22)
	b.pressed.connect(func():
		Act2DB.state()["started"] = true
		GameState.save_game()
		Audio.play("confirm")
		_intro_panel.queue_free())
	v.add_child(b)
	b.grab_focus()

func _select(id: String) -> void:
	_sel = id
	_canvas.selected = id
	Audio.play("select")
	_refresh()

func _refresh() -> void:
	for c in _info.get_children():
		c.queue_free()
	if _sel == "":
		_info.add_child(UiKit.label("Wszystkie wioski wyzwolone!", 20, UiKit.GOOD))
		return
	var q := QuestDB.get_data(_sel)
	var done := Act2DB.is_liberated(_sel)
	var avail := Act2DB.is_available(_sel)
	_info.add_child(UiKit.label(String(q.get("label", "")), 14, UiKit.DIM))
	_info.add_child(_wl(String(q.get("title", "")), 22, UiKit.ACCENT))
	_info.add_child(_wl(String(q.get("intro", "")), 15, UiKit.TEXT))
	var boss := BossDB.get_data(BossDB.for_zone(_sel))
	if not boss.is_empty():
		_info.add_child(_wl("Boss: %s — %s" % [String(boss.get("name", "")), String(boss.get("title", ""))], 15, Color(1.0, 0.5, 0.45)))
	_info.add_child(UiKit.label("Cele misji:", 15, UiKit.ACCENT2))
	for o in ChapterExtras.objectives(_sel):
		var req := bool(o.get("required", false))
		var st := ""
		if done: st = "✓ "
		else: st = "▶ " if req else "· "
		_info.add_child(_wl(st + String(o["text"]), 14, UiKit.GOOD if done else (UiKit.TEXT if req else UiKit.DIM)))
	_info.add_child(_wl("Nagroda: %s" % QuestDB.reward_text(_sel), 14, Color(1, 0.85, 0.4)))
	if _sel == Act2DB.FINAL:
		var rep := Act2DB.rep()
		_info.add_child(_wl("Wdzięczność wiosek: %d. Przy 3 lub więcej wioski wesprą cię w finale (boss słabszy o 10%% i większa nagroda)." % rep, 13, UiKit.ACCENT2 if rep >= 3 else UiKit.DIM))
	if done:
		_info.add_child(UiKit.label("Wioska wyzwolona", 18, UiKit.GOOD))
		return
	var go := UiKit.button("Wyrusz na misję" if avail else "Zablokowane", 20)
	go.disabled = not avail
	if not avail:
		go.tooltip_text = "Wyzwól najpierw pozostałe pięć wiosek."
		_info.add_child(_wl("Wyzwól najpierw pozostałe pięć wiosek.", 13, UiKit.BAD))
	go.pressed.connect(func(): Audio.play("confirm"); on_start.emit(_sel))
	_info.add_child(go)
