class_name UiLoadout
extends Control
## Ekwipunek w stylu Minecrafta: 7 slotów wyposażenia, 40 slotów plecaka, szczegóły
## przedmiotu, statystyki i skille. Przedmioty przenosi się przeciąganiem lub przyciskami.
## Otwierane z wyboru postaci albo z pauzy (jako nakładka).

signal on_close

var from := "select"
var _visual: CreatureVisual
var _char_label: Label
var _stats_box: VBoxContainer
var _equip_slots: Dictionary = {}
var _inv_slots: Array = []
var _skill_cells: Array = []
var _detail_box: VBoxContainer
var _free_label: Label
var _overflow_btn: Button
var _mode := "item"  # item | skills
var _sel_kind := ""
var _sel_key: Variant = null
var _cur_skill := 0

const COLUMNS := 8
const CELL := 54

# ------------------------------------------------------------------ slot ---

class Slot extends Button:
	var ui: UiLoadout
	var kind := "inv"   # inv | equip
	var key: Variant = 0

	func _get_drag_data(_at: Vector2) -> Variant:
		var e: Variant = ui.entry_at(kind, key)
		if e == null:
			return null
		var prev := TextureRect.new()
		prev.texture = Art.item_icon(String(e["id"]), 40)
		prev.custom_minimum_size = Vector2(40, 40)
		prev.modulate.a = 0.85
		set_drag_preview(prev)
		return {"kind": kind, "key": key}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("kind") and ui.can_drop(data, kind, key)

	func _drop_data(_at: Vector2, data: Variant) -> void:
		ui.drop(data, kind, key)

func setup(source: String) -> void:
	from = source

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(6)
	UiKit.full(root)
	root.offset_left = 16.0
	root.offset_right = -16.0
	root.offset_top = 8.0
	root.offset_bottom = -8.0
	add_child(root)
	root.add_child(UiKit.title("EKWIPUNEK", 36))

	var body := UiKit.hbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	# --- lewa: postać, wyposażenie, skille, statystyki
	var left := UiKit.panel(UiKit.BG, 10)
	left.custom_minimum_size = Vector2(330, 0)
	body.add_child(left)
	var lscroll := ScrollContainer.new()
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lscroll)
	var lv := UiKit.vbox(6)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lscroll.add_child(lv)
	_char_label = UiKit.label("", 20, UiKit.ACCENT)
	lv.add_child(_char_label)
	var top := UiKit.hbox(8)
	lv.add_child(top)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(120, 130)
	top.add_child(holder)
	_visual = CreatureVisual.new()
	_visual.position = Vector2(55, 124)
	holder.add_child(_visual)
	var slots_col := UiKit.vbox(4)
	top.add_child(slots_col)
	for slot in ItemDB.EQUIP_SLOTS:
		var row := UiKit.hbox(4)
		slots_col.add_child(row)
		var s := _make_slot("equip", String(slot))
		row.add_child(s)
		_equip_slots[String(slot)] = s
		var lab := UiKit.label(String(ItemDB.SLOT_NAMES[slot]), 12, UiKit.DIM)
		lab.custom_minimum_size = Vector2(70, 0)
		row.add_child(lab)
	lv.add_child(UiKit.label("SKILE (klawisze 1–9)", 13, UiKit.DIM))
	var srow := UiKit.hbox(4)
	lv.add_child(srow)
	for i in range(GameState.SKILL_SLOTS):
		var b := Button.new()
		b.custom_minimum_size = Vector2(CELL - 12, CELL)
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_stylebox_override("normal", UiKit.sb(UiKit.BG2, 8))
		b.add_theme_stylebox_override("hover", UiKit.sb(UiKit.BG3, 8, 2, UiKit.ACCENT))
		var idx: int = i
		b.pressed.connect(func(): _open_skill_slot(idx))
		srow.add_child(b)
		_skill_cells.append(b)
	lv.add_child(UiKit.label("STATYSTYKI", 13, UiKit.DIM))
	var sc := UiKit.panel(UiKit.BG2, 8)
	lv.add_child(sc)
	_stats_box = UiKit.vbox(1)
	sc.add_child(_stats_box)

	# --- środek: 40 slotów
	var mid := UiKit.panel(UiKit.BG, 10)
	body.add_child(mid)
	var mv := UiKit.vbox(6)
	mid.add_child(mv)
	mv.add_child(UiKit.label("PLECAK — 40 SLOTÓW", 15, UiKit.ACCENT))
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	mv.add_child(grid)
	for i in GameState.INV_SIZE:
		var s2 := _make_slot("inv", i)
		grid.add_child(s2)
		_inv_slots.append(s2)
	_free_label = UiKit.label("", 13, UiKit.DIM)
	mv.add_child(_free_label)
	var tools := UiKit.hbox(6)
	mv.add_child(tools)
	var sort := UiKit.button("Sortuj", 14, UiKit.ACCENT2)
	sort.pressed.connect(func(): GameState.inv_sort(); Audio.play("select"); _refresh())
	tools.add_child(sort)
	_overflow_btn = UiKit.button("Skrytka", 14, UiKit.BAD)
	_overflow_btn.pressed.connect(_claim_overflow)
	tools.add_child(_overflow_btn)

	# --- prawa: szczegóły / wybór skilla
	var right := UiKit.panel(UiKit.BG, 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(300, 0)
	right.clip_contents = true
	body.add_child(right)
	var rscroll := ScrollContainer.new()
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rscroll)
	_detail_box = UiKit.vbox(5)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.add_child(_detail_box)

	# --- przyciski
	var row2 := UiKit.hbox(12)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row2)
	if from == "select":
		var back := UiKit.button("Wybierz innego", 18)
		back.pressed.connect(func(): Audio.play("back"); on_close.emit())
		row2.add_child(back)
		var go := UiKit.button("Wyrusz do etapu 1", 22)
		go.custom_minimum_size = Vector2(280, 46)
		go.pressed.connect(_on_start)
		row2.add_child(go)
	else:
		var back2 := UiKit.button("Wróć", 18)
		back2.pressed.connect(func(): Audio.play("back"); on_close.emit())
		row2.add_child(back2)
	_refresh()

