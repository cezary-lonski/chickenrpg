class_name UiPause
extends CanvasLayer
## Nakładka pauzy. Nie usuwa sceny etapu — tylko ją przyciemnia.

signal resume_pressed
signal loadout_pressed
signal attributes_pressed
signal skills_pressed
signal pets_pressed
signal settings_pressed
signal restart_pressed
signal menu_pressed
signal host_pressed(online: bool)
signal waves_pressed
signal arena_pressed
signal map_pressed
signal stash_pressed
signal achievements_pressed
signal hospital_pressed

var _panel: PanelContainer
var _root: Control

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	UiKit.full(_root)
	add_child(_root)
	var dim := UiKit.dim(Color(0.05, 0.04, 0.08, 0.25))
	_root.add_child(dim)
	var wrap := UiKit.hbox(14)
	UiKit.full_margin(wrap, 40.0)
	_root.add_child(wrap)
	_panel = UiKit.panel(UiKit.BG, 14)
	_panel.custom_minimum_size = Vector2(400, 0)
	wrap.add_child(_panel)
	var v := UiKit.vbox(6)
	_panel.add_child(v)
	v.add_child(UiKit.label("PAUZA", 36, UiKit.ACCENT))
	v.add_child(UiKit.label("Poziom %d · Złoto %d" % [GameState.player_level(), GameState.gold()], 14, UiKit.DIM))
	v.add_child(UiKit.sep(6))
	var first := UiKit.button("Wracaj do walki", 22)
	first.custom_minimum_size = Vector2(0, 54)
	var fs := UiKit.sb(Color(0.72, 0.38, 0.16), 6)
	first.add_theme_stylebox_override("normal", fs)
	first.add_theme_stylebox_override("focus", UiKit.sb(Color(0.8, 0.45, 0.2), 6, 3, UiKit.ACCENT))
	first.add_theme_stylebox_override("hover", UiKit.sb(Color(0.8, 0.45, 0.2), 6, 3, UiKit.ACCENT))
	first.pressed.connect(func():
		Audio.play("confirm")
		resume_pressed.emit())
	v.add_child(first)
	_btn(v, "Ekwipunek", func(): loadout_pressed.emit())
	_attr_button = _btn(v, "Atrybuty", func(): attributes_pressed.emit())
	_skills_button = _btn(v, "Umiejętności", func(): skills_pressed.emit())
	_btn(v, "Towarzysze", func(): pets_pressed.emit())
	_btn(v, "Mapa świata (M)", func(): map_pressed.emit())
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	_btn(v, "Ustawienia", func(): settings_pressed.emit())
	_btn(v, "Wyjdź do menu", func(): menu_pressed.emit(), UiKit.BAD)
	var right := UiKit.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(right)
	var top := UiKit.panel(UiKit.BG, 14)
	right.add_child(top)
	var tv := UiKit.vbox(6)
	top.add_child(tv)
	tv.add_child(UiKit.label("MIASTO I USŁUGI", 13, UiKit.ACCENT))
	var g1 := _row3(tv)
	_btn(g1, "Szpital", func(): hospital_pressed.emit(), UiKit.GOOD)
	_btn(g1, "Skrytka", func(): stash_pressed.emit())
	_btn(g1, "Osiągnięcia", func(): achievements_pressed.emit())
	tv.add_child(UiKit.label("GRA WIELOOSOBOWA", 13, UiKit.ACCENT))
	var g2 := _row3(tv)
	_btn(g2, "Multiplayer (LAN)", func(): host_pressed.emit(false), UiKit.GOOD)
	_btn(g2, "Arena: zaproś gracza", func(): arena_pressed.emit(), UiKit.BAD)
	_btn(g2, "Własne fale", func(): waves_pressed.emit())
	var g3 := _row3(tv)
	_btn(g3, "Od nowa", func(): restart_pressed.emit())
	_btn(g3, "Usuń zapis", _do_reset, UiKit.BAD)
	var bottom := UiKit.panel(UiKit.BG, 14)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(bottom)
	var v2 := UiKit.vbox(6)
	bottom.add_child(v2)
	v2.add_child(UiKit.label("STEROWANIE", 13, UiKit.ACCENT))
	v2.add_child(UiKit.label("WASD ruch · Shift sprint · J lekki · K ciężki · L unik · U blok · I rzut · O furia
1-9 skile · E rozmowa/użycie · Q dziennik · T umiejętności", 14, UiKit.DIM))
	v2.add_child(UiKit.sep(6))
	v2.add_child(UiKit.label("OPCJE", 13, UiKit.ACCENT))
	_opts = UiKit.vbox(4)
	v2.add_child(_opts)
	var orow := _row3(_opts)
	var oi := 0
	for entry in [["music", "Muzyka"], ["sfx", "Dźwięki"], ["shake", "Trzęsienie"], ["toasts", "Komunikaty"], ["hitstop", "Spowolnienie ataku"], ["animations", "Animacje"], ["auras", "Aury"]]:
		var key := String(entry[0])
		if oi > 0 and oi % 3 == 0:
			orow = _row3(_opts)
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
	_refresh_attr_button()
	first.grab_focus()
	Audio.play("pause")

func _row3(parent: Control) -> HBoxContainer:
	var h := UiKit.hbox(8)
	parent.add_child(h)
	return h

var _opts: VBoxContainer
var _attr_button: Button
var _skills_button: Button
var _confirm_reset := false

func refresh_attributes_button() -> void:
	_refresh_attr_button()

func _refresh_attr_button() -> void:
	if _attr_button == null or not is_instance_valid(_attr_button):
		return
	if _skills_button and is_instance_valid(_skills_button):
		var sp := GameState.skill_points()
		_skills_button.text = ("Umiejętności (%d)" % sp) if sp > 0 else "Umiejętności"
	var points := GameState.attr_points()
	_attr_button.text = ("Atrybuty (%d)" % points) if points > 0 else "Atrybuty"
	_attr_button.disabled = points <= 0

func _btn(parent: Control, text: String, cb: Callable, col: Color = UiKit.ACCENT) -> Button:
	var b := UiKit.button(text, 17, col)
	b.custom_minimum_size = Vector2(0, 38)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func():
		Audio.play("confirm")
		cb.call())
	parent.add_child(b)
	return b

func _toggle_opts() -> void:
	Audio.play("select")
	_opts.visible = not _opts.visible

func _do_reset() -> void:
	if _confirm_reset:
		GameState.reset_save()
		_confirm_reset = false
		GameState.toast.emit("Zapis usunięty.", UiKit.BAD)
	else:
		_confirm_reset = true
		GameState.toast.emit("Kliknij ponownie, aby usunąć zapis.", UiKit.BAD)

func open() -> void:
	visible = true

func close() -> void:
	visible = false
	queue_free()
