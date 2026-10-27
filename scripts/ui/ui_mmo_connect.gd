class_name UiMmoConnect
extends Control
## Dołączanie do ChickenSerwera: adres IP + port, wybór zapisu i postaci, nick, hasło.
## Postać jest kopiowana na serwer przy pierwszym wejściu; potem serwer trzyma własną kopię (nick + hasło).

const LAST_FILE := "user://mmo_last.json"
const SERVERS_FILE := "user://mmo_servers.json"
const SLOTS := 3

## Wybór przetrwa przejście do kreatora wyglądu / edytora animacji i powrót.
static var s_server: Dictionary = {}
static var s_slot := 0
static var s_char := ""

var _servers: Array = []
var _host_label: Label
var _add_btn: Button

var _ip: LineEdit
var _port: SpinBox
var _nick: LineEdit
var _pass: LineEdit
var _cls: OptionButton
var _status: Label
var _join_btn: Button
var _slot_row: HBoxContainer
var _char_box: VBoxContainer
var _slot := 0
var _char := ""
var _busy := false
var _class_ids: Array = []
var _new := false
var _login_only := false
var _nicks: Dictionary = {}
var _base: OptionButton
var _base_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	UiKit.menu_scene(self)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(840, 16)
	scroll.size = Vector2(420, 688)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var outer := UiKit.vbox(8)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.custom_minimum_size = Vector2(410, 0)
	scroll.add_child(outer)
	outer.add_child(UiKit.title("SERWER ONLINE", 30))
	# pola adresu żyją poza drzewem: wartości bierzemy z wybranego serwera
	_ip = LineEdit.new()
	_port = SpinBox.new()
	_port.min_value = 1
	_port.max_value = 65535
	_port.value = Mmo.DEFAULT_PORT
	_load_servers()
	if s_server.is_empty():
		_build_server_list(outer)
		return
	_ip.text = String(s_server.get("ip", ""))
	_port.value = float(s_server.get("port", Mmo.DEFAULT_PORT))
	var hdr := UiKit.panel(UiKit.BG, 12)
	hdr.custom_minimum_size = Vector2(400, 0)
	var hr := UiKit.hbox(10)
	hdr.add_child(hr)
	outer.add_child(_center(hdr))
	_host_label = UiKit.label("Serwer: %s  (%s:%d)" % [String(s_server.get("name", "")), _ip.text, int(_port.value)], 17, UiKit.ACCENT)
	_host_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_host_label.custom_minimum_size = Vector2(200, 0)
	hr.add_child(_host_label)
	var change := _wb("Zmień serwer", 15)
	change.pressed.connect(func(): Audio.play("back"); s_server = {}; s_slot = 0; s_char = ""; Flow.goto("mmo_connect"))
	hr.add_child(change)

	outer.add_child(_center(UiKit.label("1. Zapis gry", 18, UiKit.ACCENT)))
	_slot_row = UiKit.hbox(10)
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(_slot_row)
	for i in range(1, SLOTS + 1):
		var info := GameState.slot_info(i)
		var b := _wb("Slot %d" % i if not bool(info.get("exists", false)) else "Slot %d · poz. %d" % [i, int(info.get("level", 1))], 15)
		b.disabled = not bool(info.get("exists", false)) or bool(info.get("broken", false))
		b.pressed.connect(_pick_slot.bind(i))
		_slot_row.add_child(b)

	var nb := _wb("Utwórz nową postać (zapis na serwerze)", 16, UiKit.GOOD)
	nb.pressed.connect(_pick_new)
	outer.add_child(_center(nb))
	var lb := _wb("Wejdź na postać zapisaną na serwerze", 16, UiKit.ACCENT2)
	lb.pressed.connect(_pick_login)
	outer.add_child(_center(lb))
	var look_row := UiKit.hbox(10)
	look_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(look_row)
	var b_look := _wb("Wygląd, kolory i nick…", 16, UiKit.ACCENT2)
	b_look.pressed.connect(_to_look.bind(false))
	look_row.add_child(b_look)
	var b_anim := _wb("Edytor animacji…", 16, UiKit.ACCENT2)
	b_anim.pressed.connect(_to_look.bind(true))
	look_row.add_child(b_anim)
	outer.add_child(_center(UiKit.label("2. Postać", 18, UiKit.ACCENT)))
	_char_box = UiKit.vbox(4)
	outer.add_child(_center(_char_box))
	_char_box.add_child(UiKit.label("Wybierz zapis z postacią albo „Nowa postać”.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_base = OptionButton.new()
	_base.custom_minimum_size = Vector2(260, 38)
	_base.visible = false
	_base.item_selected.connect(func(i: int): _set_base(String(_base_ids[i])))
	outer.add_child(_center(_base))

	var acc := UiKit.panel(UiKit.BG, 12)
	acc.custom_minimum_size = Vector2(400, 0)
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 10)
	gr.add_theme_constant_override("v_separation", 6)
	acc.add_child(gr)
	outer.add_child(_center(acc))
	gr.add_child(UiKit.label("NICK", 16, UiKit.ACCENT))
	_nick = LineEdit.new()
	_nick.max_length = 16
	_nick.custom_minimum_size = Vector2(200, 38)
	_nick.placeholder_text = "nazwa postaci na serwerze"
	gr.add_child(_nick)
	gr.add_child(UiKit.label("HASŁO", 16, UiKit.ACCENT))
	_pass = LineEdit.new()
	_pass.secret = true
	_pass.custom_minimum_size = Vector2(200, 38)
	_pass.placeholder_text = "min. 3 znaki"
	gr.add_child(_pass)
	gr.add_child(UiKit.label("KLASA", 16, UiKit.ACCENT))
	_cls = OptionButton.new()
	_cls.custom_minimum_size = Vector2(200, 38)
	gr.add_child(_cls)
	var hint := UiKit.label("Nowy nick = tworzysz postać na serwerze (kopia Twojej). Istniejący nick = wchodzisz hasłem.", 12, UiKit.DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(190, 0)
	gr.add_child(hint)

	_status = UiKit.label("", 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_status)
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(row)
	var back := _wb("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); Mmo.stop(); Flow.goto("menu"))
	row.add_child(back)
	_join_btn = _wb("Dołącz", 22, UiKit.GOOD)
	_join_btn.disabled = true
	_join_btn.pressed.connect(_on_join)
	row.add_child(_join_btn)

	Mmo.connect_failed.connect(_on_fail)
	Mmo.login_result.connect(_on_login)
	_load_last()
	if s_slot > 0:
		_pick_slot(s_slot)
		if s_char != "":
			_pick_char(s_char)

# ------------------------------------------------------------ lista serwerów ---

func _load_servers() -> void:
	_servers.clear()
	if not FileAccess.file_exists(SERVERS_FILE):
		return
	var f := FileAccess.open(SERVERS_FILE, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text()) if f else null
	if f:
		f.close()
	if v is Array:
		for e in v:
			if e is Dictionary and String(e.get("ip", "")) != "":
				_servers.append({"name": String(e.get("name", e["ip"])).left(32), "ip": String(e["ip"]).left(128), "port": clampi(int(e.get("port", Mmo.DEFAULT_PORT)), 1, 65535)})

func _save_servers() -> void:
	var f := FileAccess.open(SERVERS_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_servers))
		f.close()

func _build_server_list(outer: VBoxContainer) -> void:
	outer.add_child(UiKit.label("Wybierz zapisany serwer albo dodaj nowy (+).", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var p := UiKit.panel(UiKit.BG, 12)
	p.custom_minimum_size = Vector2(400, 0)
	outer.add_child(_center(p))
	var v := UiKit.vbox(8)
	p.add_child(v)
	if _servers.is_empty():
		v.add_child(UiKit.label("Brak zapisanych serwerów. Kliknij +, żeby dodać pierwszy.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	for i in _servers.size():
		var s: Dictionary = _servers[i]
		var row := UiKit.panel(UiKit.BG2, 8)
		v.add_child(row)
		var h := UiKit.hbox(10)
		row.add_child(h)
		var col := UiKit.vbox(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(col)
		col.add_child(UiKit.label(String(s["name"]), 18, UiKit.TEXT))
		col.add_child(UiKit.label("%s:%d" % [String(s["ip"]), int(s["port"])], 13, UiKit.DIM))
		var join := _wb("Dołącz", 18, UiKit.GOOD)
		join.pressed.connect(func():
			Audio.play("confirm")
			s_server = (_servers[i] as Dictionary).duplicate()
			s_slot = 0
			s_char = ""
			Flow.goto("mmo_connect"))
		h.add_child(join)
		var del := _wb("✕", 16, UiKit.BAD)
		del.pressed.connect(func():
			Audio.play("back")
			_servers.remove_at(i)
			_save_servers()
			Flow.goto("mmo_connect"))
		h.add_child(del)
	var add := _wb("+  Dodaj serwer", 20, UiKit.ACCENT)
	_add_btn = add
	add.pressed.connect(func(): Audio.play("select"); _show_add_form(outer, add))
	outer.add_child(_center(add))
	var back := _wb("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); Mmo.stop(); Flow.goto("menu"))
	outer.add_child(_center(back))

func _show_add_form(outer: VBoxContainer, add_btn: Button) -> void:
	add_btn.visible = false
	var p := UiKit.panel(UiKit.BG, 12)
	p.custom_minimum_size = Vector2(400, 0)
	outer.add_child(_center(p))
	outer.move_child(p.get_parent(), add_btn.get_parent().get_index())
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	p.add_child(g)
	g.add_child(UiKit.label("NAZWA", 16, UiKit.ACCENT))
	var name_e := LineEdit.new()
	name_e.placeholder_text = "np. Serwer kolegi"
	name_e.max_length = 32
	name_e.custom_minimum_size = Vector2(200, 38)
	g.add_child(name_e)
	g.add_child(UiKit.label("PORT", 16, UiKit.ACCENT))
	var port_e := SpinBox.new()
	port_e.min_value = 1
	port_e.max_value = 65535
	port_e.value = Mmo.DEFAULT_PORT
	g.add_child(port_e)
	g.add_child(UiKit.label("IP", 16, UiKit.ACCENT))
	var ip_e := LineEdit.new()
	ip_e.placeholder_text = "np. 83.12.45.7 lub moj.serwer.pl"
	ip_e.custom_minimum_size = Vector2(200, 38)
	g.add_child(ip_e)
	var save := _wb("Zapisz", 18, UiKit.GOOD)
	g.add_child(save)
	var msg := UiKit.label("", 14, UiKit.BAD)
	g.add_child(msg)
	save.pressed.connect(func():
		var ip := ip_e.text.strip_edges()
		if ip == "":
			msg.text = "Wpisz adres IP."
			Audio.play("deny")
			return
		var nm := name_e.text.strip_edges()
		_servers.append({"name": nm if nm != "" else ip, "ip": ip, "port": int(port_e.value)})
		_save_servers()
		Audio.play("confirm")
		Flow.goto("mmo_connect"))
	ip_e.grab_focus()

## Do kreatora wyglądu (kolory, ubrania, nick) albo edytora animacji; po powrocie wybór zostaje.
func _to_look(anim: bool) -> void:
	if _slot <= 0 or _char == "":
		_status.text = "Najpierw wybierz zapis i postać."
		_status.add_theme_color_override("font_color", UiKit.BAD)
		Audio.play("deny")
		return
	s_slot = _slot
	s_char = _char
	Audio.play("confirm")
	if anim:
		Flow.goto("paint", {"back": "mmo_connect", "then": "mmo_connect"})
	else:
		Flow.goto("creator", {"then": "mmo_connect"})

func _center(c: Control) -> Control:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(c)
	return h

func _exit_tree() -> void:
	if Mmo.connect_failed.is_connected(_on_fail):
		Mmo.connect_failed.disconnect(_on_fail)
	if Mmo.login_result.is_connected(_on_login):
		Mmo.login_result.disconnect(_on_login)

func _load_last() -> void:
	if not FileAccess.file_exists(LAST_FILE):
		return
	var f := FileAccess.open(LAST_FILE, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text()) if f else null
	if f:
		f.close()
	if typeof(v) == TYPE_DICTIONARY:
		_nicks = v.get("nicks", {}) if v.get("nicks") is Dictionary else {}

func _save_last() -> void:
	var f := FileAccess.open(LAST_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"ip": _ip.text.strip_edges(), "port": int(_port.value), "nicks": _nicks}))
		f.close()

func _pick_slot(slot: int) -> void:
	Audio.play("select")
	_login_only = false
	_slot = slot
	_new = false
	_base.visible = false
	_char = ""
	_join_btn.disabled = true
	GameState.set_slot(slot)
	s_slot = slot
	for c in _char_box.get_children():
		c.queue_free()
	var chars: Dictionary = GameState.profile.get("characters", {})
	var ids: Array = []
	for id in CharacterDB.ordered_ids():
		if chars.has(id) and (int((chars[id] as Dictionary).get("level", 1)) > 1 or bool((chars[id] as Dictionary).get("unlocked", false))):
			ids.append(id)
	for id in chars:
		if id not in ids and CharacterDB.LIST.has(id):
			ids.append(id)
	if ids.is_empty():
		_char_box.add_child(UiKit.label("Ten zapis nie ma postaci.", 15, UiKit.BAD, HORIZONTAL_ALIGNMENT_CENTER))
		return
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(400, 0)
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	_char_box.add_child(row)
	for id in ids:
		var cp: Dictionary = chars[id]
		var b := _wb("%s — poz. %d" % [String(CharacterDB.get_data(id).get("title", id)), int(cp.get("level", 1))], 16)
		b.pressed.connect(_pick_char.bind(id))
		row.add_child(b)
	if ids.size() == 1:
		_pick_char(ids[0])

func _pick_char(id: String) -> void:
	Audio.play("select")
	_char = id
	s_char = id
	_join_btn.disabled = false
	var cp := GameState.char_profile(id)
	_class_ids = ClassDatabase.for_server(id)
	_cls.clear()
	var want := String(cp.get("class", ""))
	var sel := 0
	for i in _class_ids.size():
		_cls.add_item(String(ClassDatabase.get_data(_class_ids[i]).get("title", _class_ids[i])))
		if _class_ids[i] == want:
			sel = i
	_cls.select(sel)
	_nick.text = String(_nicks.get(_nick_key(), GameState.nick()))
	_status.text = "Wybrano: %s, poziom %d." % [String(CharacterDB.get_data(id).get("title", id)), int(cp.get("level", 1))]

## Klucz zapamiętanego nicku: zapis+postać albo „nowa postać”. Nick wpisujesz raz, hasło przy każdym wejściu.
func _nick_key() -> String:
	if _login_only:
		return "login"
	return "new:%s" % _char if _new else "s%d:%s" % [_slot, _char]

func _pick_login() -> void:
	Audio.play("select")
	_login_only = true
	_new = false
	_slot = 0
	_char = ""
	_base.visible = false
	for c in _char_box.get_children():
		c.queue_free()
	_char_box.add_child(UiKit.label("Wpisz nick i hasło postaci, którą masz już zapisaną na tym serwerze.", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_class_ids = []
	_cls.clear()
	_nick.text = String(_nicks.get("login", ""))
	_join_btn.disabled = false
	_status.text = "Postać zostanie wczytana z zapisu na serwerze."

func _pick_new() -> void:
	Audio.play("select")
	_login_only = false
	_new = true
	_slot = 0
	for c in _char_box.get_children():
		c.queue_free()
	_char_box.add_child(UiKit.label("Nowa postać startuje od poziomu 1 — wybierz bohatera i klasę.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_base.clear()
	_base_ids.clear()
	for id in CharacterDB.ordered_ids():
		if String(CharacterDB.get_data(id).get("unlock", "")) == "":
			_base_ids.append(id)
			_base.add_item(String(CharacterDB.get_data(id).get("title", id)))
	_base.visible = true
	_base.select(0)
	_set_base(String(_base_ids[0]))

func _set_base(id: String) -> void:
	_char = id
	_join_btn.disabled = false
	_class_ids = ClassDatabase.for_server(id)
	_cls.clear()
	for cid in _class_ids:
		_cls.add_item(String(ClassDatabase.get_data(cid).get("title", cid)))
	_cls.select(0)
	_nick.text = String(_nicks.get(_nick_key(), ""))
	_status.text = "Nowa postać: %s." % String(CharacterDB.get_data(id).get("title", id))

func _build_pack() -> Dictionary:
	if _login_only:
		return {}
	if _new:
		var inv0: Array = []
		var sb := ItemDB.starter_backpack()
		for iid in sb:
			inv0.append({"id": String(iid), "n": int(sb[iid])})
		return {"char": _char, "class": String(_class_ids[_cls.selected]) if _cls.selected >= 0 and _cls.selected < _class_ids.size() else "wojownik",
			"level": 1, "xp": 0, "gold": 0, "inv": inv0, "equip": ItemDB.defaults(), "skills": [], "attrs": {}, "attr_points": 0, "appearance": {}, "look": ""}
	var cp := GameState.char_profile(_char)
	var inv: Array = []
	for e in cp.get("inv", []):
		if e is Dictionary and String(e.get("id", "")) != "":
			var ent := {"id": String(e["id"]), "n": int(e.get("n", 1)), "q": float(e.get("q", 1.0))}
			if e.get("m") is Dictionary:
				ent["m"] = (e["m"] as Dictionary).duplicate(true)
			inv.append(ent)
	return {
		"char": _char, "class": String(_class_ids[_cls.selected]) if _cls.selected >= 0 and _cls.selected < _class_ids.size() else "wojownik",
		"level": int(cp.get("level", 1)), "xp": int(cp.get("xp", 0)), "gold": GameState.gold(),
		"attr_points": int(cp.get("attr_points", 0)), "attrs": cp.get("attrs", {}).duplicate(true),
		"equip": cp.get("equip", {}).duplicate(true), "equip_q": cp.get("equip_q", {}).duplicate(), "equip_m": cp.get("equip_m", {}).duplicate(true), "inv": inv, "skills": cp.get("skills", []).duplicate(),
		"appearance": GameState.appearance(), "look": GameState.look_id(),
		"story": {"chapter": GameState.story_chapter(), "quest": GameState.story_quest(), "done": GameState.story().get("done", []).duplicate(), "flags": GameState.story().get("flags", {}).duplicate()},
		"act2": (GameState.profile.get("act2", {}) as Dictionary).duplicate(true) if GameState.profile.get("act2") is Dictionary else {},
	}

func _on_join() -> void:
	if _busy or (_char == "" and not _login_only):
		return
	var nick := _nick.text.strip_edges()
	if not ServerChars.valid_name(nick):
		_status.text = "Nick: 2–16 znaków (litery, cyfry, spacja, _ lub -)."
		_status.add_theme_color_override("font_color", UiKit.BAD)
		return
	if _pass.text.length() < 3:
		_status.text = "Hasło musi mieć co najmniej 3 znaki."
		_status.add_theme_color_override("font_color", UiKit.BAD)
		return
	if _ip.text.strip_edges() == "":
		_status.text = "Wpisz adres IP serwera."
		_status.add_theme_color_override("font_color", UiKit.BAD)
		return
	_busy = true
	_join_btn.disabled = true
	_status.add_theme_color_override("font_color", UiKit.ACCENT)
	_status.text = "Łączę z %s:%d…" % [_ip.text.strip_edges(), int(_port.value)]
	Mmo.connect_to(_ip.text, int(_port.value), nick, _pass.text, _build_pack())

func _on_fail(reason: String) -> void:
	_busy = false
	_join_btn.disabled = _char == "" and not _login_only
	_status.add_theme_color_override("font_color", UiKit.BAD)
	_status.text = reason
	Audio.play("deny")

func _on_login(ok: bool, msg: String, _info: Dictionary) -> void:
	if ok:
		_nicks[_nick_key()] = _nick.text.strip_edges()
		_save_last()
		Audio.play("confirm")
		s_slot = 0
		s_char = ""
		Flow.goto("mmo")
		return
	_busy = false
	_join_btn.disabled = _char == "" and not _login_only
	_status.add_theme_color_override("font_color", UiKit.BAD)
	_status.text = msg
	Audio.play("deny")
	Mmo.stop()

## Drewniane przyciski jak w menu głównym gry.
func _wb(text: String, size: int = 22, accent: Color = UiKit.ACCENT) -> Button:
	var b := UiKit.button(text, size, accent)
	var base := Color(0.35, 0.24, 0.13)
	if accent == UiKit.GOOD:
		base = Color(0.72, 0.38, 0.16)
	b.add_theme_color_override("font_color", Color(0.97, 0.93, 0.84))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.45))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.86, 0.45))
	b.add_theme_stylebox_override("normal", _wood_sb(base, Color(0.17, 0.11, 0.06)))
	b.add_theme_stylebox_override("hover", _wood_sb(base.lightened(0.14), Color(0.95, 0.75, 0.3)))
	b.add_theme_stylebox_override("pressed", _wood_sb(base.darkened(0.15), Color(0.17, 0.11, 0.06)))
	b.add_theme_stylebox_override("focus", _wood_sb(base.lightened(0.08), Color(0.95, 0.75, 0.3)))
	b.add_theme_stylebox_override("disabled", _wood_sb(Color(0.25, 0.19, 0.13, 0.55), Color(0.17, 0.11, 0.06, 0.6)))
	return b

func _wood_sb(bgc: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bgc
	s.border_color = border
	s.set_border_width_all(3)
	s.border_width_top = 4
	s.set_corner_radius_all(3)
	s.anti_aliasing = false
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left = 10
	s.content_margin_right = 10
	return s