func _make_slot(kind: String, key: Variant) -> Slot:
	var b := Slot.new()
	b.ui = self
	b.kind = kind
	b.key = key
	b.custom_minimum_size = Vector2(CELL, CELL)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(func(): _select(kind, key))
	return b

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		Audio.play("back")
		on_close.emit()

# -------------------------------------------------------------- dane slotów ---

func entry_at(kind: String, key: Variant) -> Variant:
	if kind == "inv":
		return GameState.inv()[int(key)]
	var id := String(GameState.equipped().get(String(key), ""))
	if id == "":
		return null
	return {"id": id, "n": 1, "q": GameState.equipped_q(String(key)), "m": GameState.equipped_meta(String(key))}

func can_drop(data: Dictionary, to_kind: String, to_key: Variant) -> bool:
	var fk := String(data["kind"])
	var src: Variant = entry_at(fk, data["key"])
	if src == null:
		return false
	if fk == "inv" and to_kind == "inv":
		return int(data["key"]) != int(to_key)
	if fk == "inv" and to_kind == "equip":
		return ItemDB.fits_slot(String(src["id"]), String(to_key))
	if fk == "equip" and to_kind == "inv":
		var dst: Variant = GameState.inv()[int(to_key)]
		return dst == null or ItemDB.fits_slot(String(dst["id"]), String(data["key"]))
	if fk == "equip" and to_kind == "equip":
		var eq := GameState.equipped()
		var there := String(eq.get(String(to_key), ""))
		return data["key"] != to_key and ItemDB.fits_slot(String(src["id"]), String(to_key)) and (there == "" or ItemDB.fits_slot(there, String(data["key"])))
	return false

