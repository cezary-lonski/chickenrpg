class_name UiRunes
extends Control
## Zapis run na przedmiocie: wybierasz przedmiot (z plecaka lub założony) i słowo, a potem
## „rzeźbisz” kolejne runy, klikając punkty obrysu w kolejności.

signal on_close

var _src := {}            # {"kind": "inv"|"eq", "key": idx|slot}
var _word := ""
var _list: VBoxContainer
var _side: VBoxContainer
var _carve: CarveCanvas
var _msg: Label
var _phase := "pick"

# ------------------------------------------------------------------- płótno ---

class CarveCanvas extends Control:
	signal finished
	var word := ""
	var _li := 0               # indeks litery
	var _ci := 0               # indeks punktu kontrolnego
	var _points: Array = []    # punkty kontrolne bieżącej litery (0..1)
	var _done_lines: Array = []
	var _t := 0.0
	var _flash := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(520, 420)

	func start(w: String) -> void:
		word = w
		_li = 0
		_load_letter()

	func _load_letter() -> void:
		_ci = 0
		_done_lines.clear()
		_points.clear()
		var strokes: Array = RuneDB.GLYPHS.get(word[_li], [])
		for st in strokes:
			for i in st.size():
				_points.append({"p": st[i], "stroke": strokes.find(st)})
				if i < st.size() - 1:
					_points.append({"p": ((st[i] as Vector2) + (st[i + 1] as Vector2)) * 0.5, "stroke": strokes.find(st)})
		queue_redraw()

	func _box() -> Rect2:
		return Rect2(Vector2(size.x * 0.5 - 130.0, 90.0), Vector2(260.0, 300.0))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if _li >= word.length():
				return
			var b := _box()
			var target: Vector2 = b.position + (_points[_ci]["p"] as Vector2) * b.size
			if event.position.distance_to(target) <= 30.0:
				Audio.play("hit", 1.0 + 0.05 * float(_ci), -6.0)
				Fx.shake(1.5, 0.05)
				_flash = 0.15
				_ci += 1
				if _ci >= _points.size():
					Audio.play("confirm", 1.2, -2.0)
					_li += 1
					if _li >= word.length():
						finished.emit()
					else:
						_load_letter()
				queue_redraw()
			else:
				Audio.play("deny", 1.3, -14.0)

	func _process(delta: float) -> void:
		_t += delta
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.13))
		# wyświetlenie słowa
		var f := ThemeDB.fallback_font
		for i in word.length():
			var x := size.x * 0.5 - float(word.length()) * 24.0 + float(i) * 48.0
			var col := Color(1.0, 0.85, 0.4) if i == _li else (Color(0.4, 0.9, 0.5) if i < _li else Color(0.5, 0.5, 0.55))
			draw_string(f, Vector2(x, 40.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, col)
			_draw_rune_small(word[i], Vector2(x - 6.0, 52.0), col)
		if _li >= word.length():
			return
		var b := _box()
		draw_rect(b.grow(14.0), Color(0.2, 0.19, 0.22))
		draw_rect(b.grow(14.0), Color(0.45, 0.42, 0.5), false, 3.0)
		# zarys litery (podpowiedź)
		for st in RuneDB.GLYPHS.get(word[_li], []):
			var pts := PackedVector2Array()
			for p in st:
				pts.append(b.position + (p as Vector2) * b.size)
			if pts.size() > 1:
				draw_polyline(pts, Color(0.3, 0.3, 0.35), 8.0, true)
		# wyrzeźbione odcinki
		for i in range(1, _ci):
			var a: Vector2 = b.position + (_points[i - 1]["p"] as Vector2) * b.size
			var c: Vector2 = b.position + (_points[i]["p"] as Vector2) * b.size
			if int(_points[i]["stroke"]) == int(_points[i - 1]["stroke"]):
				draw_line(a, c, Color(1.0, 0.8, 0.3, 0.95), 7.0, true)
		# punkty
		for i in _points.size():
			var pp: Vector2 = b.position + (_points[i]["p"] as Vector2) * b.size
			if i == _ci:
				var pulse := 0.5 + 0.5 * sin(_t * 8.0)
				draw_circle(pp, 16.0 + 4.0 * pulse, Color(1.0, 0.9, 0.3, 0.35))
				draw_circle(pp, 9.0, Color(1.0, 0.9, 0.3))
			elif i > _ci:
				draw_circle(pp, 5.0, Color(0.55, 0.55, 0.6))
			else:
				draw_circle(pp, 5.0, Color(1.0, 0.8, 0.3))
		if _flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 0.8, _flash * 0.4))

	func _draw_rune_small(letter: String, at: Vector2, col: Color) -> void:
		for st in RuneDB.GLYPHS.get(letter, []):
			var pts := PackedVector2Array()
			for p in st:
				pts.append(at + Vector2((p as Vector2).x * 22.0, (p as Vector2).y * 30.0 + 12.0))
			if pts.size() > 1:
				draw_polyline(pts, col, 2.0, true)

