class_name UiMmoPets
extends UiMmoPanel
## Menu towarzyszy na serwerze (klawisz P): wybór aktywnego peta i jego wyposażenia. Zmiany wykonuje serwer.

var _sel := ""

func _init() -> void:
	super._init("TOWARZYSZE")

func apply_state(_data: Dictionary) -> void:
	if _box != null:
		_rebuild()

func _build() -> void:
	var pets: Dictionary = Mmo.my_info.get("pets", {})
	_sel = String(pets.get("equipped", ""))
	Mmo.me_received.connect(func(_i): _rebuild())
	_rebuild()

func _rebuild() -> void:
	_clear()
	var pets: Dictionary = Mmo.my_info.get("pets", {})
	var unlocked: Array = pets.get("unlocked", [])
	var gear_map: Dictionary = pets.get("gear", {})
	if _sel == "" or _sel not in unlocked:
		_sel = String(pets.get("equipped", "")) if String(pets.get("equipped", "")) in unlocked else (String(unlocked[0]) if not unlocked.is_empty() else "")
	var row := UiKit.hbox(16)
	_box.add_child(row)
	var list := UiKit.vbox(6)
	list.custom_minimum_size = Vector2(340, 0)
	row.add_child(list)
	list.add_child(UiKit.label("ODKRYTE (%d / %d)" % [unlocked.size(), PetDB.LIST.size()], 15, UiKit.DIM))
	for id in PetDB.LIST:
		var pid := String(id)
		var d: Dictionary = PetDB.LIST[id]
		var have := pid in unlocked
		var p := UiKit.panel(UiKit.BG3 if pid == _sel else UiKit.BG2, 8)
		var h := UiKit.hbox(8)
		p.add_child(h)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(54, 54)
		h.add_child(holder)
		var cv := CreatureVisual.new()
		cv.configure(String(d["species"]), d["pal"], float(d["scale"]) * 1.5)
		cv.position = Vector2(27, 50)
		cv.modulate = Color.WHITE if have else Color(0.1, 0.1, 0.12)
		holder.add_child(cv)
		var v := UiKit.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UiKit.label(String(d["name"]) if have else "???", 16, UiKit.ACCENT if String(pets.get("equipped", "")) == pid else UiKit.TEXT))
		v.add_child(UiKit.label(String(PetDB.ROLE_NAMES.get(d["role"], "")) if have else "Zdobądź w sekretnej jaskini", 12, UiKit.DIM))
		var b := UiKit.button("Podgląd", 13)
		b.disabled = not have
		b.pressed.connect(func(): _sel = pid; Audio.play("select"); _rebuild())
		h.add_child(b)
		list.add_child(p)
	var detail := UiKit.vbox(6)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	if _sel == "":
		detail.add_child(UiKit.label("Nie masz jeszcze towarzysza", 20, UiKit.DIM))
		return
	var d2: Dictionary = PetDB.LIST[_sel]
	var gear := String(gear_map.get(_sel, ""))
	detail.add_child(UiKit.label(String(d2["name"]), 26, UiKit.ACCENT))
	detail.add_child(UiKit.label("Rola: %s" % String(PetDB.ROLE_NAMES.get(d2["role"], "")), 16, UiKit.ACCENT2))
	detail.add_child(_wl(String(d2["desc"]), 14, UiKit.TEXT))
	var bonus := func(k: String) -> float: return float(ItemDB.stats_of(gear).get(k, 0.0)) if gear != "" else 0.0
	detail.add_child(_wl("Obrażenia: %.1f   Czas ataku: %.2f s   Zasięg: %d" % [
		float(d2.get("dmg", 0.0)) * (1.0 + bonus.call("pet_dmg")), float(d2.get("cd", 1.0)) / (1.0 + bonus.call("pet_speed")), int(float(d2.get("range", 0.0)) * (1.0 + bonus.call("pet_range")))], 14, UiKit.GOOD))
	if String(pets.get("equipped", "")) == _sel:
		detail.add_child(UiKit.label("✔ Aktywny towarzysz", 16, UiKit.GOOD))
	else:
		var act := UiKit.button("Wybierz jako aktywnego", 17)
		act.pressed.connect(func(): Audio.play("confirm"); Mmo.send_act("pet_equip", {"pet": _sel}))
		detail.add_child(act)
	detail.add_child(UiKit.sep(6))
	detail.add_child(UiKit.label("WYPOSAŻENIE PETA (tylko dla petów)", 15, UiKit.DIM))
	if gear != "":
		var gd := ItemDB.get_data(gear)
		var gr := UiKit.hbox(8)
		detail.add_child(gr)
		gr.add_child(UiKit.icon(Art.item_icon(gear, 40), 40))
		var gv := UiKit.vbox(0)
		gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gr.add_child(gv)
		gv.add_child(UiKit.label(String(gd.get("name", gear)), 16, ItemDB.rarity_color(gear)))
		gv.add_child(_wl(String(gd.get("desc", "")), 12, UiKit.DIM))
		var un := UiKit.button("Zdejmij", 15)
		un.pressed.connect(func(): Audio.play("back"); Mmo.send_act("pet_ungear", {"pet": _sel}))
		gr.add_child(un)
	else:
		detail.add_child(UiKit.label("Brak założonego wyposażenia.", 14, UiKit.DIM))
	detail.add_child(UiKit.label("Dostępne w plecaku:", 14, UiKit.DIM))
	var any := false
	for e in Mmo.my_info.get("inv", []):
		if String(ItemDB.get_data(String(e["id"])).get("slot", "")) == "pet_gear":
			any = true
			var iid := String(e["id"])
			var ir := UiKit.hbox(8)
			detail.add_child(ir)
			ir.add_child(UiKit.icon(Art.item_icon(iid, 32), 32))
			var iv := UiKit.vbox(0)
			iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ir.add_child(iv)
			iv.add_child(UiKit.label(String(ItemDB.get_data(iid).get("name", iid)), 15, ItemDB.rarity_color(iid)))
			var parts: Array = []
			var st := ItemDB.stats_of(iid)
			for k in st:
				parts.append("%s %+.0f%%" % [String(UiLoadout.STAT_NAMES.get(k, k)), float(st[k]) * 100.0])
			iv.add_child(_wl(", ".join(parts), 12, UiKit.GOOD))
			var eb := UiKit.button("Załóż", 14)
			eb.pressed.connect(func(): Audio.play("confirm"); Mmo.send_act("pet_gear", {"pet": _sel, "item": iid}))
			ir.add_child(eb)
	if not any:
		detail.add_child(UiKit.label("Brak. Znajdziesz je w skrzyniach i sklepie kupca.", 13, UiKit.DIM))