func drop(data: Dictionary, to_kind: String, to_key: Variant) -> void:
	var fk := String(data["kind"])
	var fkey: Variant = data["key"]
	if fk == "inv" and to_kind == "inv":
		GameState.inv_swap(int(fkey), int(to_key))
	elif fk == "inv" and to_kind == "equip":
		var e: Dictionary = GameState.inv()[int(fkey)]
		GameState.equip_item(String(e["id"]), String(to_key))
	elif fk == "equip" and to_kind == "inv":
		var dst: Variant = GameState.inv()[int(to_key)]
		if dst == null:
			var moved: Variant = entry_at("equip", fkey)
			if GameState.unequip_item(String(fkey)):
				for i in GameState.INV_SIZE:
					var ee: Variant = GameState.inv()[i]
					if ee is Dictionary and String(ee["id"]) == String(moved["id"]) and is_equal_approx(float(ee.get("q", 1.0)), float(moved["q"])):
						GameState.inv_swap(i, int(to_key))
						break
		else:
			GameState.equip_item(String((dst as Dictionary)["id"]), String(fkey))
	elif fk == "equip" and to_kind == "equip":
		var eq := GameState.equipped()
		var a := String(eq.get(String(fkey), ""))
		var b := String(eq.get(String(to_key), ""))
		var qa := GameState.equipped_q(String(fkey))
		var qb := GameState.equipped_q(String(to_key))
		var ma := GameState.equipped_meta(String(fkey)).duplicate(true)
		var mb := GameState.equipped_meta(String(to_key)).duplicate(true)
		var cp := GameState._cp()
		if b == "":
			eq.erase(String(fkey))
			cp["equip_q"].erase(String(fkey))
			cp["equip_m"].erase(String(fkey))
		else:
			eq[String(fkey)] = b
			cp["equip_q"][String(fkey)] = qb
			if mb.is_empty(): cp["equip_m"].erase(String(fkey))
			else: cp["equip_m"][String(fkey)] = mb
		eq[String(to_key)] = a
		cp["equip_q"][String(to_key)] = qa
		if ma.is_empty(): cp["equip_m"].erase(String(to_key))
		else: cp["equip_m"][String(to_key)] = ma
		GameState.refresh_stats()
		GameState.save_game()
	Audio.play("select")
	_sel_kind = to_kind
	_sel_key = to_key
	_refresh()

func _select(kind: String, key: Variant) -> void:
	_mode = "item"
	_sel_kind = kind
	_sel_key = key
	Audio.play("select")
	_refresh()

func _open_skill_slot(i: int) -> void:
	_mode = "skills"
	_cur_skill = i
	Audio.play("select")
	_refresh()

# ------------------------------------------------------------------ odświeżanie ---

func _style_slot(b: Button, entry: Variant, selected: bool) -> void:
	var border := Color(0.3, 0.33, 0.42)
	var width := 2.0
	if entry != null:
		border = ItemDB.rarity_color_of(ItemDB.rarity_of_entry(entry))
	if selected:
		border = UiKit.ACCENT
		width = 3.0
	b.add_theme_stylebox_override("normal", UiKit.sb(UiKit.BG2, 6, width, border))
	b.add_theme_stylebox_override("hover", UiKit.sb(UiKit.BG3, 6, width, border.lightened(0.3)))
	b.add_theme_stylebox_override("pressed", UiKit.sb(UiKit.BG3, 6, width, border))
	if entry == null:
		b.icon = null
		b.text = ""
		b.tooltip_text = "Pusty slot"
		return
	var id := String(entry["id"])
	b.icon = Art.item_icon(id, 40)
	var n := int(entry["n"])
	b.text = "" if n <= 1 else str(n)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_color_override("font_color", UiKit.TEXT)
	b.tooltip_text = "%s (%s)" % [String(ItemDB.get_data(id).get("name", id)), String(ItemDB.RARITY_NAMES.get(ItemDB.rarity_of(id), ""))]

