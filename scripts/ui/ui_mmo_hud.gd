class_name UiMmoHud
extends CanvasLayer
## Interfejs gracza na ChickenSerwerze: pasek postaci, sloty umiejętności, czat (T) i panel ekwipunku (I).

signal exit_requested()
signal dialog_closed(token: int)
signal choice_picked(token: int, index: int)

const KIND_COLORS := {
	"chat": "#f6efd9", "system": "#ffd966", "error": "#f2685a", "whisper": "#f59be0", "me": "#9fd9ff", "server": "#ffa94d",
}

var inv_panel: UiMmoInv
var shop_panel: UiMmoShop
var forge_panel: UiMmoForge = null
var _overlay: UiMmoPanel = null
var _overlay_kind := ""
var _dialog: Control = null
var _objective: Label
var _zone_title: Label
var _boss_panel: PanelContainer
var _boss_bar: UiBar
var _boss_name: Label
var _root: Control
var _hp_gauge: UiChickenGauge
var _en_gauge: UiChickenGauge
var _xp_bar: UiBar
var _fan: UiSkillFan
var _title: Label
var _level_label: Label
var _gold: Label
var _log: RichTextLabel
var _log_panel: PanelContainer
var _input: LineEdit
var _hint_panel: PanelContainer
var _hint_box: VBoxContainer
var _usage_label: Label
var _ghost: Label
var _dead: Label
var _online: Label
var _exit_panel: PanelContainer
var _toast_t := 0.0
var _hp_val := 0.0
var _hp_max := 1.0
var _en_val := 0.0
var _en_max := 1.0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	UiKit.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_root = root

	# --- lewy górny panel (jak w normalnej grze): portret, nazwa, poziom, XP
	var left := UiKit.wood()
	left.position = Vector2(14, 12)
	left.custom_minimum_size = Vector2(340, 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)
	var lv := UiKit.vbox(4)
	left.add_child(lv)
	var top := UiKit.hbox(8)
	lv.add_child(top)
	top.add_child(UiKit.icon(Art.hud_icon("chicken", 34, UiKit.ACCENT), 34))
	var names := UiKit.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(names)
	_title = UiKit.label("Kurczak", 17, UiKit.TEXT)
	names.add_child(_title)
	_level_label = UiKit.label("Poziom 1", 12, UiKit.DIM)
	names.add_child(_level_label)
	_xp_bar = UiBar.new()
	_xp_bar.custom_minimum_size = Vector2(250, 8)
	_xp_bar.set_fill(UiKit.XP)
	lv.add_child(_xp_bar)

	# --- prawy górny panel: złoto i liczba graczy
	var right := UiKit.wood()
	right.position = Vector2(1126, 12)
	right.custom_minimum_size = Vector2(140, 0)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right)
	var rv := UiKit.vbox(4)
	right.add_child(rv)
	var g := UiKit.hbox(6)
	rv.add_child(g)
	g.add_child(UiKit.icon(Art.hud_icon("gold", 18, Color(1, 0.82, 0.3)), 18))
	_gold = UiKit.label("0", 16, Color(1, 0.85, 0.4))
	g.add_child(_gold)
	_online = UiKit.label("", 13, UiKit.DIM)
	rv.add_child(_online)

	# --- umiejętności jako jajka i kurczaki-mierniki życia i energii (jak w normalnej grze)
	_fan = UiSkillFan.new()
	_fan.position = Vector2(640.0 - _fan.size.x * 0.5, 612)
	root.add_child(_fan)
	_hp_gauge = UiChickenGauge.new()
	_hp_gauge.set_fill(Color(0.85, 0.28, 0.25))
	_hp_gauge.hi_col = Color(0.95, 0.5, 0.45)
	_hp_gauge.position = Vector2(_fan.position.x - 224.0, 492)
	root.add_child(_hp_gauge)
	_en_gauge = UiChickenGauge.new()
	_en_gauge.flipped = true
	_en_gauge.set_fill(Color(0.29, 0.56, 0.88))
	_en_gauge.hi_col = Color(0.56, 0.76, 0.94)
	_en_gauge.position = Vector2(_fan.position.x + _fan.size.x, 492)
	root.add_child(_en_gauge)

	# --- czat
	_log_panel = UiKit.panel(Color(0.03, 0.03, 0.06, 0.55), 6)
	_log_panel.position = Vector2(14, 262)
	_log_panel.custom_minimum_size = Vector2(500, 180)
	_log_panel.size = Vector2(500, 180)
	_log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_log_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.fit_content = false
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", 15)
	_log_panel.add_child(_log)
	_input = LineEdit.new()
	_input.position = Vector2(14, 448)
	_input.custom_minimum_size = Vector2(500, 34)
	_input.size = Vector2(500, 34)
	_input.placeholder_text = "Wiadomość lub /komenda…  (Enter wyślij, Esc zamknij)"
	_input.max_length = Mmo.MAX_CHAT
	_input.visible = false
	_input.text_submitted.connect(_on_submit)
	_input.text_changed.connect(_on_chat_text)
	_input.gui_input.connect(_on_chat_key)
	root.add_child(_input)
	_hint_panel = UiKit.panel(Color(0.0, 0.0, 0.0, 0.62), 0)
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_box = VBoxContainer.new()
	_hint_box.add_theme_constant_override("separation", 0)
	_hint_panel.add_child(_hint_box)
	root.add_child(_hint_panel)
	_usage_label = UiKit.label("", 13, Color(0.7, 0.7, 0.72))
	_usage_label.visible = false
	root.add_child(_usage_label)
	_ghost = Label.new()
	_ghost.add_theme_font_size_override("font_size", 16)
	_ghost.add_theme_color_override("font_color", Color(1, 1, 1, 0.32))
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_input.add_child(_ghost)

	_dead = UiKit.title("POLEGŁEŚ — odrodzenie za chwilę…", 34, UiKit.BAD)
	_dead.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_dead.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dead.offset_top = 150
	_dead.visible = false
	root.add_child(_dead)

	inv_panel = UiMmoInv.new()
	inv_panel.visible = false
	root.add_child(inv_panel)

	shop_panel = UiMmoShop.new()
	shop_panel.visible = false
	shop_panel.closed.connect(close_shop)
	root.add_child(shop_panel)

	var quest_panel := UiKit.wood()
	quest_panel.position = Vector2(1000, 100)
	quest_panel.custom_minimum_size = Vector2(266, 0)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(quest_panel)
	var qv := UiKit.vbox(2)
	quest_panel.add_child(qv)
	_zone_title = UiKit.label("", 15, UiKit.ACCENT2)
	_zone_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(_zone_title)
	_objective = UiKit.label("", 14, UiKit.TEXT)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qv.add_child(_objective)
	_boss_panel = UiKit.panel(Color(0.1, 0.05, 0.06, 0.8), 10)
	_boss_panel.position = Vector2(330, 20)
	_boss_panel.custom_minimum_size = Vector2(620, 0)
	_boss_panel.visible = false
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_panel)
	var bv := UiKit.vbox(3)
	_boss_panel.add_child(bv)
	_boss_name = UiKit.label("BOSS", 16, Color(1, 0.6, 0.4), HORIZONTAL_ALIGNMENT_CENTER)
	bv.add_child(_boss_name)
	_boss_bar = UiBar.new()
	_boss_bar.custom_minimum_size = Vector2(596, 16)
	_boss_bar.set_fill(Color(0.85, 0.25, 0.2))
	bv.add_child(_boss_bar)

	_build_exit_panel(root)
	Mmo.chat_received.connect(_on_chat)
	Mmo.me_received.connect(refresh_me)
	refresh_me(Mmo.my_info)
	add_line("system", "", "T — czat, I — ekwipunek, E — rozmowa, /help — komendy. Esc — menu.")

