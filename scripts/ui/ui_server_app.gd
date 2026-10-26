class_name UiServerApp
extends Control
## Okno aplikacji ChickenSerwer: konfiguracja i start serwera, adresy do podania graczom,
## lista graczy, log oraz konsola komend. Tryb --headless działa na tej samej klasie MmoServer.

var srv := MmoServer.new()

var _name_f: LineEdit
var _port_f: SpinBox
var _max_f: SpinBox
var _motd_f: LineEdit
var _admin_cb: CheckBox
var _start_btn: Button
var _status: Label
var _addr: Label
var _players: RichTextLabel
var _log: RichTextLabel
var _cmd: LineEdit
var _hint_panel: PanelContainer
var _hint_box: VBoxContainer
var _usage_label: Label
var _ghost: Label
var _hint_opts: Array = []
var _hint_start := 0
var _hint_sel := 0
var _hist: Array = []
var _hist_i := 0
var _refresh_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().title = "ChickenSerwer"
	AudioServer.set_bus_mute(0, true)
	Engine.max_fps = 60
	add_child(srv)
	srv.load_config()
	srv.log_line.connect(_on_log)
	srv.players_changed.connect(_refresh)
	srv.info_changed.connect(_refresh)
	srv.stopped.connect(func():
		if DisplayServer.get_name() == "headless":
			get_tree().quit())
	_build_ui()
	_refresh()
	var auto := ServerMode.flag("autostart") or DisplayServer.get_name() == "headless"
	var p := ServerMode.arg("port")
	if p != "":
		_port_f.value = float(p)
	var nm := ServerMode.arg("name")
	if nm != "":
		_name_f.text = nm
	var mx := ServerMode.arg("max")
	if mx != "":
		_max_f.value = float(mx)
	if auto:
		_on_start_stop.call_deferred()

func _build_ui() -> void:
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.07, 0.11)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.5)))
	var root := UiKit.hbox(14)
	UiKit.full_margin(root, 18.0)
	add_child(root)

	# --- lewa kolumna: konfiguracja
	var left := UiKit.vbox(8)
	left.custom_minimum_size = Vector2(400, 0)
	root.add_child(left)
	left.add_child(UiKit.title("CHICKENSERWER", 34))
	left.add_child(UiKit.label("Serwer dedykowany: gracze dołączają z ChickenRPG przez IP.", 14, UiKit.DIM))
	left.add_child(UiKit.sep(4))
	_name_f = _field(left, "Nazwa serwera", String(srv.cfg["name"]))
	_port_f = _spin(left, "Port (UDP)", int(srv.cfg["port"]), 1024, 65535)
	_max_f = _spin(left, "Limit graczy", int(srv.cfg["max_players"]), 1, Mmo.MAX_PLAYERS)
	_motd_f = _field(left, "Wiadomość powitalna", String(srv.cfg["motd"]))
	_admin_cb = CheckBox.new()
	_admin_cb.text = "Pozwól wybrać klasę Admin (tymczasowa)"
	_admin_cb.button_pressed = bool(srv.cfg["allow_admin_class"])
	left.add_child(_admin_cb)
	_start_btn = UiKit.button("Utwórz serwer", 22, UiKit.GOOD)
	_start_btn.pressed.connect(_on_start_stop)
	left.add_child(_start_btn)
	_status = UiKit.label("", 15, UiKit.ACCENT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_status)
	_addr = UiKit.label("", 15, UiKit.ACCENT2)
	_addr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_addr)
	left.add_child(UiKit.label("Gracze:", 16, UiKit.ACCENT))
	_players = RichTextLabel.new()
	_players.bbcode_enabled = true
	_players.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_players.scroll_following = false
	left.add_child(_players)

	# --- prawa kolumna: log + konsola
	var right := UiKit.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	right.add_child(UiKit.label("Log i konsola (komendy z /, np. /help, /list, /say, /op nazwa, /stop)", 14, UiKit.DIM))
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.selection_enabled = true
	right.add_child(_log)
	_cmd = LineEdit.new()
	_cmd.placeholder_text = "Komenda lub wiadomość do wszystkich…  (Enter)"
	_cmd.custom_minimum_size = Vector2(0, 40)
	_cmd.text_submitted.connect(_on_cmd)
	_cmd.text_changed.connect(_on_cmd_text)
	_cmd.gui_input.connect(_on_cmd_key)
	right.add_child(_cmd)
	# podpowiedzi komend jak w Minecrafcie (to samo co w czacie gry), konsola ma prawa admina
	_hint_panel = UiKit.panel(Color(0.0, 0.0, 0.0, 0.85), 0)
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.z_index = 50
	_hint_box = VBoxContainer.new()
	_hint_box.add_theme_constant_override("separation", 0)
	_hint_panel.add_child(_hint_box)
	add_child(_hint_panel)
	_usage_label = UiKit.label("", 13, Color(0.7, 0.7, 0.72))
	_usage_label.visible = false
	_usage_label.z_index = 50
	add_child(_usage_label)
	_ghost = Label.new()
	_ghost.add_theme_font_size_override("font_size", 16)
	_ghost.add_theme_color_override("font_color", Color(1, 1, 1, 0.32))
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd.add_child(_ghost)

