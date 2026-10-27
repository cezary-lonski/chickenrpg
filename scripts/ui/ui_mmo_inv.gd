class_name UiMmoInv
extends PanelContainer
## Ekwipunek gracza na serwerze — ten sam układ co w normalnej grze (UiLoadout): 7 slotów wyposażenia, plecak 40 slotów,
## skile 1–9, statystyki i szczegóły przedmiotu, przenoszenie przeciąganiem. Zmiany to żądania do serwera (Mmo.send_inv);
## panel odświeża się z karty postaci (Mmo.my_info). Dla admina dochodzi katalog Creative, dla wszystkich atrybuty.

const COLUMNS := 8
const CELL := 54

var _info: Dictionary = {}
var _char_label: Label
var _visual: CreatureVisual
var _stats_box: VBoxContainer
var _equip_slots: Dictionary = {}
var _inv_slots: Array = []
var _skill_cells: Array = []
var _detail_box: VBoxContainer
var _free_label: Label
var _attr_btn: Button
var _creative_btn: Button
var _mode := "item"  # item | skills | attrs | creative
var _sel_kind := ""
var _sel_key: Variant = null
var _cur_skill := 0
var _search := ""
var _count := 1

class Slot extends Button:
	var ui: UiMmoInv
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

func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.sb(Color(0.05, 0.06, 0.1, 0.97), 12, 3, Color(0.17, 0.11, 0.06)))
	custom_minimum_size = Vector2(1180, 640)
	var root := UiKit.vbox(6)
	add_child(root)
	root.add_child(UiKit.title("EKWIPUNEK", 32))
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
	sort.pressed.connect(func(): Audio.play("select"); Mmo.send_inv("sort"))
	tools.add_child(sort)
	_attr_btn = UiKit.button("Atrybuty", 14, UiKit.ACCENT2)
	_attr_btn.pressed.connect(func(): _mode = "attrs"; Audio.play("select"); _refresh())
	tools.add_child(_attr_btn)
	_creative_btn = UiKit.button("Creative", 14, UiKit.GOOD)
	_creative_btn.pressed.connect(func(): _mode = "creative"; Audio.play("select"); _refresh())
	tools.add_child(_creative_btn)

	# --- prawa: szczegóły / wybór skilla / atrybuty / Creative
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

	var row2 := UiKit.hbox(12)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row2)
	var back := UiKit.button("Wróć (I)", 18)
	back.pressed.connect(func(): Audio.play("back"); visible = false)
	row2.add_child(back)
	if not _info.is_empty():
		_refresh()

# -------------------------------------------------------------- dane slotów ---

func rebuild(info: Dictionary) -> void:
	_info = info
	if info.is_empty() or _detail_box == null:
		return
	_refresh()

func _inv() -> Array:
	return _info.get("inv", [])

func entry_at(kind: String, key: Variant) -> Variant:
	if kind == "inv":
		var inv := _inv()
		return inv[int(key)] if int(key) < inv.size() else null
	var id := String((_info.get("equip", {}) as Dictionary).get(String(key), ""))
	if id == "":
		return null
	var q := float((_info.get("equip_q", {}) as Dictionary).get(String(key), 1.0))
	var m: Dictionary = (_info.get("equip_m", {}) as Dictionary).get(String(key), {})
	return {"id": id, "n": 1, "q": q, "m": m}

func _is_default(slot: String) -> bool:
	return ItemDB.defaults().has(slot) and String(ItemDB.defaults()[slot]) == String((_info.get("equip", {}) as Dictionary).get(slot, ""))

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
		return not _is_default(String(data["key"]))
	return false

