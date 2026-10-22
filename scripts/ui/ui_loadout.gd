class_name UiLoadout
extends Control
## Ekwipunek: trzy sloty wyposażenia, plecak, porównanie statystyk.
## Otwierane z wyboru postaci albo z pauzy (jako nakładka).

signal on_close

var from := "select"
var _cells: Array = []
var _list_box: VBoxContainer
var _list_title: Label
var _stats_box: VBoxContainer
var _bag_box: HBoxContainer
var _char_label: Label
var _visual: CreatureVisual
var _mode := "equipment"  # equipment | skills
var _cur_slot := "weapon"
var _cur_skill := 0

func setup(source: String) -> void:
	from = source

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	add_child(root)
	root.add_child(UiKit.title("WYPOSAŻENIE", 42))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var body := UiKit.hbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	# --- lewa: postać i sloty
	var left := UiKit.panel(UiKit.BG, 12)
	left.custom_minimum_size = Vector2(360, 0)
	body.add_child(left)
	var lv := UiKit.vbox(8)
	left.add_child(lv)
	_char_label = UiKit.label("", 24, UiKit.ACCENT)
	lv.add_child(_char_label)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(320, 150)
	lv.add_child(holder)
	_visual = CreatureVisual.new()
	_visual.position = Vector2(100, 142)
	holder.add_child(_visual)
	lv.add_child(UiKit.label("WYPOSAŻENIE  ·  SKILE", 15, UiKit.DIM))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	lv.add_child(grid)
	for slot in ItemDB.SLOT_ORDER:
		var b := _make_cell()
		var s := String(slot)
		b.pressed.connect(func(): _open_slot(s))
		grid.add_child(b)
		_cells.append({"btn": b, "kind": "gear", "key": s})
	for i in range(6):
		var b := _make_cell()
		var idx: int = i
		b.pressed.connect(func(): _open_skill_slot(idx))
		grid.add_child(b)
		_cells.append({"btn": b, "kind": "skill", "key": i})
	# statystyki
	lv.add_child(UiKit.label("STATYSTYKI", 15, UiKit.DIM))
	var sc := UiKit.panel(UiKit.BG2, 8)
	lv.add_child(sc)
	_stats_box = UiKit.vbox(2)
	sc.add_child(_stats_box)
	# plecak
	lv.add_child(UiKit.label("PLECAK (kliknij, żeby użyć)", 15, UiKit.DIM))
	var bagc := UiKit.panel(UiKit.BG2, 8)
	lv.add_child(bagc)
	_bag_box = UiKit.hbox(6)
	bagc.add_child(_bag_box)

	# --- prawa: lista przedmiotów
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv := UiKit.vbox(6)
	right.add_child(rv)
	_list_title = UiKit.label("", 22, UiKit.ACCENT)
	rv.add_child(_list_title)
	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(scroller)
	_list_box = UiKit.vbox(4)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(_list_box)

	# --- przyciski
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	if from == "select":
		var back := UiKit.button("Wybierz innego", 20)
		back.pressed.connect(func(): Audio.play("back"); on_close.emit())
		row.add_child(back)
		var go := UiKit.button("Wyrusz do etapu 1", 24)
		go.custom_minimum_size = Vector2(300, 50)
		go.pressed.connect(_on_start)
		row.add_child(go)
	else:
		var back2 := UiKit.button("Wróć do pauzy", 20)
		back2.pressed.connect(func(): Audio.play("back"); on_close.emit())
		row.add_child(back2)
	_open_slot("weapon")
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		Audio.play("back")
		on_close.emit()