func _refresh() -> void:
	var id := GameState.current_character_id()
	var data := CharacterDB.get_data(id)
	_char_label.text = "%s — poziom %d" % [String(data["title"]), int(GameState.char_profile(id).get("level", 1))]
	var look := GameState.look_id()
	_visual.configure(look if look != "" else id, CharacterDB.get_data(look if look != "" else id)["pal"], 1.3)
	GameState.dress(_visual)
	for slot in _equip_slots:
		var b: Slot = _equip_slots[slot]
		var e: Variant = entry_at("equip", slot)
		_style_slot(b, e, _sel_kind == "equip" and _sel_key == slot)
		if e == null:
			b.tooltip_text = "%s — pusty slot" % String(ItemDB.SLOT_NAMES[slot])
	var inv_a := GameState.inv()
	for i in _inv_slots.size():
		_style_slot(_inv_slots[i], inv_a[i], _sel_kind == "inv" and _sel_key == i)
	_free_label.text = "Wolne sloty: %d / %d" % [GameState.inv_free_slots(), GameState.INV_SIZE]
	var ov := GameState.overflow_items().size()
	_overflow_btn.visible = ov > 0
	_overflow_btn.text = "Skrytka (%d) — odbierz" % ov
	_refresh_skills()
	_refresh_stats()
	_rebuild_detail()

func _refresh_skills() -> void:
	var skills := GameState.skill_slots()
	for i in _skill_cells.size():
		var b: Button = _skill_cells[i]
		var sid := String(skills[i]) if i < skills.size() else ""
		var sel := _mode == "skills" and _cur_skill == i
		b.add_theme_stylebox_override("normal", UiKit.sb(UiKit.BG2, 8, 3.0 if sel else 1.0, UiKit.ACCENT if sel else Color(0.3, 0.33, 0.42)))
		if sid == "" or not SkillDB.has(sid):
			b.text = "%d\n—" % (i + 1)
			b.tooltip_text = "Pusty slot skilla %d" % (i + 1)
			b.add_theme_color_override("font_color", UiKit.DIM)
		else:
			var sd := SkillDB.get_data(sid)
			b.text = "%d\n%s" % [i + 1, String(sd.get("name", "?")).substr(0, 5)]
			b.tooltip_text = "%s\n%s\nKoszt: %d · cd %.1fs" % [sd.get("name", ""), sd.get("desc", ""), int(sd.get("cost", 0.0)), float(sd.get("cd", 0.0))]
			b.add_theme_color_override("font_color", sd.get("col", UiKit.TEXT))

func _refresh_stats() -> void:
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
	if float(s.get("regen", 0.0)) > 0.0:
		_row("Regeneracja", "%.1f HP/s" % s["regen"], UiKit.GOOD)
	if float(s.get("lifesteal", 0.0)) > 0.0:
		_row("Kradzież życia", "%.0f%%" % (s["lifesteal"] * 100.0), UiKit.GOOD)
	if float(s.get("dmg_reduction", 0.0)) > 0.0:
		_row("Redukcja obrażeń", "%.0f%%" % (s["dmg_reduction"] * 100.0), UiKit.GOOD)
	if float(s.get("xp_mult", 0.0)) > 0.0:
		_row("Bonus do XP", "+%.0f%%" % (s["xp_mult"] * 100.0), UiKit.XP)
	if float(s.get("gold_mult", 0.0)) > 0.0:
		_row("Bonus do złota", "+%.0f%%" % (s["gold_mult"] * 100.0), Color(1, 0.85, 0.4))

func _row(name_text: String, value: String, col: Color) -> void:
	var h := UiKit.hbox(4)
	var a := UiKit.label(name_text, 13, UiKit.DIM)
	a.custom_minimum_size = Vector2(150, 0)
	h.add_child(a)
	h.add_child(UiKit.label(value, 13, col))
	_stats_box.add_child(h)

# ------------------------------------------------------------------ szczegóły ---