func drop(data: Dictionary, to_kind: String, to_key: Variant) -> void:
	var fk := String(data["kind"])
	var fkey: Variant = data["key"]
	if fk == "inv" and to_kind == "inv":
		Mmo.send_inv("swap", str(int(fkey)), str(int(to_key)))
	elif fk == "inv" and to_kind == "equip":
		Mmo.send_inv("equip", str(int(fkey)))
	elif fk == "equip" and to_kind == "inv":
		Mmo.send_inv("unequip", String(fkey))
	Audio.play("select")
	_sel_kind = to_kind
	_sel_key = to_key

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
	var cid := String(_info.get("char", "kurczak"))
	var data := CharacterDB.get_data(cid)
	_char_label.text = "%s — poziom %d" % [String(_info.get("name", data.get("title", ""))), int(_info.get("level", 1))]
	_visual.configure(cid, data["pal"], 1.3)
	_visual.set_gear(CosmeticDB.gear_visual(_info.get("equip", {}), _info.get("equip_m", {})))
	for slot in _equip_slots:
		var b: Slot = _equip_slots[slot]
		var e: Variant = entry_at("equip", slot)
		_style_slot(b, e, _sel_kind == "equip" and _sel_key == slot)
		if e == null:
			b.tooltip_text = "%s — pusty slot" % String(ItemDB.SLOT_NAMES[slot])
	var inv := _inv()
	for i in _inv_slots.size():
		_style_slot(_inv_slots[i], inv[i] if i < inv.size() else null, _sel_kind == "inv" and _sel_key == i)
	_free_label.text = "Wolne sloty: %d / %d" % [GameState.INV_SIZE - inv.size(), GameState.INV_SIZE]
	_creative_btn.visible = bool(_info.get("admin", false))
	_refresh_skills()
	_refresh_stats()
	_rebuild_detail()

func _refresh_skills() -> void:
	var skills: Array = _info.get("skills", [])
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
	var s: Dictionary = _info.get("stats", {})
	_row("Życie", "%.0f" % float(s.get("max_health", 0)), UiKit.HP)
	_row("Siła", "%.2f" % float(s.get("strength", 1)), UiKit.TEXT)
	_row("Obrona", "%.2f" % float(s.get("defense", 1)), UiKit.TEXT)
	_row("Szybkość", "%.2f" % float(s.get("speed", 1)), UiKit.ACCENT2)
	_row("Krytyk", "%.0f%%" % (float(s.get("crit", 0)) * 100.0), UiKit.XP)

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

func _wl(text: String, size: int = 14, col: Color = UiKit.TEXT) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _rebuild_detail() -> void:
	for c in _detail_box.get_children():
		c.queue_free()
	match _mode:
		"skills":
			_build_skill_picker()
			return
		"attrs":
			_build_attrs()
			return
		"creative":
			_build_creative()
			return
	if _sel_kind == "":
		_detail_box.add_child(_wl("Wybierz przedmiot", 20, UiKit.ACCENT))
		_detail_box.add_child(_wl("Kliknij przedmiot, aby zobaczyć opis i statystyki. Możesz też przeciągać przedmioty między slotami, a na wyposażenie upuścić je na odpowiedni slot.", 14, UiKit.DIM))
		_detail_box.add_child(_wl("Amulety działają tylko w slotach amuletów. Wyposażenie petów zakładasz w menu petów (P).", 13, UiKit.DIM))
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
		un.disabled = _is_default(key_s)
		un.pressed.connect(func():
			Audio.play("back")
			Mmo.send_inv("unequip", key_s)
			_sel_kind = "")
		row.add_child(un)
	else:
		var idx: int = int(_sel_key)
		if ItemDB.is_gear(id):
			var eq_b := UiKit.button("Załóż", 16)
			eq_b.pressed.connect(func():
				Audio.play("confirm")
				Mmo.send_inv("equip", str(idx))
				_sel_kind = "")
			row.add_child(eq_b)
		elif ItemDB.is_consumable(id) or ItemDB.is_throwable(id):
			var use_b := UiKit.button("Użyj", 16)
			use_b.pressed.connect(func(): Audio.play("select"); Mmo.send_inv("use", str(idx)))
			row.add_child(use_b)
		var drop_b := UiKit.button("Wyrzuć", 16, UiKit.BAD)
		drop_b.pressed.connect(func():
			Audio.play("deny")
			Mmo.send_inv("drop", str(idx))
			_sel_kind = "")
		row.add_child(drop_b)
		if slot_s == "pet_gear":
			_detail_box.add_child(_wl("Załóż u peta w menu towarzyszy (P).", 13, UiKit.DIM))

# --------------------------------------------------------------------- skille ---