func _refresh() -> void:
	var id := String(GameState.run.get("character", "kurczak"))
	var data := CharacterDB.get_data(id)
	_char_label.text = "%s — Poziom %d" % [String(data["title"]), int(GameState.char_profile(id).get("level", 1))]
	_visual.configure(id, data["pal"], 1.4)
	var eq := GameState.equipped()
	var skills := GameState.skill_slots()
	for cell in _cells:
		var b: Button = cell["btn"]
		if cell["kind"] == "gear":
			var slot := String(cell["key"])
			var item := String(eq.get(slot, ""))
			var d := ItemDB.get_data(item)
			b.icon = Art.item_icon(item, 48)
			b.text = ""
			var tip := "%s\n%s" % [String(d.get("name", "?")), String(d.get("desc", ""))]
			if slot == "weapon":
				var eff := ItemDB.weapon_desc(item)
				if eff != "":
					tip += "\nEfekt: %s" % eff
			b.tooltip_text = tip
			b.add_theme_color_override("font_color", UiKit.TEXT)
			b.modulate = Color.WHITE
		else:
			var si := int(cell["key"])
			var sid := String(skills[si]) if si < skills.size() else ""
			b.icon = null
			if sid == "" or not SkillDB.has(sid):
				b.text = "—"
				b.tooltip_text = "Pusty slot skilla %d" % (si + 1)
				b.add_theme_color_override("font_color", UiKit.DIM)
				b.modulate = Color(0.7, 0.7, 0.75)
			else:
				var sd := SkillDB.get_data(sid)
				b.text = "%d\n%s" % [si + 1, String(sd.get("name", "?"))]
				b.tooltip_text = "%s\n%s\nKoszt: %d · cd %.1fs" % [sd.get("name", ""), sd.get("desc", ""), int(sd.get("cost", 0.0)), float(sd.get("cd", 0.0))]
				b.add_theme_color_override("font_color", sd.get("col", UiKit.TEXT))
				b.modulate = Color.WHITE
	# statystyki
	for c in _stats_box.get_children():
		c.queue_free()
	var s := GameState.compute_stats()
	_row("Życie", "%.0f" % s["max_health"], UiKit.HP)
	_row("Energia", "%.0f" % s["max_energy"], UiKit.EN)
	_row("Siła", "%.2f" % s["strength"], UiKit.TEXT)
	_row("Obrona", "%.2f" % s["defense"], UiKit.TEXT)
	_row("Szybkość", "%.2f" % s["speed"], UiKit.ACCENT2)
	_row("Krytyk", "%.0f%%" % (s["crit"] * 100.0), UiKit.XP)
	_row("Szansa na łupy", "%.2f" % s["luck"], UiKit.ACCENT)
	# plecak
	for c in _bag_box.get_children():
		c.queue_free()
	var any := false
	for id2 in GameState.consumed_ids():
		var n := GameState.item_count(id2)
		if n <= 0:
			continue
		any = true
		var d2 := ItemDB.get_data(id2)
		var b2 := Button.new()
		b2.tooltip_text = String(d2["desc"])
		b2.custom_minimum_size = Vector2(54, 54)
		b2.icon = Art.item_icon(id2, 34)
		b2.expand_icon = true
		b2.text = "x%d" % n
		b2.add_theme_font_size_override("font_size", 11)
		b2.add_theme_stylebox_override("normal", UiKit.sb(UiKit.BG3, 8))
		b2.add_theme_stylebox_override("hover", UiKit.sb(Color(0.25, 0.3, 0.4), 8, 2, UiKit.GOOD))
		var use_id: String = id2
		b2.pressed.connect(func(): _use(use_id))
		_bag_box.add_child(b2)
	if not any:
		_bag_box.add_child(UiKit.label("pusto", 14, UiKit.DIM))

func _row(name_text: String, value: String, col: Color) -> void:
	var h := UiKit.hbox(4)
	var a := UiKit.label(name_text, 14, UiKit.DIM)
	a.custom_minimum_size = Vector2(140, 0)
	h.add_child(a)
	h.add_child(UiKit.label(value, 14, col))
	_stats_box.add_child(h)

