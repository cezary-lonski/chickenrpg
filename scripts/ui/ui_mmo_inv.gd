class_name UiMmoInv
extends PanelContainer
## Ekwipunek gracza na serwerze: założone przedmioty, plecak, umiejętności, atrybuty, a dla admina katalog Creative.
## Wszystkie zmiany to żądania do serwera (Mmo.send_inv / komendy czatu); panel odświeża się z karty postaci.

const SLOT_LABELS := {"weapon": "Broń", "armor": "Pancerz", "helmet": "Hełm", "boots": "Buty", "amulet": "Amulet", "accessory": "Akcesorium"}

var _tabs: TabContainer
var _equip_box: VBoxContainer
var _bag: ItemList
var _detail: Label
var _skill_box: VBoxContainer
var _attr_box: VBoxContainer
var _creative_list: ItemList
var _creative_ids: Array = []
var _search: LineEdit
var _count: SpinBox
var _creative_tab: Control
var _bag_ids: Array = []
var _info: Dictionary = {}

func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.sb(Color(0.05, 0.04, 0.08, 0.96), 12, 3, Color(0.17, 0.11, 0.06)))
	custom_minimum_size = Vector2(820, 520)
	var v := UiKit.vbox(6)
	add_child(v)
	v.add_child(UiKit.label("EKWIPUNEK  (I — zamknij)", 20, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_tabs)

	var t1 := HBoxContainer.new()
	t1.name = "Ekwipunek"
	t1.add_theme_constant_override("separation", 12)
	_tabs.add_child(t1)
	_equip_box = UiKit.vbox(4)
	_equip_box.custom_minimum_size = Vector2(300, 0)
	t1.add_child(_equip_box)
	var right := UiKit.vbox(4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t1.add_child(right)
	right.add_child(UiKit.label("Plecak (dwuklik: załóż / użyj, PPM: wyrzuć)", 14, UiKit.DIM))
	_bag = ItemList.new()
	_bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag.max_columns = 1
	_bag.item_activated.connect(_on_bag_activated)
	_bag.item_selected.connect(_on_bag_selected)
	_bag.item_clicked.connect(_on_bag_clicked)
	right.add_child(_bag)
	_detail = UiKit.label("", 13, UiKit.TEXT)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(0, 48)
	right.add_child(_detail)

	var t2 := ScrollContainer.new()
	t2.name = "Umiejętności"
	_tabs.add_child(t2)
	_skill_box = UiKit.vbox(4)
	_skill_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t2.add_child(_skill_box)

	var t3 := ScrollContainer.new()
	t3.name = "Atrybuty"
	_tabs.add_child(t3)
	_attr_box = UiKit.vbox(6)
	_attr_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t3.add_child(_attr_box)

	_creative_tab = VBoxContainer.new()
	_creative_tab.name = "Creative"
	_tabs.add_child(_creative_tab)
	var sr := UiKit.hbox(8)
	_creative_tab.add_child(sr)
	_search = LineEdit.new()
	_search.placeholder_text = "Szukaj przedmiotu…"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_t): _fill_creative())
	sr.add_child(_search)
	sr.add_child(UiKit.label("ile:", 14, UiKit.DIM))
	_count = SpinBox.new()
	_count.min_value = 1
	_count.max_value = 999
	_count.value = 1
	sr.add_child(_count)
	_creative_list = ItemList.new()
	_creative_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_creative_list.item_activated.connect(func(i: int):
		Audio.play("select")
		Mmo.send_inv("give", String(_creative_ids[i]), str(int(_count.value))))
	_creative_tab.add_child(_creative_list)
	_creative_tab.add_child(UiKit.label("Dwuklik = dodaj do plecaka (plecak ma 40 miejsc). Admin: komenda /give all dodaje wszystko.", 12, UiKit.DIM))

func rebuild(info: Dictionary) -> void:
	_info = info
	if info.is_empty() or _tabs == null:
		return
	_build_equip(info)
	_build_bag(info)
	_build_skills(info)
	_build_attrs(info)
	var admin := bool(info.get("admin", false))
	_tabs.set_tab_hidden(3, not admin)
	if admin and _creative_ids.is_empty():
		_fill_creative()

