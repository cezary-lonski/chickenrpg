class_name UiResults
extends Control
## Podsumowanie etapu po zwycięstwie (albo po porażce, jeśli ktoś tam trafi).

signal victory_changed(v: bool)
signal continue_pressed
signal menu_pressed

var _rows: VBoxContainer
var _title: Label
var _sub: Label
var _results: Dictionary = {}
var _last := false
var _cont: Button
var _guest := false

func set_guest(guest: bool) -> void:
	_guest = guest

func set_results(r: Dictionary) -> void:
	_results = r
	_last = bool(r.get("last_stage", false))
	if is_inside_tree():
		_populate()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.08, 0.06)))
	var center := UiKit.vbox(6)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(center)
	add_child(center)
	_title = UiKit.title("", 58)
	center.add_child(_title)
	_sub = UiKit.label("", 22, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(_sub)
	center.add_child(UiKit.sep(20))
	var p := UiKit.panel(UiKit.BG, 12)
	p.custom_minimum_size = Vector2(560, 0)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(p)
	_rows = UiKit.vbox(4)
	p.add_child(_rows)
	center.add_child(UiKit.sep(20))
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	_cont = UiKit.button("Dalej", 24)
	_cont.custom_minimum_size = Vector2(280, 50)
	_cont.pressed.connect(func(): Audio.play("confirm"); continue_pressed.emit())
	row.add_child(_cont)
	var menu := UiKit.button("Menu", 20)
	menu.pressed.connect(func(): Audio.play("back"); menu_pressed.emit())
	row.add_child(menu)
	if _guest:
		_cont.text = "Czekam na hosta…"
		_cont.disabled = true
		center.add_child(UiKit.label("Dalszy ciąg uruchomi host.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		menu.grab_focus()
	else:
		_cont.grab_focus()
	_populate()
	if not _guest:
		victory_changed.emit(bool(_results.get("victory", true)))

func _populate() -> void:
	if _rows == null or _results.is_empty():
		return
	var win := bool(_results.get("victory", true))
	var story := bool(_results.get("story", false))
	_title.text = ("ROZDZIAŁ UKOŃCZONY" if story else "ETAP UKOŃCZONY") if win else "PORAŻKA"
	if story:
		_sub.text = "%s  ·  %s" % [String(_results.get("stage_name", "")), ("Kruk zaciska pięść. Ciąg dalszy nastąpi." if win else "Wioska upadła. Spróbuj ponownie.")]
	else:
		_sub.text = "%s  ·  %s" % [String(_results.get("stage_name", "")), ("To był ostatni etap!" if _last else "Dobra robota, kurczaku.") if win else "Kurczak przegrał. I tak bywa."]
	for c in _rows.get_children():
		c.queue_free()
	var t := float(_results.get("time", 0.0))
	_row("Wynik", str(int(_results.get("score", 0))), UiKit.ACCENT, 22)
	_row("Czas", "%d:%02d" % [int(t) / 60, int(t) % 60], UiKit.TEXT)
	_row("Pokonani wrogowie", str(int(_results.get("kills", 0))), UiKit.TEXT)
	_row("Zadane obrażenia", "%.0f" % float(_results.get("damage_dealt", 0.0)), UiKit.TEXT)
	_row("Otrzymane obrażenia", "%.0f" % float(_results.get("damage_taken", 0.0)), UiKit.BAD)
	_row("Najdłuższe combo", "x%d" % int(_results.get("max_combo", 0)), UiKit.ACCENT2)
	_row("Bloki / parry", "%d / %d" % [int(_results.get("blocks", 0)), int(_results.get("parries", 0))], UiKit.TEXT)
	_row("Złoto na etapie", "+%d" % int(_results.get("gold", 0)), Color(1, 0.85, 0.4))
	_rows.add_child(UiKit.sep(6))
	var cp := GameState.char_profile(String(GameState.run.get("character", "kurczak")))
	_row("Poziom", "%d  (%d / %d XP)" % [int(cp.get("level", 1)), int(cp.get("xp", 0)), CharacterDB.xp_for_level(int(cp.get("level", 1)))], UiKit.XP)
	_row("Łącznie złota", str(GameState.gold()), Color(1, 0.85, 0.4))
	_row("Łącznie piór", str(GameState.cod()), Color(0.88, 0.92, 1))
	if _last:
		_rows.add_child(UiKit.sep(6))
		_rows.add_child(UiKit.label("Wszystkie etapy przeszły. Ptaki nie odpuszczą.", 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	elif bool(_results.get("story", false)):
		_rows.add_child(UiKit.sep(6))
		var nxt := QuestDB.chapter(GameState.story_chapter())
		var line := "%s — %s" % [String(nxt.get("label", "")), String(nxt.get("title", ""))]
		_rows.add_child(UiKit.label("Dalej: %s" % line, 16, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER))

func _row(name_text: String, value: String, col: Color, size: int = 17) -> void:
	var h := UiKit.hbox(6)
	var a := UiKit.label(name_text, size, UiKit.DIM)
	a.custom_minimum_size = Vector2(240, 0)
	h.add_child(a)
	h.add_child(UiKit.label(value, size, col))
	_rows.add_child(h)