const STAT_NAMES := {
	"strength": "Siła", "defense": "Obrona", "health": "Życie", "energy": "Energia",
	"speed": "Szybkość", "crit": "Krytyk", "fury": "Furia", "luck": "Łupy", "poise": "Pewność",
	"pet_dmg": "Obrażenia peta", "pet_speed": "Szybkość peta", "pet_hp": "Życie peta", "pet_range": "Zasięg peta",
}
const FX_NAMES := {
	"regen": "Regeneracja: +%.1f HP/s", "lifesteal": "Kradzież życia: %.0f%%", "dmg_reduction": "Mniejsze obrażenia: %.0f%%",
	"xp_mult": "Więcej XP: +%.0f%%", "gold_mult": "Więcej złota: +%.0f%%",
	"skill_power": "Moc umiejętności: +%.0f%%", "skill_cdr": "Krótsze odnowienie umiejętności: %.0f%%",
	"skill_cost": "Tańsze umiejętności: %.0f%%", "skill_range": "Zasięg umiejętności: +%.0f%%", "energy_regen": "Regeneracja energii: +%.1f/s",
}

## Etykieta z zawijaniem tekstu (nie rozpycha panelu).
func _wl(text: String, size: int = 14, col: Color = UiKit.TEXT) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _rebuild_detail() -> void:
	for c in _detail_box.get_children():
		c.queue_free()
	if _mode == "skills":
		_build_skill_picker()
		return
	if _sel_kind == "":
		_detail_box.add_child(_wl("Wybierz przedmiot", 20, UiKit.ACCENT))
		_detail_box.add_child(_wl("Kliknij przedmiot, aby zobaczyć opis i statystyki. Możesz też przeciągać przedmioty między slotami, a na wyposażenie upuścić je na odpowiedni slot.", 14, UiKit.DIM))
		_detail_box.add_child(_wl("Amulety działają tylko w slotach amuletów. Wyposażenie petów zakładasz w menu petów.", 13, UiKit.DIM))
		return
	var e: Variant = entry_at(_sel_kind, _sel_key)
	if e == null:
		_detail_box.add_child(_wl("Pusty slot", 20, UiKit.DIM))
		if _sel_kind == "equip":
			_detail_box.add_child(_wl("Slot: %s" % String(ItemDB.SLOT_NAMES.get(String(_sel_key), "")), 14, UiKit.DIM))
		return
	var id := String(e["id"])
	var d := ItemDB.get_data(id)
	var meta: Dictionary = e.get("m", {})
	var q := float(e.get("q", 1.0)) * ItemDB.meta_mult(id, meta)
	var rar := ItemDB.meta_rarity(id, meta)
	var rcol := ItemDB.rarity_color_of(rar)
	var head := UiKit.hbox(8)
	_detail_box.add_child(head)
	head.add_child(UiKit.icon(Art.item_icon(id, 48), 48))
	var hv := UiKit.vbox(0)
	head.add_child(hv)
	hv.add_child(UiKit.label(String(d.get("name", id)), 22, rcol))
	hv.add_child(UiKit.label(String(ItemDB.RARITY_NAMES.get(rar, "")), 14, rcol))
	var kind_txt := String(ItemDB.SLOT_NAMES.get(String(d.get("slot", "")), ""))
	match String(d.get("slot", "")):
		"consumable": kind_txt = "Mikstura"
		"throwable": kind_txt = "Do rzucania"
		"material": kind_txt = "Materiał kowalski"
		"key": kind_txt = "Przedmiot fabularny"
		"pet_gear": kind_txt = "Wyposażenie peta"
	hv.add_child(UiKit.label(kind_txt, 13, UiKit.DIM))
	_detail_box.add_child(_wl(String(d.get("desc", "")), 14, UiKit.TEXT))
	if absf(float(e.get("q", 1.0)) - 1.0) > 0.001:
		_detail_box.add_child(_wl("Jakość wykonania: %.0f%%" % (float(e.get("q", 1.0)) * 100.0), 14, UiKit.GOOD if float(e.get("q", 1.0)) >= 1.0 else UiKit.BAD))
	if not meta.is_empty():
		var ws: Array = meta.get("ws", [])
		if not ws.is_empty():
			_detail_box.add_child(_wl("Runy: %s%s" % [" · ".join(ws), ("  (wzmocnienie +%d%%)" % (int(meta.get("b", 0)) * 20)) if int(meta.get("b", 0)) > 0 else ""], 14, Color(1.0, 0.9, 0.5)))
	if String(d.get("slot", "")) == "weapon":
		var wa := ItemDB.weapon_attacks(id)
		var light: Array = wa.get("light", [])
		var heavy: Dictionary = wa.get("heavy", {})
		var parts: Array = []
		for i in mini(2, light.size()):
			parts.append("%.0f" % float(light[i].get("dmg", 0.0)))
		parts.append("%.0f" % float(heavy.get("dmg", 0.0)))
		_detail_box.add_child(_wl("Obrażenia: %s" % " · ".join(parts), 14, UiKit.TEXT))
		var eff := ItemDB.weapon_desc(id)
		if eff != "":
			_detail_box.add_child(_wl("Efekt: %s" % eff, 14, UiKit.ACCENT2))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		var v := float(st[k]) * q
		var txt := ""
		if k in ["health", "energy"]:
			txt = "%+.0f" % v
		else:
			txt = "%+.0f%%" % (v * 100.0)
		_detail_box.add_child(_wl("%s %s" % [String(STAT_NAMES.get(k, k)), txt], 14, UiKit.GOOD if v >= 0.0 else UiKit.BAD))
	var fx: Dictionary = (d.get("fx", {}) as Dictionary).duplicate()
	for k in meta.get("fx", {}):
		fx[k] = float(fx.get(k, 0.0)) + float(meta["fx"][k])
	for k in fx:
		var f := float(fx[k])
		var fmt := String(FX_NAMES.get(k, "%s"))
		_detail_box.add_child(_wl(fmt % (f if k in ["regen", "energy_regen"] else f * 100.0), 14, rcol))
	if d.has("use"):
		var u: Dictionary = d["use"]
		if float(u.get("health", 0.0)) > 0.0:
			_detail_box.add_child(_wl("Leczy %s życia" % ("całe" if float(u["health"]) > 900.0 else str(int(u["health"]))), 14, UiKit.GOOD))
		if float(u.get("energy", 0.0)) > 0.0:
			_detail_box.add_child(_wl("Przywraca %d energii" % int(minf(float(u["energy"]), 999.0)), 14, UiKit.EN))
	if d.has("throw"):
		var t: Dictionary = d["throw"]
		_detail_box.add_child(_wl("Obrażenia %d, zasięg %d" % [int(t["damage"]), int(t["radius"])], 14, UiKit.TEXT))
	_detail_box.add_child(UiKit.sep(6))
	var row := UiKit.hbox(6)
	_detail_box.add_child(row)
	var slot_s := String(d.get("slot", ""))
	if _sel_kind == "equip":
		var un := UiKit.button("Zdejmij", 16)
		var key_s: String = String(_sel_key)
		un.pressed.connect(func():
			if GameState.unequip_item(key_s):
				Audio.play("back")
				_sel_kind = ""
			else:
				Audio.play("deny")
			_refresh())
		row.add_child(un)
	else:
		var idx: int = int(_sel_key)
		if ItemDB.is_gear(id):
			var eq_b := UiKit.button("Załóż", 16)
			eq_b.pressed.connect(func():
				if GameState.equip_item(id):
					Audio.play("confirm")
					_sel_kind = ""
				else:
					Audio.play("deny")
				_refresh())
			row.add_child(eq_b)
		elif ItemDB.is_consumable(id) or ItemDB.is_throwable(id):
			var use_b := UiKit.button("Użyj", 16)
			use_b.pressed.connect(func(): _use(id); _refresh())
			row.add_child(use_b)
		var drop_b := UiKit.button("Wyrzuć", 16, UiKit.BAD)
		drop_b.pressed.connect(func():
			GameState.inv_discard(idx)
			Audio.play("deny")
			_sel_kind = ""
			_refresh())
		row.add_child(drop_b)
		if slot_s == "pet_gear":
			_detail_box.add_child(_wl("Załóż u peta w menu towarzyszy.", 13, UiKit.DIM))