func _exit_tree() -> void:
	if Mmo.chat_received.is_connected(_on_chat):
		Mmo.chat_received.disconnect(_on_chat)
	if Mmo.me_received.is_connected(refresh_me):
		Mmo.me_received.disconnect(refresh_me)

func _bar(parent: Control, col: Color, h: int = 14) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(300, h)
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	b.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	b.add_theme_stylebox_override("fill", fg)
	parent.add_child(b)
	return b

func _build_exit_panel(root: Control) -> void:
	# menu Esc ma ten sam układ co PAUZA w normalnej grze; funkcje, których serwer nie obsługuje z menu, są wyszarzone
	_exit_panel = UiKit.panel(Color(0, 0, 0, 0), 0)
	_exit_panel.visible = false
	root.add_child(_exit_panel)
	var wrap := UiKit.hbox(14)
	_exit_panel.add_child(wrap)
	var panel := UiKit.panel(UiKit.BG, 14)
	panel.custom_minimum_size = Vector2(400, 0)
	wrap.add_child(panel)
	var v := UiKit.vbox(6)
	panel.add_child(v)
	v.add_child(UiKit.label("PAUZA", 36, UiKit.ACCENT))
	v.add_child(UiKit.label("Serwer online · gra toczy się dalej", 14, UiKit.DIM))
	v.add_child(UiKit.sep(6))
	var first := UiKit.button("Wracaj do walki", 22)
	first.custom_minimum_size = Vector2(0, 54)
	first.add_theme_stylebox_override("normal", UiKit.sb(Color(0.72, 0.38, 0.16), 6))
	first.add_theme_stylebox_override("focus", UiKit.sb(Color(0.8, 0.45, 0.2), 6, 3, UiKit.ACCENT))
	first.add_theme_stylebox_override("hover", UiKit.sb(Color(0.8, 0.45, 0.2), 6, 3, UiKit.ACCENT))
	first.pressed.connect(func(): Audio.play("confirm"); _exit_panel.visible = false)
	v.add_child(first)
	_pause_btn(v, "Ekwipunek (I)", func(): _exit_panel.visible = false; toggle_inventory())
	_pause_btn(v, "Atrybuty", Callable(), UiKit.ACCENT, true)
	_pause_btn(v, "Umiejętności", Callable(), UiKit.ACCENT, true)
	_pause_btn(v, "Towarzysze (P)", func(): _exit_panel.visible = false; open_overlay("pets", {}))
	_pause_btn(v, "Mapa świata", func(): _exit_panel.visible = false; Mmo.send_chat_text("/mapa"))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	_pause_btn(v, "Ustawienia", Callable(), UiKit.ACCENT, true)
	_pause_btn(v, "Wyjdź do menu", func(): exit_requested.emit(), UiKit.BAD)
	var right := UiKit.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(right)
	var top := UiKit.panel(UiKit.BG, 14)
	right.add_child(top)
	var tv := UiKit.vbox(6)
	top.add_child(tv)
	tv.add_child(UiKit.label("MIASTO I USŁUGI", 13, UiKit.ACCENT))
	var g1 := _pause_row(tv)
	_pause_btn(g1, "Szpital", Callable(), UiKit.GOOD, true)
	_pause_btn(g1, "Skrytka", Callable(), UiKit.ACCENT, true)
	_pause_btn(g1, "Osiągnięcia", Callable(), UiKit.ACCENT, true)
	tv.add_child(UiKit.label("GRA WIELOOSOBOWA", 13, UiKit.ACCENT))
	var g2 := _pause_row(tv)
	_pause_btn(g2, "Multiplayer (LAN)", Callable(), UiKit.GOOD, true)
	_pause_btn(g2, "Arena: zaproś gracza", Callable(), UiKit.BAD, true)
	_pause_btn(g2, "Własne fale (B)", func(): _exit_panel.visible = false; open_overlay("waves", {}))
	var g3 := _pause_row(tv)
	_pause_btn(g3, "Od nowa", Callable(), UiKit.ACCENT, true)
	_pause_btn(g3, "Usuń zapis", Callable(), UiKit.BAD, true)
	var bottom := UiKit.panel(UiKit.BG, 14)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(bottom)
	var v2 := UiKit.vbox(6)
	bottom.add_child(v2)
	v2.add_child(UiKit.label("STEROWANIE", 13, UiKit.ACCENT))
	v2.add_child(UiKit.label("WASD ruch · Shift sprint · J lekki · K ciężki · L unik · U blok · O furia
1-9 skile · E rozmowa/użycie · T czat · / komenda · I ekwipunek · P pety · B fale", 14, UiKit.DIM))
	v2.add_child(UiKit.sep(6))
	v2.add_child(UiKit.label("OPCJE", 13, UiKit.ACCENT))
	var orow := _pause_row(v2)
	var oi := 0
	for entry in [["music", "Muzyka"], ["sfx", "Dźwięki"], ["shake", "Trzęsienie"], ["toasts", "Komunikaty"], ["hitstop", "Spowolnienie ataku"], ["animations", "Animacje"], ["auras", "Aury"]]:
		var key := String(entry[0])
		if oi > 0 and oi % 3 == 0:
			orow = _pause_row(v2)
		oi += 1
		var b := UiKit.button("", 15)
		b.text = "%s: %s" % [String(entry[1]), "TAK" if GameState.setting(key) else "NIE"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			var on := GameState.toggle_setting(key)
			b.text = "%s: %s" % [String(entry[1]), "TAK" if on else "NIE"]
			Audio.play("select")
			if key == "music":
				Audio.set_music_enabled(on)
			elif key == "sfx":
				Audio.play("confirm"))
		orow.add_child(b)

func _pause_row(parent: Control) -> HBoxContainer:
	var h := UiKit.hbox(8)
	parent.add_child(h)
	return h

func _pause_btn(parent: Control, text: String, cb: Callable, col: Color = UiKit.ACCENT, off: bool = false) -> Button:
	var b := UiKit.button(text, 17, col)
	b.custom_minimum_size = Vector2(0, 38)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if off:
		b.disabled = true
		b.tooltip_text = "Niedostępne na serwerze z menu (użyj w grze lub komendą)"
	else:
		b.pressed.connect(func():
			Audio.play("confirm")
			cb.call())
	parent.add_child(b)
	return b

# ---------------------------------------------------------------- stan UI ---

func is_typing() -> bool:
	return _input.visible

func is_dialog_open() -> bool:
	return _dialog != null and is_instance_valid(_dialog)

func is_blocking() -> bool:
	return _input.visible or inv_panel.visible or _exit_panel.visible or shop_panel.visible or is_dialog_open() or (forge_panel != null and is_instance_valid(forge_panel)) or has_overlay()

func open_dialog(token: int, lines: Array, accent: Color) -> void:
	if is_dialog_open():
		_dialog.queue_free()
	var d := UiDialog.new()
	d.setup(lines, accent)
	d.on_close.connect(func():
		if is_instance_valid(d):
			d.queue_free()
		_dialog = null
		dialog_closed.emit(token))
	_dialog = d
	_root.add_child(d)

func open_choice(token: int, prompt: String, options: Array, accent: Color) -> void:
	if is_dialog_open():
		_dialog.queue_free()
	var ui := UiChoice.new()
	ui.setup(prompt, options, accent)
	ui.chosen.connect(func(i: int): choice_picked.emit(token, i))
	ui.on_close.connect(func():
		if is_instance_valid(ui):
			ui.queue_free()
		_dialog = null)
	_dialog = ui
	_root.add_child(ui)

func open_shop(stock: Array, gold: int) -> void:
	shop_panel.setup(stock, gold)
	if not shop_panel.visible:
		shop_panel.visible = true
		_center.call_deferred(shop_panel)

## Panele z serwera (szpital, skrytka, laboratorium, pety): otwiera nowy albo odświeża otwarty tego samego rodzaju.
func open_overlay(kind: String, data: Dictionary) -> void:
	if _overlay != null and is_instance_valid(_overlay) and _overlay_kind != kind:
		_overlay.queue_free()
		_overlay = null
	if _overlay == null or not is_instance_valid(_overlay):
		match kind:
			"hospital": _overlay = UiMmoHospital.new()
			"stash": _overlay = UiMmoStash.new()
			"lab": _overlay = UiMmoLab.new()
			"pets": _overlay = UiMmoPets.new()
			"waves": _overlay = UiMmoWaves.new()
			"worldmap": _overlay = UiMmoMap.new()
			_: return
		_overlay_kind = kind
		_overlay.apply_state(data)
		_overlay.closed.connect(close_overlay)
		_root.add_child(_overlay)
	else:
		_overlay.apply_state(data)

func has_overlay() -> bool:
	return _overlay != null and is_instance_valid(_overlay)

func close_overlay() -> void:
	if has_overlay():
		_overlay.queue_free()
		_overlay = null
		Mmo.send_act("panel_close")

func open_forge(state: Dictionary) -> void:
	if forge_panel == null or not is_instance_valid(forge_panel):
		forge_panel = UiMmoForge.new()
		forge_panel.closed.connect(close_forge)
		_root.add_child(forge_panel)
	forge_panel.apply_state(state)

func forge_result(r: Dictionary) -> void:
	if forge_panel != null and is_instance_valid(forge_panel):
		forge_panel.apply_result(r)

func close_forge() -> void:
	if forge_panel != null and is_instance_valid(forge_panel):
		forge_panel.queue_free()
		forge_panel = null
		Mmo.send_act("forge_close")

func close_shop() -> void:
	if shop_panel.visible:
		shop_panel.visible = false
		Mmo.send_act("shop_close")

func set_zone_title(t: String) -> void:
	_zone_title.text = t

func set_objective(title: String, obj: String, wave_i: int, waves: int, active: bool) -> void:
	_zone_title.text = title
	var extra := ""
	if waves > 0 and active:
		extra = "   [fala %d/%d]" % [wave_i, waves]
	_objective.text = obj + extra

func set_boss(bname: String, hp: float, max_hp: float) -> void:
	_boss_panel.visible = bname != ""
	_boss_name.text = bname
	if bname != "":
		_boss_bar.set_value(hp / maxf(1.0, max_hp))

## Ustawia gracza, z którego jajka umiejętności czytają sloty, energię i cooldowny (duch własnej postaci).
func bind_player(p: Player) -> void:
	_fan.player = p

func open_chat(prefix: String = "") -> void:
	_input.visible = true
	_input.text = prefix
	_input.grab_focus()
	_input.caret_column = prefix.length()
	_on_chat_text(prefix)

## Podpowiedzi jak w Minecrafcie: po "/" komendy, potem argumenty (nicki, przedmioty…). Góra/dół wybiera, Tab uzupełnia.
var _hint_opts: Array = []
var _hint_start := 0
var _hint_sel := 0

func _hint_ctx() -> Dictionary:
	var names: Array = []
	for r in Mmo.roster.values():
		names.append(String((r as Dictionary).get("name", "")))
	var ctx := {"players": names}
	var known: Array = Mmo.my_info.get("known_skills", [])
	if not known.is_empty():
		ctx["skills"] = known
	return ctx

func _on_chat_text(text: String) -> void:
	var h := ServerCmds.hints(text, bool(Mmo.my_info.get("admin", false)), _hint_ctx())
	_hint_opts = h["options"]
	_hint_start = int(h["start"])
	_hint_sel = clampi(_hint_sel, 0, maxi(0, _hint_opts.size() - 1))
	# nieznana komenda świeci na czerwono, jak w Minecrafcie
	var bad: bool = text.begins_with("/") and text.length() > 1 and String(h["usage"]) == "" and _hint_opts.is_empty()
	_input.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35) if bad else UiKit.TEXT)
	_render_hint(String(h["usage"]))

