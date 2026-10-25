class_name UiWaveEditor
extends Control
## Własne fale: ile fal, jakie potwory i w jakiej liczbie, mnożniki życia / ataku / XP każdej fali,
## elita, bossowie, teren. Konfiguracja zapisuje się w profilu.

signal on_start(config: Dictionary, hero: String)
signal on_close

const TERRAINS := {
	"village": "Wioska", "road": "Trakt", "city": "Miasto", "tower": "Wieża", "forest": "Las",
	"fortress": "Twierdza", "ash": "Popielisko", "desert": "Pustynia", "storm": "Burza",
}

var cfg: Dictionary = {}
var _hero := "lord"
var _list: VBoxContainer
var _enemy_ids: Array = []
var _boss_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.06, 0.07, 0.11)))
	cfg = _load()
	for id in EnemyDB.LIST:
		if not bool(EnemyDB.LIST[id].get("boss", false)):
			_enemy_ids.append(String(id))
	_enemy_ids.sort_custom(func(a, b): return int(EnemyDB.LIST[a]["tier"]) < int(EnemyDB.LIST[b]["tier"]))
	for id in BossDB.LIST:
		_boss_ids.append(String(id))
	var outer := UiKit.vbox(6)
	UiKit.full_margin(outer, 24.0)
	add_child(outer)
	outer.add_child(UiKit.title("WŁASNE FALE", 40))
	outer.add_child(UiKit.label("Zapis: slot %d" % GameState.active_slot, 14, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER))
	outer.add_child(UiKit.label("Ułóż własną bitwę: fale, potwory, siła ataku, życie i nagrody. Wszystko możesz zmienić.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var top := UiKit.hbox(10)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(top)
	top.add_child(UiKit.label("Teren:", 16))
	var terr := OptionButton.new()
	var ti := 0
	var k := 0
	for t in TERRAINS:
		terr.add_item(String(TERRAINS[t]), k)
		terr.set_item_metadata(k, t)
		if t == String(cfg["terrain"]):
			ti = k
		k += 1
	terr.select(ti)
	terr.item_selected.connect(func(i): cfg["terrain"] = String(terr.get_item_metadata(i)))
	top.add_child(terr)
	top.add_child(UiKit.label("Bohater:", 16))
	for h in ["lord", "lady"]:
		var b := UiKit.button("Lord" if h == "lord" else "Lady", 16)
		var hid: String = h
		b.pressed.connect(func(): _hero = hid; Audio.play("select"); _refresh_hero())
		top.add_child(b)
		_hero_btns[h] = b
	_refresh_hero()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_list = UiKit.vbox(10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var bottom := UiKit.hbox(12)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(bottom)
	var add := UiKit.button("+ Dodaj falę", 18, UiKit.GOOD)
	add.pressed.connect(func():
		(cfg["waves"] as Array).append(_new_wave(cfg["waves"].size() + 1))
		Audio.play("confirm")
		_rebuild())
	bottom.add_child(add)
	var back := UiKit.button("Wstecz", 18)
	back.pressed.connect(func(): _save(); Audio.play("back"); on_close.emit())
	bottom.add_child(back)
	var go := UiKit.button("Rozpocznij bitwę", 22)
	go.custom_minimum_size = Vector2(300, 48)
	go.pressed.connect(func():
		if (cfg["waves"] as Array).is_empty():
			Audio.play("deny")
			return
		_save()
		Audio.play("confirm")
		on_start.emit(cfg.duplicate(true), _hero))
	bottom.add_child(go)
	_rebuild()

var _hero_btns := {}

func _refresh_hero() -> void:
	for h in _hero_btns:
		(_hero_btns[h] as Button).add_theme_color_override("font_color", UiKit.ACCENT if h == _hero else UiKit.TEXT)

static func default_config() -> Dictionary:
	return {
		"terrain": "village", "gold": 1.0,
		"waves": [
			{"name": "Zwiad", "hp": 1.0, "dmg": 1.0, "xp": 1.0, "elite": false, "enemies": [["wrzos", 4]]},
			{"name": "Szturm", "hp": 1.2, "dmg": 1.1, "xp": 1.2, "elite": false, "enemies": [["wrzos", 4], ["sroka", 3]]},
			{"name": "Przełamanie", "hp": 1.5, "dmg": 1.3, "xp": 1.5, "elite": true, "enemies": [["wronszek", 4], ["sroka", 3]]},
		],
	}

func _new_wave(n: int) -> Dictionary:
	return {"name": "Fala %d" % n, "hp": 1.0, "dmg": 1.0, "xp": 1.0, "elite": false, "enemies": [[_enemy_ids[0], 3]]}

func _load() -> Dictionary:
	var c = GameState.profile.get("custom_waves")
	if c is Dictionary and (c.get("waves") is Array) and not (c["waves"] as Array).is_empty():
		var out := (c as Dictionary).duplicate(true)
		if not TERRAINS.has(String(out.get("terrain", ""))):
			out["terrain"] = "village"
		out["gold"] = float(out.get("gold", 1.0))
		return out
	return default_config()

func _save() -> void:
	GameState.profile["custom_waves"] = cfg.duplicate(true)
	GameState.save_game()

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
	var waves: Array = cfg["waves"]
	for wi in waves.size():
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
	stats.add_child(_spin(float(w["hp"]), 0.1, 200.0, 0.1, func(x): w["hp"] = x))
	stats.add_child(UiKit.label("Atak ×", 14, UiKit.DIM))
	stats.add_child(_spin(float(w["dmg"]), 0.1, 200.0, 0.1, func(x): w["dmg"] = x))
	stats.add_child(UiKit.label("XP ×", 14, UiKit.DIM))
	stats.add_child(_spin(float(w["xp"]), 0.0, 500.0, 0.1, func(x): w["xp"] = x))
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_save()
		on_close.emit()
