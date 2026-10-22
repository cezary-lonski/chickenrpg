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
	"move_up": "W górę (drabina)", "move_down": "W dół (zjazd)",
	"jump": "Skok / podwójny", "light_attack": "Atak lekki", "heavy_attack": "Atak ciężki",
	"dash": "Unik", "block": "Blok", "throw_item": "Rzut przedmiotem",
	"special": "Furia", "sprint": "Sprint (stamina)", "pause": "Pauza", "equipment": "Ekwipunek",
	"quest_log": "Dziennik zadań",
	"skill_1": "Skill 1", "skill_2": "Skill 2", "skill_3": "Skill 3",
	"skill_4": "Skill 4", "skill_5": "Skill 5", "skill_6": "Skill 6",
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
	for entry in [["music", "Muzyka"], ["sfx", "Dźwięki"], ["shake", "Trzęsienie ekranu"]]:
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

	# --- prawa: sterowanie
	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv := UiKit.vbox(6)
	right.add_child(rv)
	rv.add_child(UiKit.label("STEROWANIE — kliknij „Zmień”, potem wciśnij klawisz", 17, UiKit.ACCENT))
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
	(_rows[action] as Label).text = "Naciśnij klawisz…"
	Audio.play("select")

func _input(event: InputEvent) -> void:
	if _cap_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = (event as InputEventKey).physical_keycode
		if kc == KEY_ESCAPE:
			_cap_action = ""
			if _cap_btn:
				_cap_btn.text = "Zmień"
			_refresh_binds()
			return
		GameState.rebind(_cap_action, kc)
		if _cap_btn:
			_cap_btn.text = "Zmień"
		_cap_action = ""
		_refresh_binds()
		get_viewport().set_input_as_handled()