func _make_cell() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(96, 96)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_stylebox_override("normal", UiKit.sb(UiKit.BG2, 8))
	b.add_theme_stylebox_override("hover", UiKit.sb(UiKit.BG3, 8, 2, UiKit.ACCENT))
	b.add_theme_stylebox_override("pressed", UiKit.sb(UiKit.BG3, 8, 2, UiKit.ACCENT))
	return b

func _open_slot(slot: String) -> void:
	_mode = "equipment"
	_cur_slot = slot
	Audio.play("select")
	_rebuild_list()

func _open_skill_slot(i: int) -> void:
	_mode = "skills"
	_cur_skill = i
	Audio.play("select")
	_rebuild_list()

func _rebuild_list() -> void:
	for c in _list_box.get_children():
		c.queue_free()
	if _mode == "skills":
		_rebuild_skills()
		return
	var slot_names := {"weapon": "BROŃ", "armor": "PANCERZ", "accessory": "AKCESORIA"}
	_list_title.text = String(slot_names.get(_cur_slot, _cur_slot))
	var eq := GameState.equipped()
	var owned: Array = GameState.owned_gear_of_slot(_cur_slot)
	if owned.is_empty():
		var empty := UiKit.panel(UiKit.BG2, 10)
		var ev := UiKit.vbox(4)
		empty.add_child(ev)
		ev.add_child(UiKit.label("Brak przedmiotów w tej kategorii.", 16, UiKit.DIM))
		ev.add_child(UiKit.label("Kup sprzęt w sklepie między etapami.", 13, UiKit.DIM))
		_list_box.add_child(empty)
		return
	for id in owned:
		var d := ItemDB.get_data(id)
		var is_eq: bool = String(eq.get(_cur_slot, "")) == id
		var row := UiKit.panel(UiKit.BG3 if is_eq else UiKit.BG2, 8)
		var tip := "%s\n%s" % [String(d["name"]), String(d["desc"])]
		if String(d.get("slot", "")) == "weapon":
			var eff := ItemDB.weapon_desc(id)
			if eff != "":
				tip += "\nEfekt: %s" % eff
		row.tooltip_text = tip
		var h := UiKit.hbox(8)
		row.add_child(h)
		h.add_child(UiKit.icon(Art.item_icon(id, 40), 40))
		var v := UiKit.vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var t := UiKit.label("%s%s" % [String(d["name"]), "  ✔" if is_eq else ""], 17, UiKit.ACCENT if is_eq else UiKit.TEXT)
		v.add_child(t)
		v.add_child(UiKit.label(String(d["desc"]), 13, UiKit.DIM))
		v.add_child(UiKit.label(_stat_text(d, id), 13, UiKit.GOOD))
		if not is_eq:
			var b := UiKit.button("Załóż", 15)
			b.custom_minimum_size = Vector2(96, 34)
			var use_id: String = id
			b.pressed.connect(func():
				GameState.equip_item(use_id)
				_rebuild_list()
				_refresh())
			h.add_child(b)
		_list_box.add_child(row)