## Okienko podpowiedzi jak w Minecrafcie: ciemna lista tuż nad polem czatu, wyrównana do uzupełnianego słowa,
## zaznaczona pozycja żółta, reszta szara; szary „duch” dopisku w polu; składnia komendy nad listą.
func _render_hint(usage: String) -> void:
	for c in _hint_box.get_children():
		c.queue_free()
	_ghost.text = ""
	var typed := _input.text
	if usage == "" and _hint_opts.is_empty():
		_hint_panel.visible = false
		_usage_label.visible = false
		return
	var from := clampi(_hint_sel - 4, 0, maxi(0, _hint_opts.size() - 10))
	for i in range(from, mini(_hint_opts.size(), from + 10)):
		var o: Array = _hint_opts[i]
		var l := Label.new()
		l.text = " %s " % String(o[0])
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(1.0, 1.0, 0.33) if i == _hint_sel else Color(0.72, 0.72, 0.74))
		_hint_box.add_child(l)
	_hint_panel.visible = not _hint_opts.is_empty()
	_usage_label.text = usage
	_usage_label.visible = usage != ""
	if not _hint_opts.is_empty():
		var sel_v := String((_hint_opts[clampi(_hint_sel, 0, _hint_opts.size() - 1)] as Array)[0])
		var partial := typed.substr(_hint_start)
		if sel_v.to_lower().begins_with(partial.to_lower()):
			_ghost.text = sel_v.substr(partial.length())
	_place_hint.call_deferred()