func _claim_overflow() -> void:
	var moved := GameState.claim_overflow()
	Audio.play("confirm" if moved > 0 else "deny")
	if moved == 0:
		GameState.toast.emit("Nadal brak miejsca w ekwipunku.", UiKit.BAD)
	_refresh()

# --------------------------------------------------------------------- skille ---

func _build_skill_picker() -> void:
	_detail_box.add_child(_wl("SKILE — slot %d (klawisz %d)" % [_cur_skill + 1, _cur_skill + 1], 20, UiKit.ACCENT))
	_detail_box.add_child(_wl("Nowe umiejętności odblokujesz w drzewku umiejętności (pauza → Umiejętności).", 13, UiKit.DIM))
	var cur := String(GameState.skill_slots()[_cur_skill]) if _cur_skill < GameState.skill_slots().size() else ""
	for id in GameState.available_skills():
		var d := SkillDB.get_data(String(id))
		var is_eq: bool = cur == id
		var row := UiKit.panel(UiKit.BG3 if is_eq else UiKit.BG2, 8)
		row.tooltip_text = "%s\n%s" % [d.get("name", ""), d.get("desc", "")]
		var h := UiKit.hbox(8)
		row.add_child(h)
		var col: Color = d.get("col", UiKit.TEXT)
		var chip := UiKit.panel(col, 6)
		chip.custom_minimum_size = Vector2(30, 30)
		h.add_child(chip)
		var v := UiKit.vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var rank := GameState.skill_rank(String(id))
		var title_txt := String(d.get("name", "?")) + ("  ✔" if is_eq else "") + ("  (poz. %d)" % rank if rank > 1 else "")
		v.add_child(_wl(title_txt, 15, UiKit.ACCENT if is_eq else UiKit.TEXT))
		v.add_child(_wl(String(d.get("desc", "")), 12, UiKit.DIM))
		v.add_child(_wl("Koszt: %d energii · cd %.1fs" % [int(d.get("cost", 0.0)), float(d.get("cd", 0.0))], 12, UiKit.ACCENT2))
		if not is_eq:
			var b := UiKit.button("Przypisz", 14)
			b.custom_minimum_size = Vector2(90, 30)
			var use_id: String = String(id)
			var slot_i := _cur_skill
			b.pressed.connect(func():
				GameState.set_skill_slot(slot_i, use_id)
				Audio.play("confirm")
				_refresh())
			h.add_child(b)
		_detail_box.add_child(row)
	var clear_row := UiKit.hbox(8)
	clear_row.add_child(_wl("— pusty slot —", 14, UiKit.DIM))
	var cb := UiKit.button("Wyczyść", 14)
	var cidx := _cur_skill
	cb.pressed.connect(func():
		GameState.set_skill_slot(cidx, "")
		Audio.play("back")
		_refresh())
	clear_row.add_child(cb)
	_detail_box.add_child(clear_row)

# --------------------------------------------------------------------- użycie ---

func _use(id: String) -> void:
	if ItemDB.is_consumable(id):
		if GameState.has_run() and GameState.run.get("character", "") != "":
			var ps := get_tree().get_nodes_in_group("player")
			if ps.size() > 0 and ps[0] is Player:
				if (ps[0] as Player).use_consumable(id):
					return
		var d := ItemDB.get_data(id)
		var use: Dictionary = d.get("use", {})
		GameState.remove_item(id, 1)
		GameState.commit_backpack()
		GameState.toast.emit("Zużyto: %s (+%.0f życia)" % [String(d["name"]), float(use.get("health", 0.0))], UiKit.GOOD)
		Audio.play("drink", 1.0, -4.0)
	else:
		GameState.toast.emit("%s wrzucasz do worka na walkę (klawisz I)" % String(ItemDB.get_data(id)["name"]), UiKit.ACCENT2)
		Audio.play("deny", 1.2, -12.0)

func _on_start() -> void:
	Audio.play("confirm")
	GameState.commit_backpack()
	Flow.goto("game", {"stage": int(GameState.run.get("stage_index", 0))})
