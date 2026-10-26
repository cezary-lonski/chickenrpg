class_name UiLanLobby
extends Control
## Lobby LAN/online: Host tworzy pokój (dostaje KOD) albo gracz dołącza
## wpisując kod (LAN) lub IP hosta + kod (online).
## Wybierasz klasę, potem gra się wspólnie w kampanię.

signal on_close
signal on_start(p1: String, p2: String, cls: String)

const CHARS := ["lord", "lady"]

var online := false
var arena := false
var _mode := "host"        # host | join
var _char := "lord"
var _cls := "wojownik"
var _code := ""
var _remote_char := ""
var _remote_class := ""
var _host_started := false

var _code_field: LineEdit
var _code_label: Label
var _addr_panel: PanelContainer
var _addr_field: LineEdit
var _addr_label: Label
var _status: Label
var _slot := 0
var _slot_row: HBoxContainer
var _slot_label: Label
var _char_row: HBoxContainer
var _class_row: HBoxContainer
var _class_desc: Label
var _online_panel: PanelContainer
var _online_addr: Label
var _online_hint: Label
var _copy_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.07, 0.11)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.55)))
	var outer := UiKit.vbox(10)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(outer)
	add_child(outer)

	outer.add_child(UiKit.title("ARENA GRACZY" if arena else ("GRA ONLINE" if online else "GRA LAN"), 42))
	if online:
		outer.add_child(UiKit.label("Host udostępnia IP i KOD. Drugi gracz wpisuje IP hosta oraz kod.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		outer.add_child(UiKit.label("Host tworzy pokój i podaje KOD. Dołącz przez kod lub bezpośrednio przez IP.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	if arena:
		outer.add_child(UiKit.label("Pojedynek dwóch graczy — walczycie swoimi zapisanymi postaciami. Wygrywa ten, kto zostanie na nogach.", 15, UiKit.BAD, HORIZONTAL_ALIGNMENT_CENTER))
		var net_row := UiKit.hbox(10)
		net_row.alignment = BoxContainer.ALIGNMENT_CENTER
		outer.add_child(net_row)
		var b_lan := UiKit.button("LAN", 18)
		b_lan.pressed.connect(func(): online = false; Audio.play("select"); _refresh())
		net_row.add_child(b_lan)
		var b_online := UiKit.button("Online", 18)
		b_online.pressed.connect(func(): online = true; Audio.play("select"); _refresh())
		net_row.add_child(b_online)
	var modes := UiKit.hbox(10)
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(modes)
	var bh := UiKit.button("Hostuj", 20)
	bh.pressed.connect(func(): _mode = "host"; _refresh())
	modes.add_child(bh)
	var bj := UiKit.button("Dołącz", 20)
	bj.pressed.connect(func(): _mode = "join"; _refresh())
	modes.add_child(bj)

	outer.add_child(UiKit.sep(4))

	# --- kod
	var code_panel := UiKit.panel(UiKit.BG, 12)
	code_panel.custom_minimum_size = Vector2(560, 0)
	var cc := UiKit.hbox(10)
	code_panel.add_child(cc)
	outer.add_child(code_panel)
	_code_label = UiKit.label("KOD POKOJU", 16, UiKit.ACCENT)
	cc.add_child(_code_label)
	_code_field = LineEdit.new()
	_code_field.placeholder_text = "np. 7K2M"
	_code_field.max_length = 8
	_code_field.custom_minimum_size = Vector2(200, 44)
	_code_field.add_theme_font_size_override("font_size", 26)
	_code_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cc.add_child(_code_field)
	var gen := UiKit.button("Generuj", 18)
	gen.pressed.connect(func(): _on_generate())
	cc.add_child(gen)

	_addr_panel = UiKit.panel(UiKit.BG, 12)
	_addr_panel.custom_minimum_size = Vector2(560, 0)
	var ac := UiKit.hbox(10)
	_addr_panel.add_child(ac)
	outer.add_child(_addr_panel)
	_addr_label = UiKit.label("IP HOSTA", 16, UiKit.DIM)
	ac.add_child(_addr_label)
	_addr_field = LineEdit.new()
	_addr_field.placeholder_text = "opcjonalnie, np. 192.168.1.10"
	_addr_field.custom_minimum_size = Vector2(360, 40)
	ac.add_child(_addr_field)

	_online_panel = UiKit.panel(UiKit.BG2, 12)
	_online_panel.custom_minimum_size = Vector2(620, 0)
	_online_panel.visible = false
	var oc := UiKit.vbox(4)
	_online_panel.add_child(oc)
	outer.add_child(_online_panel)
	var orow := UiKit.hbox(10)
	oc.add_child(orow)
	_online_addr = UiKit.label("", 18, UiKit.ACCENT2)
	_online_addr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orow.add_child(_online_addr)
	_copy_btn = UiKit.button("Kopiuj", 16)
	_copy_btn.pressed.connect(_copy_online_address)
	orow.add_child(_copy_btn)
	_online_hint = UiKit.label("", 13, UiKit.DIM)
	_online_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_online_hint.custom_minimum_size = Vector2(590, 0)
	oc.add_child(_online_hint)

	# --- zapisana postać
	_slot_label = UiKit.label("Zapisana postać (zapis gry)", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_slot_label)
	_slot_row = UiKit.hbox(10)
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(_slot_row)
	_slot = GameState.last_slot()
	if _slot < 1 or not GameState.slot_exists(_slot):
		_slot = 0
		for i in range(1, GameState.SLOT_COUNT + 1):
			if GameState.slot_exists(i):
				_slot = i
				break
	if _slot > 0:
		GameState.set_slot(_slot)
	else:
		GameState.select_slot(1, true)
		_slot = 1

	# --- postać
	_char_row = UiKit.hbox(10)
	_char_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(_char_row)

	# --- klasa
	outer.add_child(UiKit.label("Klasa", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_class_row = UiKit.hbox(10)
	_class_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(_class_row)
	_class_desc = UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_class_desc)

	_status = UiKit.label("", 16, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_status)

	outer.add_child(UiKit.sep(6))
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(row)
	var back := UiKit.button("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); _leave(); on_close.emit())
	row.add_child(back)
	var go := UiKit.button("Start", 24)
	go.custom_minimum_size = Vector2(260, 50)
	go.pressed.connect(_on_go)
	row.add_child(go)

	Net.hosting_ready.connect(_on_hosting_ready)
	Net.joined_ok.connect(_on_joined_ok)
	Net.join_failed.connect(_on_join_failed)
	Net.peer_joined.connect(_on_peer_joined)
	Net.client_info_received.connect(_on_client_info_received)
	Net.online_info_ready.connect(_on_online_info_ready)

	_pick_saved_class()
	_refresh()

func _leave() -> void:
	Net.reset()

func _on_generate() -> void:
	_code = Net.make_code()
	_code_field.text = _code

func _refresh() -> void:
	_char_row.visible = true
	_addr_panel.visible = _mode == "join"
	_addr_label.text = "PUBLICZNE IP HOSTA" if online else "IP HOSTA"
	_addr_field.placeholder_text = "np. 83.12.34.56" if online else "opcjonalnie, np. 192.168.1.10"
	if _mode == "host":
		_code_label.text = "KOD POKOJU (podaj drugiemu graczowi)"
		_code_field.editable = true
	else:
		_code_label.text = "WPISZ KOD OD HOSTA"
		_code_field.editable = true
	_refresh_online_info()
	# zapisana postać: wybór zapisu, z którego grasz (ekwipunek, poziom, umiejętności)
	for c in _slot_row.get_children():
		c.queue_free()
	var any := false
	for i in range(1, GameState.SLOT_COUNT + 1):
		if not GameState.slot_exists(i):
			continue
		any = true
		var inf := GameState.slot_info(i)
		var sb := UiKit.button("Zapis %d · poz. %d · rozdz. %d" % [i, int(inf.get("level", 1)), int(inf.get("chapter", 1))], 16)
		sb.custom_minimum_size = Vector2(240, 40)
		var sid: int = i
		sb.pressed.connect(func():
			_slot = sid
			GameState.set_slot(sid)
			Audio.play("select")
			_pick_saved_class()
			_refresh())
		if i == _slot:
			sb.add_theme_color_override("font_color", UiKit.ACCENT)
		_slot_row.add_child(sb)
	if not any:
		_slot_row.add_child(UiKit.label("Brak zapisów — zagrasz nową postacią.", 15, UiKit.DIM))
	# postać
	for c in _char_row.get_children():
		c.queue_free()
	for id in CHARS:
		var b := UiKit.button(String(CharacterDB.get_data(id).get("title", id)), 20)
		var cid: String = id
		b.pressed.connect(func(): _char = cid; _pick_saved_class(); _refresh())
		if String(id) == _char:
			b.add_theme_color_override("font_color", UiKit.ACCENT)
		_char_row.add_child(b)
	# klasa
	for c in _class_row.get_children():
		c.queue_free()
	var avail := ClassDatabase.for_character(_char)
	var saved_cls := String(GameState.char_profile(_char).get("class", ""))
	if saved_cls != "" and avail.has(saved_cls):
		_cls = saved_cls
	else:
		saved_cls = ""
	if not avail.has(_cls):
		_cls = String(avail[0]) if avail.size() > 0 else ""
	for id in avail:
		var d := ClassDatabase.get_data(id)
		var b := UiKit.button(String(d.get("title", id)), 18, d.get("col", UiKit.ACCENT))
		var cid2: String = id
		if saved_cls != "" and String(id) != saved_cls:
			b.disabled = true
		b.pressed.connect(func(): _cls = cid2; _refresh())
		if String(id) == _cls:
			b.add_theme_color_override("font_color", d.get("col", UiKit.ACCENT))
		_class_row.add_child(b)
	_class_desc.text = String(ClassDatabase.get_data(_cls).get("desc", ""))

## Domyślna klasa to ta zapisana przy wybranej postaci.
func _pick_saved_class() -> void:
	var saved := String(GameState.char_profile(_char).get("class", ""))
	if saved != "" and ClassDatabase.for_character(_char).has(saved):
		_cls = saved

func _refresh_online_info() -> void:
	if _online_panel == null:
		return
	var show := online and _mode == "host" and Net.is_host
	_online_panel.visible = show
	if not show:
		return
	var info := Net.online_info()
	var code := String(info.get("code", Net.host_code))
	var port := int(info.get("port", 0))
	var local_ip := String(info.get("local_ip", ""))
	var external_ip := String(info.get("external_ip", ""))
	var mapped := bool(info.get("mapped", false))
	var busy := bool(info.get("busy", false))
	var err := String(info.get("error", ""))
	if busy:
		_online_addr.text = "UDP %d · konfiguruję router (UPnP)…" % port
		_online_hint.text = "IP lokalne: %s. Za chwilę pojawi się adres do udostępnienia." % local_ip
		_copy_btn.disabled = true
		return
	var ip := external_ip if mapped and external_ip != "" else local_ip
	_online_addr.text = "IP: %s   KOD: %s" % [ip, code]
	_copy_btn.disabled = false
	if mapped and external_ip != "":
		_online_hint.text = "Przekierowanie UPnP aktywne (UDP %d). Podaj drugiemu graczowi IP i kod." % port
	elif mapped:
		_online_hint.text = "UPnP aktywne, ale router nie podał publicznego IP. Sprawdź je w routerze; port UDP %d." % port
	else:
		var reason := err if err != "" else "UPnP niedostępne."
		_online_hint.text = "%s Przekieruj UDP %d na ten komputer i podaj swoje publiczne IP. IP lokalne: %s." % [reason, port, local_ip]

func _copy_online_address() -> void:
	if not Net.is_host:
		return
	var info := Net.online_info()
	var ip := String(info.get("external_ip", ""))
	if ip == "" or not bool(info.get("mapped", false)):
		ip = String(info.get("local_ip", ""))
	var port := int(info.get("port", 0))
	DisplayServer.clipboard_set("%s  KOD: %s  (UDP %d)" % [ip, Net.host_code, port])
	_status.text = "Adres skopiowany do schowka."
	Audio.play("confirm")

func _on_go() -> void:
	var code := _code_field.text.strip_edges().to_upper()
	if Net.code_to_port(code) < 0:
		_status.text = "Kod musi mieć 4 znaki (bez 0, 1, O, I)."
		Audio.play("deny")
		return
	GameState.set_slot(_slot)
	Net.my_class = _cls
	Net.my_name = GameState.nick()
	Audio.play("confirm")
	if _mode == "host":
		_status.text = "Tworzę pokój online…" if online else "Tworzę pokój…"
		Net.host_game(code, online)
	else:
		var addr := _addr_field.text.strip_edges()
		if addr.is_empty():
			if online:
				_status.text = "Podaj publiczne IP hosta."
				Audio.play("deny")
				return
			_status.text = "Szukam pokoju %s…" % code
			Net.join_game(code)
		else:
			_status.text = "Łączę z %s (kod %s)…" % [addr, code]
			Net.join_game_at(code, addr)

func _on_online_info_ready(_info: Dictionary) -> void:
	_refresh_online_info()

func _on_hosting_ready(code: String) -> void:
	_code = code
	_code_field.text = code
	if online:
		_status.text = "Pokój online otwarty. Czekam na drugiego gracza… (kod: %s)" % code
	else:
		_status.text = "Pokój otwarty. Czekam na drugiego gracza… (kod: %s)" % code
	_refresh_online_info()

func _on_peer_joined(_id: int) -> void:
	_status.text = "Gracz dołączył. Czekam na wybór postaci…"

func _on_client_info_received(id: int, info: Dictionary) -> void:
	if not Net.is_host or _host_started:
		return
	_remote_char = String(info.get("char", "lady"))
	_remote_class = String(info.get("class", "wojownik"))
	if _remote_char == _char:
		_remote_char = "lady" if _char == "lord" else "lord"
	_status.text = "%s dołączył! Startujemy." % String(info.get("name", "Gracz 2"))
	_host_started = true
	Net.broadcast_start({
		"p1": _char,
		"p2": _remote_char,
		"cls1": _cls,
		"cls2": _remote_class,
		"arena": arena,
	})
	_start_local(_remote_char)

func _on_joined_ok() -> void:
	_status.text = "Połączono! Czekam na start hosta…"
	var lo := GameState.arena_loadout(_char)
	Net.send_client_info({
		"char": _char,
		"class": _cls,
		"name": GameState.nick(),
		"stats": lo["stats"],
		"gear": lo["gear"],
	})

func _on_join_failed(reason: String) -> void:
	_status.text = reason
	Audio.play("deny")

func _start_local(p2: String) -> void:
	on_start.emit(_char, p2, _cls)
