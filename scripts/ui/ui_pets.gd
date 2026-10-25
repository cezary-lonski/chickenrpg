class_name UiPets
extends Control
## Menu towarzyszy: wybór aktywnego peta i jego specjalnego wyposażenia (tylko dla petów).

signal on_close

var _list: VBoxContainer
var _detail: VBoxContainer
var _sel := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.07, 0.08)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_top = 10.0
	root.offset_bottom = -10.0
	add_child(root)
	root.add_child(UiKit.title("TOWARZYSZE", 38))
	var body := UiKit.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := UiKit.panel(UiKit.BG, 10)
	left.custom_minimum_size = Vector2(340, 0)
	body.add_child(left)
	var ls := ScrollContainer.new()
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(ls)
	_list = UiKit.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(_list)
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	_detail = UiKit.vbox(6)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(_detail)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wróć", 20)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	row.add_child(back)
	_sel = String(GameState.pets().get("equipped", ""))
	if _sel == "" and not GameState.pets().get("unlocked", []).is_empty():
		_sel = String(GameState.pets()["unlocked"][0])
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		Audio.play("back")
		on_close.emit()

func _wl(text: String, size: int, col: Color) -> Label:
	var l := UiKit.label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(10, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for c in _detail.get_children():
		c.queue_free()
	var pets := GameState.pets()
	var unlocked: Array = pets.get("unlocked", [])
	_list.add_child(UiKit.label("ODKRYTE (%d / %d)" % [unlocked.size(), PetDB.LIST.size()], 15, UiKit.DIM))
	for id in PetDB.LIST:
		var pid := String(id)
		var d: Dictionary = PetDB.LIST[id]
		var have := pid in unlocked
		var row := UiKit.panel(UiKit.BG3 if pid == _sel else UiKit.BG2, 8)
		var h := UiKit.hbox(8)
		row.add_child(h)
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
		b.pressed.connect(func(): _sel = pid; Audio.play("select"); _refresh())
		h.add_child(b)
		_list.add_child(row)
	if _sel == "" or _sel not in unlocked:
		_detail.add_child(UiKit.label("Nie masz jeszcze towarzysza", 20, UiKit.DIM))
		return
	var d2: Dictionary = PetDB.LIST[_sel]
	var gear := GameState.pet_gear(_sel)
	_detail.add_child(UiKit.label(String(d2["name"]), 26, UiKit.ACCENT))
	_detail.add_child(UiKit.label("Rola: %s" % String(PetDB.ROLE_NAMES.get(d2["role"], "")), 16, UiKit.ACCENT2))
	_detail.add_child(_wl(String(d2["desc"]), 14, UiKit.TEXT))
	var bonus := func(k: String) -> float: return float(ItemDB.stats_of(gear).get(k, 0.0)) if gear != "" else 0.0
	_detail.add_child(_wl("Obrażenia: %.1f   Czas ataku: %.2f s   Zasięg: %d" % [
		float(d2.get("dmg", 0.0)) * (1.0 + bonus.call("pet_dmg")), float(d2.get("cd", 1.0)) / (1.0 + bonus.call("pet_speed")), int(float(d2.get("range", 0.0)) * (1.0 + bonus.call("pet_range")))], 14, UiKit.GOOD))
	var eq_row := UiKit.hbox(8)
	_detail.add_child(eq_row)
	if String(GameState.pets().get("equipped", "")) == _sel:
		eq_row.add_child(UiKit.label("✔ Aktywny towarzysz", 16, UiKit.GOOD))
	else:
		var act := UiKit.button("Wybierz jako aktywnego", 17)
		act.pressed.connect(func(): GameState.equip_pet(_sel); Audio.play("confirm"); _refresh())
		eq_row.add_child(act)
	_detail.add_child(UiKit.sep(6))
	_detail.add_child(UiKit.label("WYPOSAŻENIE PETA (tylko dla petów)", 15, UiKit.DIM))
	if gear != "":
		var gd := ItemDB.get_data(gear)
		var gr := UiKit.hbox(8)
		_detail.add_child(gr)
		gr.add_child(UiKit.icon(Art.item_icon(gear, 40), 40))
		var gv := UiKit.vbox(0)
		gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gr.add_child(gv)
		gv.add_child(UiKit.label(String(gd.get("name", gear)), 16, ItemDB.rarity_color(gear)))
		gv.add_child(_wl(String(gd.get("desc", "")), 12, UiKit.DIM))
		var un := UiKit.button("Zdejmij", 15)
		un.pressed.connect(func():
			if not GameState.unequip_pet_gear(_sel):
				Audio.play("deny")
				GameState.toast.emit("Brak miejsca w ekwipunku.", UiKit.BAD)
			else:
				Audio.play("back")
			_refresh())
		gr.add_child(un)
	else:
		_detail.add_child(UiKit.label("Brak założonego wyposażenia.", 14, UiKit.DIM))
	_detail.add_child(UiKit.label("Dostępne w ekwipunku:", 14, UiKit.DIM))
	var any := false
	for e in GameState.inv():
		if e is Dictionary and String(ItemDB.get_data(String(e["id"])).get("slot", "")) == "pet_gear":
			any = true
			var iid := String(e["id"])
			var ir := UiKit.hbox(8)
			_detail.add_child(ir)
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
			eb.pressed.connect(func():
				GameState.set_pet_gear(_sel, iid)
				Audio.play("confirm")
				_refresh())
			ir.add_child(eb)
	if not any:
		_detail.add_child(UiKit.label("Brak. Znajdziesz je w skrzyniach i sklepie kupca.", 13, UiKit.DIM))
