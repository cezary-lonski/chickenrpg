class_name UiMainMenu
extends Control

var _continue_btn: Button
var _options: PanelContainer
var stats_row: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	# tło startowe: pixelartowy krajobraz (świt, zamek, wioska), skalowany bez wygładzania
	var bg := TextureRect.new()
	bg.texture = load("res://menu_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	UiKit.full(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(UiKit.dim(Color(0.04, 0.03, 0.08, 0.28)))
	var center := UiKit.vbox(2)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(center)
	add_child(center)
	center.add_child(UiKit.title("CHICKEN BRAWL", 60))
	center.add_child(UiKit.label("jesteś kurczakiem, oni są ptakami", 20, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	center.add_child(UiKit.sep(12))
	_continue_btn = UiKit.button("Kontynuuj", 20)
	_continue_btn.pressed.connect(_on_continue)
	center.add_child(_wrap(_continue_btn))
	center.add_child(UiKit.sep(0))
	var brpg := UiKit.button("Nowa gra RPG", 20)
	brpg.pressed.connect(func(): Audio.play("confirm"); Flow.goto("slots"))
	center.add_child(_wrap(brpg))
	center.add_child(UiKit.sep(0))
	var bplat := UiKit.button("Tryb platformowy", 20)
	bplat.pressed.connect(func(): Audio.play("confirm"); Flow.goto("select"))
	center.add_child(_wrap(bplat))
	center.add_child(UiKit.sep(0))
	var bwaves := UiKit.button("Własne fale", 20)
	bwaves.pressed.connect(_on_waves)
	center.add_child(_wrap(bwaves))
	center.add_child(UiKit.sep(0))
	var bchal := UiKit.button("Wyzwania — pojedynki", 20, Color(1.0, 0.75, 0.3))
	bchal.pressed.connect(func(): Audio.play("confirm"); Flow.start_challenge())
	center.add_child(_wrap(bchal))
	center.add_child(UiKit.sep(0))
	var barena := UiKit.button("Arena graczy", 20, Color(1.0, 0.45, 0.4))
	barena.pressed.connect(func(): Audio.play("confirm"); Flow.goto("lan", {"arena": true}))
	center.add_child(_wrap(barena))
	center.add_child(UiKit.sep(0))
	var bcreator := UiKit.button("Kreator Postaci", 20)
	bcreator.pressed.connect(func(): Audio.play("confirm"); Flow.goto("creator"))
	center.add_child(_wrap(bcreator))
	center.add_child(UiKit.sep(0))
	var bonline := UiKit.button("Gra Online", 20)
	bonline.pressed.connect(func(): Audio.play("confirm"); Flow.goto("online"))
	center.add_child(_wrap(bonline))
	center.add_child(UiKit.sep(0))
	var blan := UiKit.button("Gra LAN", 20)
	blan.pressed.connect(func(): Audio.play("confirm"); Flow.goto("lan"))
	center.add_child(_wrap(blan))
	center.add_child(UiKit.sep(0))
	var bset := UiKit.button("Ustawienia", 20)
	bset.pressed.connect(func(): Audio.play("select"); Flow.goto("settings"))
	center.add_child(_wrap(bset))
	center.add_child(UiKit.sep(0))
	var b4 := UiKit.button("Wyjście", 20)
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
	var cc := HBoxContainer.new()
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(c)
	c.custom_minimum_size = Vector2(320, 38)
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