func _rebuild_skills() -> void:
	_list_title.text = "SKILE — slot %d (klawisz %d)" % [_cur_skill + 1, _cur_skill + 1]
	var cur := String(GameState.skill_slots()[_cur_skill]) if _cur_skill < GameState.skill_slots().size() else ""
	for id in SkillDB.all():
		var d := SkillDB.get_data(id)
		var is_eq: bool = cur == id
		var row := UiKit.panel(UiKit.BG3 if is_eq else UiKit.BG2, 8)
		row.tooltip_text = "%s\n%s" % [d.get("name", ""), d.get("desc", "")]
		var h := UiKit.hbox(8)
		row.add_child(h)
		var col: Color = d.get("col", UiKit.TEXT)
		var chip := UiKit.panel(col, 6)
		chip.custom_minimum_size = Vector2(40, 40)
		h.add_child(chip)
		var v := UiKit.vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UiKit.label("%s%s" % [String(d.get("name", "?")), "  ✔" if is_eq else ""], 17, UiKit.ACCENT if is_eq else UiKit.TEXT))
		v.add_child(UiKit.label(String(d.get("desc", "")), 13, UiKit.DIM))
		v.add_child(UiKit.label("Koszt: %d energii · cd %.1fs" % [int(d.get("cost", 0.0)), float(d.get("cd", 0.0))], 13, UiKit.ACCENT2))
		if not is_eq:
			var b := UiKit.button("Przypisz", 15)
			b.custom_minimum_size = Vector2(110, 34)
			var use_id: String = id
			var idx := _cur_skill
			b.pressed.connect(func():
				GameState.set_skill_slot(idx, use_id)
				_rebuild_list()
				_refresh())
			h.add_child(b)
		_list_box.add_child(row)
	var clear_row := UiKit.panel(UiKit.BG2, 8)
	var ch := UiKit.hbox(8)
	clear_row.add_child(ch)
	ch.add_child(UiKit.label("— pusty slot —", 15, UiKit.DIM))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(spacer)
	var cb := UiKit.button("Wyczyść", 15)
	cb.custom_minimum_size = Vector2(110, 34)
	var cidx := _cur_skill
	cb.pressed.connect(func():
		GameState.set_skill_slot(cidx, "")
		_rebuild_list()
		_refresh())
	ch.add_child(cb)
	_list_box.add_child(clear_row)

func _stat_text(d: Dictionary, id: String = "") -> String:
	var names := {
		"strength": "Siła", "defense": "Obrona", "health": "Życie", "energy": "Energia",
		"speed": "Szybkość", "crit": "Krytyk", "fury": "Furia", "luck": "Łupy", "poise": "Pewność",
	}
	var out: Array = []
	if String(d.get("slot", "")) == "weapon" and id != "":
		var wa := ItemDB.weapon_attacks(id)
		var light: Array = wa.get("light", [])
		var heavy: Dictionary = wa.get("heavy", {})
		var parts: Array = []
		if light.size() > 0:
			parts.append("%.0f" % float(light[0].get("dmg", 0.0)))
		if light.size() > 1:
			parts.append("%.0f" % float(light[1].get("dmg", 0.0)))
		parts.append("%.0f" % float(heavy.get("dmg", 0.0)))
		out.append("Obrażenia: %s" % " · ".join(parts))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		var v := float(st[k])
		var txt := ""
		if k in ["crit", "luck"]:
			txt = "%+.0f%%" % (v * 100.0)
		elif k in ["health", "energy"]:
			txt = "%+.0f" % v
		else:
			txt = "%+.0f%%" % (v * 100.0)
		out.append("%s %s" % [String(names.get(k, k)), txt])
	return "  ".join(out)

func _use(id: String) -> void:
	if ItemDB.is_consumable(id):
		if GameState.has_run() and GameState.run.get("character", "") != "":
			# zużycie działa w środku etapu
			var ps := get_tree().get_nodes_in_group("player")
			if ps.size() > 0 and ps[0] is Player:
				if (ps[0] as Player).use_consumable(id):
					_refresh()
					return
		var d := ItemDB.get_data(id)
		var use: Dictionary = d.get("use", {})
		GameState.remove_item(id, 1)
		GameState.commit_backpack()
		GameState.toast.emit("Zużyto: %s (+%.0f życia)" % [String(d["name"]), float(use.get("health", 0.0))], UiKit.GOOD)
		Audio.play("drink", 1.0, -4.0)
		_refresh()
	else:
		GameState.toast.emit("%s wrzucasz do worka na walkę (klawisz I)" % String(ItemDB.get_data(id)["name"]), UiKit.ACCENT2)
		Audio.play("deny", 1.2, -12.0)

func _on_start() -> void:
	Audio.play("confirm")
	GameState.commit_backpack()
	Flow.goto("game", {"stage": int(GameState.run.get("stage_index", 0))})
