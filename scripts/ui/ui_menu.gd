class_name UiMainMenu
extends Control

var _continue_btn: Button
var _options: PanelContainer
var stats_row: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture())
	var center := UiKit.vbox(0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(center)
	add_child(center)
	center.add_child(UiKit.title("CHICKEN BRAWL", 60))
	center.add_child(UiKit.label("jesteś kurczakiem, oni są ptakami", 20, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	center.add_child(UiKit.sep(12))
	_continue_btn = UiKit.button("Kontynuuj", 22)
	_continue_btn.pressed.connect(_on_continue)
	center.add_child(_wrap(_continue_btn))
	center.add_child(UiKit.sep(0))
	var brpg := UiKit.button("Nowa gra RPG", 22)
	brpg.pressed.connect(func(): Audio.play("confirm"); Flow.goto("slots"))
	center.add_child(_wrap(brpg))
	center.add_child(UiKit.sep(0))
	var bwaves := UiKit.button("Własne fale", 22)
	bwaves.pressed.connect(_on_waves)
	center.add_child(_wrap(bwaves))
	center.add_child(UiKit.sep(0))
	var bchal := UiKit.button("Wyzwania — pojedynki", 22, Color(1.0, 0.75, 0.3))
	bchal.pressed.connect(func(): Audio.play("confirm"); Flow.start_challenge())
	center.add_child(_wrap(bchal))
	center.add_child(UiKit.sep(0))
	var barena := UiKit.button("Arena graczy", 22, Color(1.0, 0.45, 0.4))
	barena.pressed.connect(func(): Audio.play("confirm"); Flow.goto("lan", {"arena": true}))
	center.add_child(_wrap(barena))
	center.add_child(UiKit.sep(0))
	var bcreator := UiKit.button("Kreator Postaci", 22)
	bcreator.pressed.connect(func(): Audio.play("confirm"); Flow.goto("creator"))
	center.add_child(_wrap(bcreator))
	center.add_child(UiKit.sep(0))
	var bonline := UiKit.button("Gra Online", 22)
	bonline.pressed.connect(func(): Audio.play("confirm"); Flow.goto("online"))
	center.add_child(_wrap(bonline))
	center.add_child(UiKit.sep(0))
	var blan := UiKit.button("Gra LAN", 22)
	blan.pressed.connect(func(): Audio.play("confirm"); Flow.goto("lan"))
	center.add_child(_wrap(blan))
	center.add_child(UiKit.sep(0))
	var bpaint := UiKit.button("Tryb Paint", 22)
	bpaint.pressed.connect(func(): Audio.play("confirm"); Flow.goto("paint"))
	center.add_child(_wrap(bpaint))
	center.add_child(UiKit.sep(0))
	var bach := UiKit.button("Osiągnięcia", 22)
	bach.pressed.connect(func(): Audio.play("select"); Flow.goto("achievements"))
	center.add_child(_wrap(bach))
	center.add_child(UiKit.sep(0))
	var bset := UiKit.button("Ustawienia", 22)
	bset.pressed.connect(func(): Audio.play("select"); Flow.goto("settings"))
	center.add_child(_wrap(bset))
	center.add_child(UiKit.sep(0))
	var b4 := UiKit.button("Wyjście", 22)
	b4.pressed.connect(_on_quit)
	center.add_child(_wrap(b4))
	center.add_child(UiKit.sep(14))
	stats_row = UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(stats_row)
	GameState.profile_changed.connect(_refresh)
	_refresh()
	Audio.play_music("menu")
	if _continue_btn: _continue_btn.grab_focus()

func _wrap(c: Control) -> Control:
	var cc := UiKit.panel(Color(0,0,0,0), 0)
	cc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cc.add_child(c)
	c.custom_minimum_size = Vector2(320, 40)
	return cc

func _refresh() -> void:
	if stats_row: stats_row.text = "Złoto: %d   COD: %d" % [GameState.gold(), GameState.cod()]
	if _continue_btn: _continue_btn.visible = GameState.slot_exists_any()

func _on_continue() -> void:
	Audio.play("confirm")
	var last := GameState.last_slot()
	GameState.set_slot(last)
	Flow._slot_is_new = false
	# kontynuacja: od razu do gry, z zapisaną postacią, jej klasą i poziomem trudności
	var hc := Flow.pick_hero()
	var hero := String(hc[0])
	var cls := String(hc[1])
	Flow.pending_replay = -1
	GameState.start_rpg_run("solo", hero, "", false)
	GameState.set_class(cls)
	Flow.goto("game", {"stage": int(GameState.run.get("stage_index", 0))})

func _on_waves() -> void:
	Audio.play("confirm")
	var last := GameState.last_slot()
	if last >= 1 and GameState.slot_exists(last):
		GameState.set_slot(last)
	else:
		GameState.select_slot(1, true)
	Flow._slot_is_new = false
	Flow.goto("waves")

func _on_quit() -> void:
	get_tree().quit()
