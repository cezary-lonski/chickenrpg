class_name UiSettings
extends Control
## Ekran ustawień: dźwięk/obraz oraz rebindowanie klawiszy (zapisywane w profilu).

signal on_close

var from := "menu"
var _cap_action := ""
var _cap_btn: Button = null
var _rows: Dictionary = {}

const ACTION_NAMES := {
	"move_left": "Ruch w lewo", "move_right": "Ruch w prawo",
	"move_up": "W górę", "move_down": "W dół",
	"jump": "Skok (tryb platformowy)", "light_attack": "Atak 1 (lekki)", "heavy_attack": "Atak 2 (ciężki)",
	"dash": "Unik", "block": "Blok", "throw_item": "Rzut przedmiotem",
	"special": "Furia", "sprint": "Sprint (stamina)", "pause": "Pauza", "equipment": "Ekwipunek / interakcja",
	"quest_log": "Dziennik zadań", "skill_tree": "Drzewko umiejętności", "world_map": "Mapa świata",
	"skill_1": "Skill 1", "skill_2": "Skill 2", "skill_3": "Skill 3",
	"skill_4": "Skill 4", "skill_5": "Skill 5", "skill_6": "Skill 6",
	"skill_7": "Skill 7", "skill_8": "Skill 8", "skill_9": "Skill 9",
}

func setup(source: String) -> void:
	from = source

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.06, 0.1)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.6)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_top = 8.0
	root.offset_bottom = -8.0
	add_child(root)
	root.add_child(UiKit.title("USTAWIENIA", 42))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var body := UiKit.hbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	# --- lewa: dźwięk i obraz
	var left := UiKit.panel(UiKit.BG, 12)
	left.custom_minimum_size = Vector2(360, 0)
	body.add_child(left)
	var lv := UiKit.vbox(8)
	left.add_child(lv)
	lv.add_child(UiKit.label("DŹWIĘK I OBRAZ", 18, UiKit.ACCENT))
	for entry in [["music", "Muzyka"], ["sfx", "Dźwięki"], ["shake", "Trzęsienie ekranu"], ["toasts", "Komunikaty na ekranie"], ["hitstop", "Spowolnienie przy ataku"], ["animations", "Animacje (oddychanie, mruganie, tło)"], ["auras", "Aury i płomienie"], ["hitboxes", "Pokaż hitboxy"]]:
		var key := String(entry[0])
		var b := UiKit.button("", 18)
		b.custom_minimum_size = Vector2(320, 40)
		b.text = "%s: %s" % [String(entry[1]), "TAK" if GameState.setting(key) else "NIE"]
		b.pressed.connect(func():
			var on := GameState.toggle_setting(key)
			b.text = "%s: %s" % [String(entry[1]), "TAK" if on else "NIE"]
			Audio.play("select")
			if key == "music":
				Audio.set_music_enabled(on)
			elif key == "sfx":
				Audio.play("confirm"))
		lv.add_child(b)

	const GFX_NAMES := ["Niska", "Średnia", "Wysoka", "Bez cząsteczek"]
	const GFX_ORDER := [3, 0, 1, 2]
	var gb := UiKit.button("", 18)
	gb.custom_minimum_size = Vector2(320, 40)
	gb.text = "Jakość grafiki: %s" % GFX_NAMES[GameState.gfx_quality()]
	gb.pressed.connect(func():
		GameState.set_gfx_quality(GFX_ORDER[(GFX_ORDER.find(GameState.gfx_quality()) + 1) % GFX_ORDER.size()])
		gb.text = "Jakość grafiki: %s" % GFX_NAMES[GameState.gfx_quality()]
		Audio.play("select"))
	lv.add_child(gb)
	var rb2 := UiKit.button("", 18)
	rb2.custom_minimum_size = Vector2(320, 40)
	var _res_text := func() -> String:
		return "Rozdzielczość: %s" % ("nie zmieniaj" if GameState.display_idx() < 0 else GameState.RES_NAMES[GameState.display_idx()])
	rb2.text = _res_text.call()
	rb2.pressed.connect(func():
		GameState.set_display((GameState.display_idx() + 1) % GameState.RES_NAMES.size())
		rb2.text = _res_text.call()
		Audio.play("select"))
	lv.add_child(rb2)
	var vb := UiKit.button("", 18)
	vb.custom_minimum_size = Vector2(320, 40)
	vb.text = "Pole widzenia (RPG/online): %s" % GameState.VIEW_NAMES[GameState.view_idx()]
	vb.pressed.connect(func():
		GameState.set_view((GameState.view_idx() + 1) % GameState.VIEW_NAMES.size())
		vb.text = "Pole widzenia (RPG/online): %s" % GameState.VIEW_NAMES[GameState.view_idx()]
		Audio.play("select"))
	lv.add_child(vb)
	var hint := UiKit.label("Niska = płynniej na słabszym sprzęcie i telefonach. Pogoda zmienia się od następnego etapu.", 13, UiKit.DIM)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(320, 0)
	lv.add_child(hint)

	# --- prawa: sterowanie
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv := UiKit.vbox(6)
	right.add_child(rv)
	rv.add_child(UiKit.label("STEROWANIE — kliknij „Zmień”, a potem wciśnij klawisz lub przycisk myszy", 17, UiKit.ACCENT))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 6)
	rv.add_child(g)
	for action in GameState.BIND_ACTIONS:
		g.add_child(UiKit.label(String(ACTION_NAMES.get(action, action)), 15, UiKit.TEXT))
		var val := UiKit.label(GameState.key_label(action), 15, UiKit.GOOD)
		val.custom_minimum_size = Vector2(150, 0)
		g.add_child(val)
		var b := UiKit.button("Zmień", 14)
		b.custom_minimum_size = Vector2(90, 32)
		var a: String = action
		b.pressed.connect(func(): _start_capture(a, b))
		g.add_child(b)
		_rows[action] = val

	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var rb := UiKit.button("Przywróć domyślne", 20)
	rb.pressed.connect(func():
		GameState.reset_binds()
		Audio.play("select")
		_refresh_binds())
	row.add_child(rb)
	var back := UiKit.button("Wstecz", 22)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	row.add_child(back)
	set_process_input(true)

func _refresh_binds() -> void:
	for action in _rows:
		(_rows[action] as Label).text = GameState.key_label(action)

func _start_capture(action: String, btn: Button) -> void:
	_cap_action = action
	_cap_btn = btn
	btn.text = "…"
	(_rows[action] as Label).text = "Naciśnij klawisz lub dowolny przycisk myszy (też boczny)…"
	Audio.play("select")

func _input(event: InputEvent) -> void:
	if _cap_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = (event as InputEventKey).physical_keycode
		if kc == KEY_ESCAPE:
			_cancel_capture()
			return
		GameState.rebind(_cap_action, kc)
		_finish_capture()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		var mb: int = (event as InputEventMouseButton).button_index
		GameState.rebind_mouse(_cap_action, mb)
		_finish_capture()
		get_viewport().set_input_as_handled()

func _finish_capture() -> void:
	if _cap_btn:
		_cap_btn.text = "Zmień"
	_cap_action = ""
	_refresh_binds()

func _cancel_capture() -> void:
	_finish_capture()