# --------------------------------------------------------------------- UI ---

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.07, 0.06, 0.09)))
	var root := UiKit.vbox(8)
	UiKit.full_margin(root)
	add_child(root)
	root.add_child(UiKit.title("ZAPIS RUN", 36))
	var body := UiKit.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := UiKit.panel(UiKit.BG, 10)
	left.custom_minimum_size = Vector2(400, 0)
	body.add_child(left)
	var ls := ScrollContainer.new()
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(ls)
	_list = UiKit.vbox(4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(_list)
	var right := UiKit.panel(UiKit.BG, 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	_side = UiKit.vbox(6)
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(_side)
	_msg = UiKit.label("", 15, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_msg)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wróć do kuźni", 20)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	row.add_child(back)
	GameState.absorb_patterns()
	_refresh()

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

## Źródła: [{kind, key, id, meta}]
func _sources() -> Array:
	var out: Array = []
	var eq := GameState.equipped()
	for slot in ItemDB.EQUIP_SLOTS:
		var id := String(eq.get(slot, ""))
		if id != "" and ItemDB.is_gear(id):
			out.append({"kind": "eq", "key": slot, "id": id, "meta": GameState.equipped_meta(String(slot))})
	var inv := GameState.inv()
	for i in inv.size():
		var e = inv[i]
		if e is Dictionary and ItemDB.is_gear(String(e["id"])):
			out.append({"kind": "inv", "key": i, "id": String(e["id"]), "meta": e.get("m", {})})
	return out

func _is_sel(s: Dictionary) -> bool:
	return not _src.is_empty() and String(_src["kind"]) == String(s["kind"]) and _src["key"] == s["key"]

func _refresh() -> void:
	_phase = "pick"
	for c in _list.get_children():
		c.queue_free()
	for c in _side.get_children():
		c.queue_free()
	_list.add_child(UiKit.label("WYBIERZ PRZEDMIOT", 15, UiKit.DIM))
	for s in _sources():
		var sd: Dictionary = s
		var id := String(sd["id"])
		var rar := ItemDB.meta_rarity(id, sd["meta"])
		var row := UiKit.panel(UiKit.BG3 if _is_sel(sd) else UiKit.BG2, 6)
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
		b.pressed.connect(func(): _src = {"kind": sd["kind"], "key": sd["key"]}; Audio.play("select"); _refresh())
		h.add_child(b)
		_list.add_child(row)
	if _sources().is_empty():
		_list.add_child(_wl("Nie masz wyposażenia, na którym można zapisać runy.", 14, UiKit.BAD))
	_build_side()

func _find_source() -> Dictionary:
	for s in _sources():
		if _is_sel(s):
			return s
	return {}

func _build_side() -> void:
	var s := _find_source()
	if s.is_empty():
		_side.add_child(UiKit.label("Wybierz przedmiot z listy", 18, UiKit.DIM))
		_side.add_child(_wl("Runy zapisane na przedmiocie zmieniają jego rzadkość, wzmacniają statystyki albo dodają kradzież życia. Słowa o większej mocy kosztują więcej i wymagają rzadszych składników. Zbroja z kurczalium staje się hiperlegendarna po wyrzeźbieniu słowa CZARKA, a hiperekstralegendarna po słowie KURCZAK.", 14, UiKit.DIM))
		return
	var id := String(s["id"])
	_side.add_child(UiKit.label(String(ItemDB.get_data(id).get("name", id)), 20, ItemDB.rarity_color_of(ItemDB.meta_rarity(id, s["meta"]))))
	_side.add_child(UiKit.label("WYBIERZ SŁOWO", 15, UiKit.DIM))
	for w in RuneDB.WORDS:
		var word := String(w)
		var chk := RuneDB.check(id, s["meta"], word)
		var known := RuneDB.is_known(word)
		var ok := known and bool(chk["ok"]) and RuneDB.can_pay(word)
		var row := UiKit.panel(UiKit.BG3 if word == _word else UiKit.BG2, 6)
		var v := UiKit.vbox(1)
		row.add_child(v)
		var head := UiKit.hbox(8)
		v.add_child(head)
		head.add_child(UiKit.label(word, 18, UiKit.ACCENT if ok else UiKit.DIM))
		head.add_child(UiKit.label("%d run" % word.length(), 12, UiKit.DIM))
		v.add_child(_wl(String(RuneDB.WORDS[word]["desc"]), 12, UiKit.TEXT))
		v.add_child(_wl("Koszt: " + RuneDB.cost_text(word), 12, UiKit.GOOD if RuneDB.can_pay(word) else UiKit.BAD))
		if not known:
			v.add_child(_wl("Kowal nie zna tego wzoru — potrzebujesz wzorca (z potworów, skrzyń, jaskiń, bossów albo ze sklepu).", 12, UiKit.BAD))
		elif not bool(chk["ok"]):
			v.add_child(_wl(String(chk["msg"]), 12, UiKit.BAD))
		var b := UiKit.button("Zapisz runy", 14)
		b.disabled = not ok
		b.pressed.connect(func(): _begin_carve(word))
		v.add_child(b)
		_side.add_child(row)

func _begin_carve(word: String) -> void:
	_word = word
	_phase = "carve"
	for c in _side.get_children():
		c.queue_free()
	_side.add_child(UiKit.label("RZEŹBIENIE: %s" % word, 20, UiKit.ACCENT))
	_side.add_child(_wl("Klikaj podświetlone punkty obrysu runy w kolejności. Po wyrzeźbieniu wszystkich run słowo zostanie zapisane, a koszt pobrany.", 13, UiKit.DIM))
	_carve = CarveCanvas.new()
	_carve.start(word)
	_carve.finished.connect(_finish_carve)
	_side.add_child(_carve)
	var cancel := UiKit.button("Anuluj (nic nie tracisz)", 14, UiKit.BAD)
	cancel.pressed.connect(func(): _word = ""; _refresh())
	_side.add_child(cancel)

func _finish_carve() -> void:
	var s := _find_source()
	if not RuneDB.is_known(_word):
		_msg.text = "Kowal nie zna tego wzoru."
		_word = ""
		_refresh()
		return
	if not s.is_empty() and not bool(RuneDB.check(String(s["id"]), s["meta"], _word)["ok"]):
		_msg.text = String(RuneDB.check(String(s["id"]), s["meta"], _word)["msg"])
		_word = ""
		_refresh()
		return
	if s.is_empty() or not RuneDB.pay(_word):
		_msg.text = "Nie udało się zapisać run (brak składników)."
		_refresh()
		return
	var meta: Dictionary = RuneDB.apply(String(s["id"]), s["meta"], _word)
	if String(s["kind"]) == "inv":
		var inv := GameState.inv()
		inv[int(s["key"])]["m"] = meta
	else:
		GameState.equipped_meta()[String(s["key"])] = meta
		GameState.refresh_stats()
	GameState.save_game()
	Audio.play("levelup", 0.9, -2.0)
	Fx.flash(Color(1.0, 0.9, 0.5), 0.2, 0.4)
	GameState.toast.emit("Runy %s zapisane na: %s" % [_word, String(ItemDB.get_data(String(s["id"])).get("name", "?"))], UiKit.GOOD)
	_msg.text = "Zapisano runy %s!" % _word
	_word = ""
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		if _phase == "carve":
			_word = ""
			_refresh()
		else:
			on_close.emit()
