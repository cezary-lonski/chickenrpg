class_name UiMmoWaves
extends UiMmoPanel
## Edytor własnych fal na serwerze (klawisz B): ile fal, jakie potwory i bossowie, mnożniki życia / ataku / XP, elita, teren.
## Konfiguracja zapisuje się na postaci serwerowej; serwer ją sprawdza i uruchamia prywatną instancję „Własne fale”.

const MAX_WAVES := 30

var cfg: Dictionary = {}
var _enemy_ids: Array = []
var _boss_ids: Array = []
var _list: VBoxContainer

func _init() -> void:
	super._init("WŁASNE FALE")

func _build() -> void:
	cfg = (Mmo.my_info.get("custom_waves", UiWaveEditor.default_config()) as Dictionary).duplicate(true)
	if not (cfg.get("waves") is Array) or (cfg["waves"] as Array).is_empty():
		cfg = UiWaveEditor.default_config()
	for id in EnemyDB.LIST:
		if not bool(EnemyDB.LIST[id].get("boss", false)):
			_enemy_ids.append(String(id))
	_enemy_ids.sort_custom(func(a, b): return int(EnemyDB.LIST[a]["tier"]) < int(EnemyDB.LIST[b]["tier"]))
	for id in BossDB.LIST:
		if not String(id).begins_with("cavebos_"):
			_boss_ids.append(String(id))
	_box.add_child(UiKit.label("Ułóż własną bitwę i rozegraj ją na serwerze (prywatna instancja). Nagrody z walk są ograniczone: XP ×1,5 maks., życie wrogów ×0,5 min.", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var top := UiKit.hbox(10)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(top)
	top.add_child(UiKit.label("Teren:", 16))
	var terr := OptionButton.new()
	var ti := 0
	var k := 0
	for t in UiWaveEditor.TERRAINS:
		terr.add_item(String(UiWaveEditor.TERRAINS[t]), k)
		terr.set_item_metadata(k, t)
		if t == String(cfg.get("terrain", "village")):
			ti = k
		k += 1
	terr.select(ti)
	terr.item_selected.connect(func(i): cfg["terrain"] = String(terr.get_item_metadata(i)))
	top.add_child(terr)
	_list = UiKit.vbox(10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_child(_list)
	var bottom := UiKit.hbox(12)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(bottom)
	var add := UiKit.button("+ Dodaj falę", 18, UiKit.GOOD)
	add.pressed.connect(func():
		if (cfg["waves"] as Array).size() >= MAX_WAVES:
			return
		(cfg["waves"] as Array).append({"name": "Fala %d" % ((cfg["waves"] as Array).size() + 1), "hp": 1.0, "dmg": 1.0, "xp": 1.0, "elite": false, "enemies": [[_enemy_ids[0], 3]]})
		Audio.play("confirm")
		_rebuild())
	bottom.add_child(add)
	var save := UiKit.button("Zapisz", 18)
	save.pressed.connect(func(): Audio.play("confirm"); Mmo.send_act("waves_save", {"cfg": cfg}); _msg.text = "Zapisano na serwerze.")
	bottom.add_child(save)
	var go := UiKit.button("Rozpocznij bitwę", 22, UiKit.GOOD)
	go.custom_minimum_size = Vector2(300, 48)
	go.pressed.connect(func():
		if (cfg["waves"] as Array).is_empty():
			Audio.play("deny")
			return
		Audio.play("confirm")
		Mmo.send_act("waves_start", {"cfg": cfg}))
	bottom.add_child(go)
	_rebuild()

func _spin(value: float, lo: float, hi: float, step: float, cb: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(96, 0)
	s.value_changed.connect(cb)
	return s

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	for wi in (cfg["waves"] as Array).size():
		_list.add_child(_wave_panel(wi))

func _wave_panel(wi: int) -> Control:
	var w: Dictionary = (cfg["waves"] as Array)[wi]
	var p := UiKit.panel(UiKit.BG2, 8)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UiKit.vbox(6)
	p.add_child(v)
	var head := UiKit.hbox(8)
	v.add_child(head)
	head.add_child(UiKit.label("FALA %d" % (wi + 1), 18, UiKit.ACCENT))
	var name_e := LineEdit.new()
	name_e.text = String(w.get("name", ""))
	name_e.max_length = 40
	name_e.custom_minimum_size = Vector2(220, 0)
	name_e.text_changed.connect(func(t): w["name"] = t)
	head.add_child(name_e)
	head.add_child(UiKit.spacer())
	var del := UiKit.button("Usuń falę", 14, UiKit.BAD)
	del.custom_minimum_size = Vector2(0, 32)
	del.pressed.connect(func():
		(cfg["waves"] as Array).remove_at(wi)
		Audio.play("back")
		_rebuild())
	head.add_child(del)
	var stats := UiKit.hbox(8)
	v.add_child(stats)
	stats.add_child(UiKit.label("Życie ×", 14, UiKit.DIM))
	stats.add_child(_spin(float(w["hp"]), 0.5, 200.0, 0.1, func(x): w["hp"] = x))
	stats.add_child(UiKit.label("Atak ×", 14, UiKit.DIM))
	stats.add_child(_spin(float(w["dmg"]), 0.1, 200.0, 0.1, func(x): w["dmg"] = x))
	stats.add_child(UiKit.label("XP ×", 14, UiKit.DIM))
	stats.add_child(_spin(float(w["xp"]), 0.0, 1.5, 0.1, func(x): w["xp"] = x))
	var el := CheckBox.new()
	el.text = "Elita"
	el.button_pressed = bool(w.get("elite", false))
	el.toggled.connect(func(on): w["elite"] = on)
	stats.add_child(el)
	var ens: Array = w["enemies"]
	for ei in ens.size():
		v.add_child(_enemy_row(w, ei))
	var adds := UiKit.hbox(8)
	v.add_child(adds)
	var add := UiKit.button("+ Potwór", 14, UiKit.GOOD)
	add.custom_minimum_size = Vector2(0, 32)
	add.pressed.connect(func():
		ens.append([_enemy_ids[0], 1])
		Audio.play("select")
		_rebuild())
	adds.add_child(add)
	var addb := UiKit.button("+ Boss", 14, Color(0.9, 0.4, 0.95))
	addb.custom_minimum_size = Vector2(0, 32)
	addb.pressed.connect(func():
		ens.append(["BOSS:" + String(_boss_ids[0]), 1])
		Audio.play("select")
		_rebuild())
	adds.add_child(addb)
	return p

func _enemy_row(w: Dictionary, ei: int) -> Control:
	var ens: Array = w["enemies"]
	var entry: Array = ens[ei]
	var h := UiKit.hbox(8)
	var is_boss := String(entry[0]).begins_with("BOSS:")
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(260, 0)
	var ids := _boss_ids if is_boss else _enemy_ids
	var cur := String(entry[0]).substr(5) if is_boss else String(entry[0])
	var sel := 0
	for i in ids.size():
		var id: String = ids[i]
		var nm: String
		if is_boss:
			nm = "BOSS: " + String(BossDB.get_data(id).get("name", id))
		else:
			nm = "%s  (poz. %d)" % [String(EnemyDB.get_data(id).get("name", id)), int(EnemyDB.get_data(id)["tier"])]
		ob.add_item(nm, i)
		if id == cur:
			sel = i
	ob.select(sel)
	ob.item_selected.connect(func(i): entry[0] = ("BOSS:" + String(ids[i])) if is_boss else String(ids[i]))
	h.add_child(ob)
	h.add_child(UiKit.label("Ilość", 14, UiKit.DIM))
	h.add_child(_spin(float(entry[1]), 1.0, 60.0, 1.0, func(x): entry[1] = int(x)))
	var rm := UiKit.button("✕", 14, UiKit.BAD)
	rm.custom_minimum_size = Vector2(36, 32)
	rm.pressed.connect(func():
		ens.remove_at(ei)
		Audio.play("back")
		_rebuild())
	h.add_child(rm)
	return h
