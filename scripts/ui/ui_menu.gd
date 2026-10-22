class_name UiMainMenu
extends Control
## Menu główne: tytuł, kontynuacja w zapisie, wybór kurczaka, opcje, wyjście.

var _rows: VBoxContainer
var _slots: Array = []
var _sel := 0
var _continue_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture())
	_add_deco()
	var center := UiKit.vbox(0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(center)
	add_child(center)

	var t := UiKit.title("CHICKEN BRAWL", 76)
	center.add_child(t)
	center.add_child(UiKit.label("jesteś kurczakiem, oni są ptakami", 22, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	center.add_child(UiKit.sep(34))

	_continue_btn = UiKit.button("Kontynuuj", 26)
	_continue_btn.pressed.connect(_on_continue)
	center.add_child(_wrap(_continue_btn))
	center.add_child(UiKit.sep(6))
	var b2 := UiKit.button("Wybierz kurczaka", 26)
	b2.pressed.connect(func(): Audio.play("confirm"); Flow.goto("select"))
	center.add_child(_wrap(b2))
	center.add_child(UiKit.sep(6))
	var brpg := UiKit.button("Nowa gra RPG", 26)
	brpg.pressed.connect(func(): Audio.play("confirm"); Flow.goto("slots"))
	center.add_child(_wrap(brpg))
	center.add_child(UiKit.sep(6))
	var blan := UiKit.button("Gra LAN", 26)
	blan.pressed.connect(func(): Audio.play("confirm"); Flow.goto("lan"))
	center.add_child(_wrap(blan))
	center.add_child(UiKit.sep(6))
	var b3 := UiKit.button("Ustawienia", 26)
	b3.pressed.connect(func(): Audio.play("select"); Flow.goto("settings"))
	center.add_child(_wrap(b3))
	center.add_child(UiKit.sep(6))
	var b4 := UiKit.button("Wyjść", 26)
	b4.pressed.connect(_on_quit)
	center.add_child(_wrap(b4))
	center.add_child(UiKit.sep(20))

	# --- panel opcji (ukryty)
	_options = UiKit.panel(UiKit.BG2, 12)
	_options.visible = false
	_options.custom_minimum_size = Vector2(430, 0)
	center.add_child(_options)
	_build_options()

	var stats := UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	stats.name = "Stats"
	center.add_child(UiKit.sep(14))
	center.add_child(stats)
	stats_row = stats

	GameState.profile_changed.connect(_refresh)
	_refresh()
	Audio.play_music("menu")
	_focus(_continue_btn)

var _options: PanelContainer
var stats_row: Label

func _wrap(c: Control) -> Control:
	var cc := UiKit.panel(Color(0, 0, 0, 0), 0)
	cc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cc.add_child(c)
	c.custom_minimum_size = Vector2(360, 50)
	return cc

func _add_deco() -> void:
	# sylwetki kurczaka po bokach ekranu
	for i in 3:
		var s := Sprite2D.new()
		s.texture = Art.soft_blob(220, Color(1, 1, 1, 0.06), 0.35, 30 + i)
		s.position = Vector2(140.0 + i * 40.0, 560.0 - i * 30.0)
		add_child(s)

func _build_options() -> void:
	var v := UiKit.vbox(6)
	_options.add_child(v)
	v.add_child(UiKit.label("OPCJE", 20, UiKit.ACCENT))
	v.add_child(UiKit.sep(4))
	for entry in [["music", "Muzyka"], ["sfx", "Dźwięki"], ["shake", "Trzęsienie ekranu"]]:
		var key := String(entry[0])
		var b := UiKit.button("%s: TAK" % String(entry[1]), 18)
		b.pressed.connect(func():
			var on := GameState.toggle_setting(key)
			b.text = "%s: %s" % [String(entry[1]), "TAK" if on else "NIE"]
			Audio.play("select")
			if key == "music":
				Audio.set_music_enabled(on)
			elif key == "sfx":
				Audio.play("confirm"))
		b.text = "%s: %s" % [String(entry[1]), "TAK" if GameState.setting(key) else "NIE"]
		v.add_child(b)
	v.add_child(UiKit.sep(4))
	var reset := UiKit.button("Usuń zapis", 18, UiKit.BAD)
	reset.pressed.connect(func():
		if _confirm_reset:
			GameState.reset_save()
			_confirm_reset = false
			reset.text = "Usuń zapis"
			_refresh()
			Audio.play("die")
		else:
			_confirm_reset = true
			reset.text = "Na pewno? Kliknij ponownie"
			Audio.play("deny"))
	v.add_child(reset)

var _confirm_reset := false

func _toggle_options() -> void:
	Audio.play("select")
	_options.visible = not _options.visible

func _refresh() -> void:
	var has: bool = GameState.slot_exists_any()
	_continue_btn.disabled = not has
	var s: Dictionary = GameState.profile.get("stats", {})
	stats_row.text = "Ukończone etapy: %d / %d   ·   Złoto: %d   ·   Pióra: %d   ·   Pokonani bossowie: %d   ·   Zabici: %d" % [
		GameState.stage_unlocked(), StageDB.count(), GameState.gold(), GameState.cod(),
		int(s.get("bosses", 0)), int(s.get("kills", 0)),
	]
	if has:
		_continue_btn.text = "Kontynuuj — %d / %d etapów" % [GameState.stage_unlocked(), StageDB.count()]

func _on_continue() -> void:
	Audio.play("confirm")
	Flow.goto("slots")

func _on_quit() -> void:
	Audio.play("back")
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()

func _focus(b: Button) -> void:
	b.grab_focus()
