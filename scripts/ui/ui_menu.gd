class_name UiMainMenu
extends Control
## Menu startowe (układ B): animowane tło (bez logo) z menu po prawej na pikselowym tle, przyciski na przyciemnionym pasie po prawej.
## Gra wieloosobowa (LAN) i arena nie są tu dostępne — otwiera się je z menu Esc w trakcie gry.

var _continue_btn: Button
var stats_row: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	# tło: pixelartowy krajobraz (świt, zamek, wioska), skalowany bez wygładzania, z animacją na wierzchu
	var bg := TextureRect.new()
	bg.texture = load("res://menu_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	UiKit.full(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var anim := UiMenuAnim.new()
	UiKit.full(anim)
	add_child(anim)
	# przyciemniony pas pod menu
	var strip := ColorRect.new()
	strip.color = Color(0.05, 0.04, 0.08, 0.62)
	strip.position = Vector2(820, 0)
	strip.size = Vector2(460, 720)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	_continue_btn = _wood_btn("Kontynuuj", Rect2(860, 56, 380, 66), true)
	_continue_btn.pressed.connect(_on_continue)
	_wood_btn("Nowa gra RPG", Rect2(860, 134, 380, 50)).pressed.connect(func(): Audio.play("confirm"); Flow.goto("slots"))
	_wood_btn("Tryb platformowy", Rect2(860, 194, 380, 50)).pressed.connect(func(): Audio.play("confirm"); Flow.goto("select"))
	_wood_btn("Własne fale", Rect2(860, 254, 380, 50)).pressed.connect(_on_waves)
	_wood_btn("Wyzwania — pojedynki", Rect2(860, 314, 380, 50)).pressed.connect(func(): Audio.play("confirm"); Flow.start_challenge())
	_wood_btn("Serwer online (ChickenSerwer)", Rect2(860, 374, 380, 50)).pressed.connect(func(): Audio.play("confirm"); Flow.goto("mmo_connect"))
	_wood_btn("Kreator postaci", Rect2(860, 434, 380, 50)).pressed.connect(func(): Audio.play("confirm"); Flow.goto("creator"))
	_wood_btn("Ustawienia", Rect2(860, 494, 184, 46), false, 19).pressed.connect(func(): Audio.play("select"); Flow.goto("settings"))
	_wood_btn("Wyjście", Rect2(1056, 494, 184, 46), false, 19).pressed.connect(_on_quit)

	stats_row = UiKit.label("", 15, Color(0.95, 0.9, 0.78))
	stats_row.position = Vector2(862, 676)
	add_child(stats_row)
	var hint := UiKit.label("Gra wieloosobowa (LAN) i arena: menu Esc w trakcie gry", 12, Color(0.8, 0.76, 0.66))
	hint.position = Vector2(862, 560)
	add_child(hint)
	GameState.profile_changed.connect(_refresh)
	_refresh()
	add_child(UiUpdater.new())
	Audio.play_music("menu")
	if _continue_btn and _continue_btn.visible:
		_continue_btn.grab_focus()

func _wood(bgc: Color, border: Color, bw: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bgc
	s.border_color = border
	s.set_border_width_all(bw)
	s.border_width_top = bw + 1
	s.set_corner_radius_all(3)
	s.anti_aliasing = false
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_offset = Vector2(0, 3)
	return s

func _wood_btn(text: String, r: Rect2, main := false, size := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.position = r.position
	b.size = r.size
	b.add_theme_font_size_override("font_size", size + (4 if main else 0))
	b.add_theme_color_override("font_color", Color(0.97, 0.93, 0.84))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.45))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.86, 0.45))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.03, 0.9))
	b.add_theme_constant_override("outline_size", 3)
	var base := Color(0.72, 0.38, 0.16) if main else Color(0.35, 0.24, 0.13)
	b.add_theme_stylebox_override("normal", _wood(base, Color(0.17, 0.11, 0.06)))
	b.add_theme_stylebox_override("hover", _wood(base.lightened(0.14), Color(0.95, 0.75, 0.3)))
	b.add_theme_stylebox_override("pressed", _wood(base.darkened(0.15), Color(0.17, 0.11, 0.06)))
	b.add_theme_stylebox_override("focus", _wood(base.lightened(0.08), Color(0.95, 0.75, 0.3)))
	add_child(b)
	return b

func _refresh() -> void:
	if stats_row:
		stats_row.text = "Złoto %d  ·  COD %d" % [GameState.gold(), GameState.cod()]
	if _continue_btn:
		_continue_btn.visible = GameState.slot_exists_any()

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