func _build_skill_picker() -> void:
	_detail_box.add_child(_wl("SKILE — slot %d (klawisz %d)" % [_cur_skill + 1, _cur_skill + 1], 20, UiKit.ACCENT))
	var skills: Array = _info.get("skills", [])
	var cur := String(skills[_cur_skill]) if _cur_skill < skills.size() else ""
	for id in _info.get("known_skills", []):
		if not SkillDB.has(String(id)):
			continue
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
		v.add_child(_wl(String(d.get("name", "?")) + ("  ✔" if is_eq else ""), 15, UiKit.ACCENT if is_eq else UiKit.TEXT))
		v.add_child(_wl(String(d.get("desc", "")), 12, UiKit.DIM))
		v.add_child(_wl("Koszt: %d energii · cd %.1fs" % [int(d.get("cost", 0.0)), float(d.get("cd", 0.0))], 12, UiKit.ACCENT2))
		if not is_eq:
			var b := UiKit.button("Przypisz", 14)
			b.custom_minimum_size = Vector2(90, 30)
			var use_id: String = String(id)
			var slot_i := _cur_skill
			b.pressed.connect(func(): Audio.play("confirm"); Mmo.send_inv("skill", str(slot_i), use_id))
			h.add_child(b)
		_detail_box.add_child(row)
	var clear_row := UiKit.hbox(8)
	clear_row.add_child(_wl("— pusty slot —", 14, UiKit.DIM))
	var cb := UiKit.button("Wyczyść", 14)
	var cidx := _cur_skill
	cb.pressed.connect(func(): Audio.play("back"); Mmo.send_inv("skill", str(cidx), ""))
	clear_row.add_child(cb)
	_detail_box.add_child(clear_row)

# ------------------------------------------------------------------- atrybuty ---

func _build_attrs() -> void:
	var pts := int(_info.get("attr_points", 0))
	_detail_box.add_child(_wl("ATRYBUTY", 20, UiKit.ACCENT))
	_detail_box.add_child(_wl("Punkty do rozdania: %d" % pts, 16, UiKit.GOOD if pts > 0 else UiKit.DIM))
	var attrs: Dictionary = _info.get("attrs", {})
	for k in GameState.ATTR_ORDER:
		var def: Dictionary = GameState.ATTRS.get(k, {})
		var row := UiKit.hbox(8)
		var l := _wl("%s: %d  — %s" % [String(def.get("name", k)), int(attrs.get(k, 0)), String(def.get("desc", ""))], 14, UiKit.TEXT)
		row.add_child(l)
		var b := UiKit.button("+1", 14)
		b.custom_minimum_size = Vector2(56, 30)
		b.disabled = pts < 1
		var key: String = String(k)
		b.pressed.connect(func(): Audio.play("select"); Mmo.send_chat_text("/attr %s 1" % key))
		row.add_child(b)
		_detail_box.add_child(row)

# ------------------------------------------------------------------- creative ---

func _build_creative() -> void:
	_detail_box.add_child(_wl("CREATIVE (admin)", 20, UiKit.GOOD))
	var sr := UiKit.hbox(8)
	_detail_box.add_child(sr)
	var le := LineEdit.new()
	le.placeholder_text = "Szukaj przedmiotu…"
	le.text = _search
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sr.add_child(le)
	var sp := SpinBox.new()
	sp.min_value = 1
	sp.max_value = 999
	sp.value = _count
	sp.value_changed.connect(func(v: float): _count = int(v))
	sr.add_child(sp)
	var list := VBoxContainer.new()
	_detail_box.add_child(list)
	var fill := func():
		for c in list.get_children():
			c.queue_free()
		var q := _search.strip_edges().to_lower()
		var ids: Array = ItemDB.LIST.keys()
		ids.sort_custom(func(a, b): return int(ItemDB.LIST[a].get("tier", 0)) < int(ItemDB.LIST[b].get("tier", 0)))
		var shown := 0
		for id in ids:
			var d: Dictionary = ItemDB.LIST[id]
			var nm := String(d.get("name", id))
			if q != "" and not (String(id).to_lower().contains(q) or nm.to_lower().contains(q) or String(d.get("slot", "")).contains(q)):
				continue
			var b := UiKit.button("%s  [%s, T%d]" % [nm, String(d.get("slot", "")), int(d.get("tier", 0))], 12)
			b.custom_minimum_size = Vector2(0, 30)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.icon = Art.item_icon(String(id), 22)
			b.add_theme_color_override("font_color", ItemDB.rarity_color(String(id)))
			var iid: String = String(id)
			b.pressed.connect(func(): Audio.play("select"); Mmo.send_inv("give", iid, str(_count)))
			list.add_child(b)
			shown += 1
			if shown >= 60:
				break
	le.text_changed.connect(func(t: String): _search = t; fill.call())
	fill.call()
	_detail_box.add_child(_wl("Klik = dodaj do plecaka. Admin: komenda /give all dodaje wszystko.", 12, UiKit.DIM))