func _field(parent: Control, caption: String, value: String) -> LineEdit:
	parent.add_child(UiKit.label(caption, 14, UiKit.DIM))
	var f := LineEdit.new()
	f.text = value
	f.custom_minimum_size = Vector2(0, 38)
	parent.add_child(f)
	return f

func _spin(parent: Control, caption: String, value: int, lo: int, hi: int) -> SpinBox:
	parent.add_child(UiKit.label(caption, 14, UiKit.DIM))
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = value
	parent.add_child(s)
	return s

func _on_start_stop() -> void:
	if srv.running:
		srv.stop()
	else:
		srv.cfg["name"] = _name_f.text.strip_edges() if _name_f.text.strip_edges() != "" else "ChickenSerwer"
		srv.cfg["port"] = int(_port_f.value)
		srv.cfg["max_players"] = int(_max_f.value)
		srv.cfg["motd"] = _motd_f.text
		srv.cfg["allow_admin_class"] = _admin_cb.button_pressed
		srv.start()
	_refresh()

func _on_cmd(text: String) -> void:
	_cmd.clear()
	_on_cmd_text("")
	var t := text.strip_edges()
	if t == "":
		return
	_hist.append(t)
	_hist_i = _hist.size()
	if not srv.running:
		_on_log("Serwer nie działa — najpierw „Utwórz serwer”.")
		return
	if t.begins_with("/"):
		srv.cmds.run(srv, 0, t)
	else:
		srv.cmds.run(srv, 0, "/say " + t)
	_cmd.grab_focus()

func _on_log(line: String) -> void:
	if _log:
		_log.append_text(line.replace("[", "[lb]") + "\n")

func _process(delta: float) -> void:
	_refresh_t -= delta
	if _refresh_t <= 0.0:
		_refresh_t = 1.0
		_refresh()

func _refresh() -> void:
	if _start_btn == null:
		return
	var on := srv.running
	_start_btn.text = "Zatrzymaj serwer" if on else "Utwórz serwer"
	_name_f.editable = not on
	_motd_f.editable = not on
	_admin_cb.disabled = on
	_port_f.editable = not on
	_max_f.editable = not on
	if not on:
		_status.text = "Serwer wyłączony."
		_addr.text = ""
		_players.text = ""
		return
	var secs := srv.uptime()
	_status.text = "Działa: %02d:%02d:%02d · graczy %d/%d · moby %d · strefy %d · poz. śr. %.0f" % [secs / 3600, (secs / 60) % 60, secs % 60, srv.peers.size(), int(srv.cfg["max_players"]), srv.total_mobs(), srv.instances.size(), srv.average_level()]
	var port := int(srv.cfg["port"])
	var lines := "W sieci domowej: %s:%d" % [srv.info.get("local_ip", ""), port]
	var ext := String(srv.info.get("external_ip", ""))
	if ext != "":
		lines += "\nPrzez internet: %s:%d" % [ext, port]
	lines += "\n" + String(srv.info.get("upnp", ""))
	lines += "\n(Gracze z internetu: router musi przekierować port UDP %d na ten komputer.)" % port
	_addr.text = lines
	var txt := ""
	for p in srv.peers.values():
		var rec: Dictionary = p["rec"]
		txt += "%s — poz. %d %s%s\n" % [rec["name"], int(rec["level"]), rec["class"], " [ADMIN]" if srv.is_admin_rec(rec) else ""]
	_players.text = txt