func _text_width(s: String) -> float:
	var f := _input.get_theme_font("font")
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x

func _place_hint() -> void:
	var left := _input.position.x + 6.0
	_ghost.position = Vector2(_text_width(_input.text) + 6.0, 3.0)
	var x := left + _text_width(_input.text.substr(0, _hint_start))
	var y := _input.position.y - 2.0
	if _usage_label.visible:
		var uh := _usage_label.get_combined_minimum_size().y
		_usage_label.position = Vector2(left, y - uh)
		y -= uh + 2.0
	if _hint_panel.visible:
		var ms := _hint_panel.get_combined_minimum_size()
		_hint_panel.size = ms
		_hint_panel.position = Vector2(minf(x, 1280.0 - ms.x - 6.0), y - ms.y)

func _on_chat_key(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key := (event as InputEventKey).keycode
	if (key == KEY_UP or key == KEY_DOWN) and not _hint_opts.is_empty():
		_hint_sel = posmod(_hint_sel + (-1 if key == KEY_UP else 1), _hint_opts.size())
		_on_chat_text(_input.text)
		_input.accept_event()
	elif key == KEY_TAB and not _hint_opts.is_empty():
		var o: Array = _hint_opts[clampi(_hint_sel, 0, _hint_opts.size() - 1)]
		var done := _input.text.substr(0, _hint_start) + String(o[0]) + " "
		_input.text = done
		_input.caret_column = done.length()
		_hint_sel = 0
		_on_chat_text(done)
		_input.accept_event()

func close_chat() -> void:
	_hint_panel.visible = false
	_usage_label.visible = false
	_ghost.text = ""
	_input.visible = false
	_input.release_focus()

func toggle_inventory() -> void:
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible:
		inv_panel.rebuild(Mmo.my_info)
		_center.call_deferred(inv_panel)

func toggle_exit_menu() -> void:
	_exit_panel.visible = not _exit_panel.visible
	if _exit_panel.visible:
		_center.call_deferred(_exit_panel)

func _center(c: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(c):
		c.position = ((get_viewport().get_visible_rect().size - c.size) * 0.5).floor()

## Esc: zamyka kolejno czat, ekwipunek, menu; gdy nic nie było otwarte — otwiera menu.
func handle_escape() -> void:
	if _input.visible:
		close_chat()
	elif has_overlay():
		if _overlay.cancel_or_close():
			close_overlay()
	elif forge_panel != null and is_instance_valid(forge_panel):
		if forge_panel.cancel_or_close():
			close_forge()
	elif shop_panel.visible:
		close_shop()
	elif inv_panel.visible:
		inv_panel.visible = false
	elif _exit_panel.visible:
		_exit_panel.visible = false
	else:
		toggle_exit_menu()

func _on_submit(text: String) -> void:
	var t := text.strip_edges()
	close_chat()
	if t != "":
		Mmo.send_chat_text(t)

func _on_chat(kind: String, from: String, text: String) -> void:
	add_line(kind, from, text)

func add_line(kind: String, from: String, text: String) -> void:
	var col := String(KIND_COLORS.get(kind, "#ffffff"))
	var safe := text.replace("[", "[lb]")
	var name_safe := from.replace("[", "[lb]")
	match kind:
		"chat":
			_log.append_text("[color=#ffd966]<%s>[/color] [color=%s]%s[/color]\n" % [name_safe, col, safe])
		"whisper":
			_log.append_text("[color=%s][%s] %s[/color]\n" % [col, name_safe, safe])
		"me":
			_log.append_text("[color=%s]* %s %s[/color]\n" % [col, name_safe, safe])
		"server":
			_log.append_text("[color=%s][%s] %s[/color]\n" % [col, name_safe, safe])
		_:
			_log.append_text("[color=%s]%s[/color]\n" % [col, safe])

# ----------------------------------------------------------------- odświeżanie ---

func refresh_me(info: Dictionary) -> void:
	if info.is_empty():
		return
	var cls := String(ClassDatabase.get_data(String(info.get("class", ""))).get("title", info.get("class", "")))
	_title.text = String(info.get("name", ""))
	_level_label.text = "Poziom %d · %s%s" % [int(info.get("level", 1)), cls, " · ADMIN" if bool(info.get("admin", false)) else ""]
	_xp_bar.set_value(float(info.get("xp", 0)) / maxf(1.0, float(info.get("xp_need", 1))))
	_gold.text = str(int(info.get("gold", 0)))
	if inv_panel.visible:
		inv_panel.rebuild(info)

func set_vitals(hp: float, max_hp: float, en: float, max_en: float, dead: bool, online: int) -> void:
	_hp_gauge.set_value(hp / maxf(1.0, max_hp))
	_hp_gauge.text = "%d" % int(hp)
	_en_gauge.set_value(en / maxf(1.0, max_en))
	_en_gauge.text = "%d" % int(en)
	_dead.visible = dead
	_online.text = "Online: %d" % online