func _build_equip(info: Dictionary) -> void:
	for c in _equip_box.get_children():
		c.queue_free()
	_equip_box.add_child(UiKit.label("Założone", 15, UiKit.ACCENT))
	var eq: Dictionary = info.get("equip", {})
	var eq_m: Dictionary = info.get("equip_m", {})
	for slot in ["weapon", "armor", "helmet", "boots", "amulet", "accessory"]:
		var row := UiKit.hbox(6)
		var iid := String(eq.get(slot, ""))
		row.add_child(UiKit.label("%s:" % SLOT_LABELS.get(slot, slot), 14, UiKit.DIM))
		var nm := String(ItemDB.get_data(iid).get("name", "—")) if iid != "" else "—"
		var l := UiKit.label(nm, 14, ItemDB.rarity_color_of(ItemDB.meta_rarity(iid, eq_m.get(slot, {}))) if iid != "" else UiKit.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if iid != "":
			var b := UiKit.button("Zdejmij", 12)
			b.custom_minimum_size = Vector2(70, 26)
			b.pressed.connect(func(): Mmo.send_inv("unequip", slot))
			row.add_child(b)
		_equip_box.add_child(row)
	var st: Dictionary = info.get("stats", {})
	_equip_box.add_child(UiKit.sep(6))
	_equip_box.add_child(UiKit.label("Statystyki", 15, UiKit.ACCENT))
	_equip_box.add_child(UiKit.label("HP %d   Siła %.2f   Obrona %.2f\nSzybkość %.2f   Krytyk %.0f%%" % [
		int(st.get("max_health", 0)), float(st.get("strength", 1)), float(st.get("defense", 1)), float(st.get("speed", 1)), float(st.get("crit", 0)) * 100.0], 13, UiKit.TEXT))

func _build_bag(info: Dictionary) -> void:
	_bag.clear()
	_bag_ids.clear()
	for e in info.get("inv", []):
		var id := String(e["id"])
		var d := ItemDB.get_data(id)
		var txt := "%s x%d" % [String(d.get("name", id)), int(e["n"])] if int(e["n"]) > 1 else String(d.get("name", id))
		if e.has("q") and not is_equal_approx(float(e["q"]), 1.0):
			txt += "  (jakość %.0f%%)" % (float(e["q"]) * 100.0)
		_bag.add_item(txt, Art.item_icon(id, 24))
		_bag.set_item_custom_fg_color(_bag.item_count - 1, ItemDB.rarity_color_of(ItemDB.rarity_of_entry(e)))
		_bag_ids.append(id)

func _on_bag_selected(i: int) -> void:
	if i < 0 or i >= _bag_ids.size():
		return
	var d := ItemDB.get_data(String(_bag_ids[i]))
	_detail.text = "%s\n%s" % [String(d.get("desc", "")), "Statystyki: " + str(d.get("stats", {})) if d.get("stats", {}).size() > 0 else ""]

func _on_bag_activated(i: int) -> void:
	if i < 0 or i >= _bag_ids.size():
		return
	var id := String(_bag_ids[i])
	Audio.play("select")
	if ItemDB.is_gear(id):
		Mmo.send_inv("equip", str(i))
	else:
		Mmo.send_inv("use", str(i))

func _on_bag_clicked(i: int, _pos: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT and i >= 0 and i < _bag_ids.size():
		Mmo.send_inv("drop", str(i))

func _build_skills(info: Dictionary) -> void:
	for c in _skill_box.get_children():
		c.queue_free()
	var known: Array = info.get("known_skills", [])
	var slots: Array = info.get("skills", [])
	_skill_box.add_child(UiKit.label("Sloty umiejętności (klawisze 1–9)", 15, UiKit.ACCENT))
	for i in slots.size():
		var row := UiKit.hbox(8)
		row.add_child(UiKit.label("Slot %d" % (i + 1), 14, UiKit.DIM))
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(300, 32)
		ob.add_item("— pusty —")
		var sel := 0
		for k in known.size():
			var sid := String(known[k])
			ob.add_item(String(SkillDB.get_data(sid).get("name", sid)))
			if sid == String(slots[i]):
				sel = k + 1
		ob.select(sel)
		ob.item_selected.connect(func(idx: int): Mmo.send_inv("skill", str(i), "" if idx == 0 else String(known[idx - 1])))
		row.add_child(ob)
		_skill_box.add_child(row)

func _build_attrs(info: Dictionary) -> void:
	for c in _attr_box.get_children():
		c.queue_free()
	_attr_box.add_child(UiKit.label("Punkty do rozdania: %d" % int(info.get("attr_points", 0)), 16, UiKit.ACCENT))
	var attrs: Dictionary = info.get("attrs", {})
	for k in GameState.ATTR_ORDER:
		var row := UiKit.hbox(8)
		var def: Dictionary = GameState.ATTRS.get(k, {})
		var l := UiKit.label("%s: %d  — %s" % [String(def.get("name", k)), int(attrs.get(k, 0)), String(def.get("desc", ""))], 14, UiKit.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := UiKit.button("+1", 14)
		b.custom_minimum_size = Vector2(56, 30)
		b.disabled = int(info.get("attr_points", 0)) < 1
		b.pressed.connect(func(): Mmo.send_chat_text("/attr %s 1" % k))
		row.add_child(b)
		_attr_box.add_child(row)

func _fill_creative() -> void:
	_creative_list.clear()
	_creative_ids.clear()
	var q := _search.text.strip_edges().to_lower()
	var ids: Array = ItemDB.LIST.keys()
	ids.sort_custom(func(a, b): return int(ItemDB.LIST[a].get("tier", 0)) < int(ItemDB.LIST[b].get("tier", 0)))
	for id in ids:
		var d: Dictionary = ItemDB.LIST[id]
		var nm := String(d.get("name", id))
		if q != "" and not (String(id).to_lower().contains(q) or nm.to_lower().contains(q) or String(d.get("slot", "")).contains(q)):
			continue
		_creative_list.add_item("%s  [%s, T%d]" % [nm, String(d.get("slot", "")), int(d.get("tier", 0))], Art.item_icon(String(id), 24))
		_creative_list.set_item_custom_fg_color(_creative_list.item_count - 1, ItemDB.rarity_color(String(id)))
		_creative_ids.append(String(id))
		if _creative_ids.size() >= 400:
			break