# ---------------------------------------------------------- podpowiedzi komend ---

func _hint_ctx() -> Dictionary:
	var names: Array = []
	for pl in srv.peers.values():
		names.append(String(pl["name"]))
	return {"players": names}

func _on_cmd_text(text: String) -> void:
	var h := ServerCmds.hints(text, true, _hint_ctx())
	_hint_opts = h["options"]
	_hint_start = int(h["start"])
	_hint_sel = clampi(_hint_sel, 0, maxi(0, _hint_opts.size() - 1))
	var bad: bool = text.begins_with("/") and text.length() > 1 and String(h["usage"]) == "" and _hint_opts.is_empty()
	_cmd.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35) if bad else Color(0.95, 0.95, 0.95))
	for c in _hint_box.get_children():
		c.queue_free()
	_ghost.text = ""
	if String(h["usage"]) == "" and _hint_opts.is_empty():
		_hint_panel.visible = false
		_usage_label.visible = false
		return
	var from := clampi(_hint_sel - 4, 0, maxi(0, _hint_opts.size() - 10))
	for i in range(from, mini(_hint_opts.size(), from + 10)):
		var l := Label.new()
		l.text = " %s " % String((_hint_opts[i] as Array)[0])
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(1.0, 1.0, 0.33) if i == _hint_sel else Color(0.72, 0.72, 0.74))
		_hint_box.add_child(l)
	_hint_panel.visible = not _hint_opts.is_empty()
	_usage_label.text = String(h["usage"])
	_usage_label.visible = String(h["usage"]) != ""
	if not _hint_opts.is_empty():
		var sel_v := String((_hint_opts[clampi(_hint_sel, 0, _hint_opts.size() - 1)] as Array)[0])
		var partial := text.substr(_hint_start)
		if sel_v.to_lower().begins_with(partial.to_lower()):
			_ghost.text = sel_v.substr(partial.length())
	_place_hint.call_deferred()

func _text_width(s: String) -> float:
	return _cmd.get_theme_font("font").get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x

func _place_hint() -> void:
	var origin := _cmd.global_position - global_position
	_ghost.position = Vector2(_text_width(_cmd.text) + 6.0, 8.0)
	var x := origin.x + 6.0 + _text_width(_cmd.text.substr(0, _hint_start))
	var y := origin.y - 2.0
	if _usage_label.visible:
		var uh := _usage_label.get_combined_minimum_size().y
		_usage_label.position = Vector2(origin.x + 6.0, y - uh)
		y -= uh + 2.0
	if _hint_panel.visible:
		var ms := _hint_panel.get_combined_minimum_size()
		_hint_panel.size = ms
		_hint_panel.position = Vector2(x, y - ms.y)

func _on_cmd_key(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key := (event as InputEventKey).keycode
	if (key == KEY_UP or key == KEY_DOWN) and not _hint_opts.is_empty():
		_hint_sel = posmod(_hint_sel + (-1 if key == KEY_UP else 1), _hint_opts.size())
		_on_cmd_text(_cmd.text)
		_cmd.accept_event()
	elif key == KEY_TAB and not _hint_opts.is_empty():
		var o: Array = _hint_opts[clampi(_hint_sel, 0, _hint_opts.size() - 1)]
		var done := _cmd.text.substr(0, _hint_start) + String(o[0]) + " "
		_cmd.text = done
		_cmd.caret_column = done.length()
		_hint_sel = 0
		_on_cmd_text(done)
		_cmd.accept_event()
