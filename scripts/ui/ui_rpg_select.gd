class_name UiRpgSelect
extends Control
## Wybór dla RPG: tryb Solo/LAN, Lord/Lady (P1 i P2) oraz klasa postaci.

signal on_start(mode: String, p1: String, p2: String, cls: String)

var _mode := "solo"
var _p1 := "lord"
var _p2 := "lady"
var _cls := "wojownik"
var _p2_box: VBoxContainer
var _class_box: VBoxContainer
var _class_pick := "p1"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.06, 0.08, 0.12)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.35)))
	var outer := UiKit.vbox(6)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(outer)
	add_child(outer)
	var root := outer
	root.add_child(UiKit.title("NOWA GRA RPG", 42))
	root.add_child(UiKit.label("Tryb, bohaterowie i klasa", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var rowm := UiKit.hbox(10)
	rowm.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(rowm)
	var btn_solo := UiKit.button("Solo", 20)
	btn_solo.pressed.connect(func(): _mode="solo"; _refresh())
	rowm.add_child(btn_solo)
	var btn_lan := UiKit.button("Gra LAN (przez kod)", 20)
	btn_lan.pressed.connect(func(): Audio.play("confirm"); Flow.goto("lan"))
	rowm.add_child(btn_lan)

	root.add_child(UiKit.sep(6))
	root.add_child(UiKit.label("Gracz 1 (P1)", 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var r1 := UiKit.hbox(10)
	r1.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(r1)
	var b1_lord := UiKit.button("Lord", 20)
	b1_lord.pressed.connect(func(): _p1="lord"; _class_pick="p1"; _refresh())
	r1.add_child(b1_lord)
	var b1_lady := UiKit.button("Lady", 20)
	b1_lady.pressed.connect(func(): _p1="lady"; _class_pick="p1"; _refresh())
	r1.add_child(b1_lady)

	_p2_box = UiKit.vbox(8)
	root.add_child(_p2_box)
	_p2_box.add_child(UiKit.label("Gracz 2 (P2)", 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var r2 := UiKit.hbox(10)
	r2.alignment = BoxContainer.ALIGNMENT_CENTER
	_p2_box.add_child(r2)
	var b2_lord := UiKit.button("Lord", 20)
	b2_lord.pressed.connect(func(): _p2="lord"; _refresh())
	r2.add_child(b2_lord)
	var b2_lady := UiKit.button("Lady", 20)
	b2_lady.pressed.connect(func(): _p2="lady"; _refresh())
	r2.add_child(b2_lady)

	_class_box = UiKit.vbox(6)
	root.add_child(_class_box)
	var crow := UiKit.hbox(10)
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	_class_box.add_child(crow)
	_class_btns_row = crow
	root.add_child(UiKit.sep(6))
	root.add_child(UiKit.label("Poziom trudności", 18, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var rd := UiKit.hbox(10)
	rd.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(rd)
	for did in GameState.DIFF_ORDER:
		var dd: Dictionary = GameState.DIFFICULTIES[did]
		var db := UiKit.button(String(dd["name"]), 18, dd["col"])
		db.custom_minimum_size = Vector2(170, 40)
		var d_id: String = did
		db.pressed.connect(func(): _diff = d_id; Audio.play("select"); _refresh_diff())
		rd.add_child(db)
		_diff_btns[did] = db
	_diff_desc = UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_diff_desc)
	_diff = GameState.difficulty()
	_refresh_diff()
	var chs := GameState.replayable_chapters()
	if not _slot_new() and chs.size() > 0:
		_chapters = chs
		var at := chs.find(GameState.story_chapter())
		_ch_pos = at if at >= 0 else chs.size() - 1
		root.add_child(UiKit.label("Rozdział (możesz powtórzyć dowolny odblokowany)", 16, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
		var rc := UiKit.hbox(10)
		rc.alignment = BoxContainer.ALIGNMENT_CENTER
		root.add_child(rc)
		var prev := UiKit.button("◀", 20)
		prev.custom_minimum_size = Vector2(60, 40)
		prev.pressed.connect(func(): _ch_pos = (_ch_pos - 1 + _chapters.size()) % _chapters.size(); Audio.play("select"); _refresh_chapter())
		rc.add_child(prev)
		_ch_label = UiKit.label("", 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		_ch_label.custom_minimum_size = Vector2(520, 0)
		rc.add_child(_ch_label)
		var nxt := UiKit.button("▶", 20)
		nxt.custom_minimum_size = Vector2(60, 40)
		nxt.pressed.connect(func(): _ch_pos = (_ch_pos + 1) % _chapters.size(); Audio.play("select"); _refresh_chapter())
		rc.add_child(nxt)
		_refresh_chapter()
	root.add_child(UiKit.sep(10))
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); Flow.goto("slots"))
	row.add_child(back)
	var start := UiKit.button("Rozpocznij RPG", 24)
	start.custom_minimum_size = Vector2(320, 50)
	start.pressed.connect(_on_start_pressed)
	row.add_child(start)

	_refresh()

var _diff := "normal"
var _diff_btns := {}
var _diff_desc: Label
var _chapters: Array = []
var _ch_pos := 0
var _ch_label: Label

func _slot_new() -> bool:
	return Flow._slot_is_new

func _refresh_diff() -> void:
	for did in _diff_btns:
		var b := _diff_btns[did] as Button
		var col: Color = GameState.DIFFICULTIES[did]["col"]
		b.add_theme_color_override("font_color", col if did == _diff else UiKit.TEXT)
		b.add_theme_stylebox_override("normal", UiKit.sb(Color(col.r, col.g, col.b, 0.28) if did == _diff else UiKit.BG2, 0, 2, col if did == _diff else Color(0, 0, 0, 0.5)))
	_diff_desc.text = String(GameState.DIFFICULTIES[_diff]["desc"])

func _refresh_chapter() -> void:
	var idx := int(_chapters[_ch_pos])
	var c := QuestDB.chapter(idx)
	var cur := idx == GameState.story_chapter()
	_ch_label.text = "%s — %s%s" % [String(c.get("label", "")), String(c.get("title", "")), "  (obecny)" if cur else "  (powtórka)"]

var _class_btns_row: HBoxContainer
var _class_desc: Label

func _refresh() -> void:
	_p2_box.visible = (_mode == "lan")
	if _mode == "lan" and _p2 == _p1:
		_p2 = "lady" if _p1 == "lord" else "lord"
	# klasa dla wybranej postaci
	var cid := _p1 if _class_pick == "p1" else _p2
	var avail := ClassDatabase.for_character(cid)
	# kontynuacja gry: klasa postaci jest na stałe, nie można jej zmienić
	var locked_cls := ""
	if not _slot_new():
		locked_cls = String(GameState.char_profile(cid).get("class", ""))
		if locked_cls != "" and avail.has(locked_cls):
			_cls = locked_cls
		else:
			locked_cls = ""
	if not avail.has(_cls):
		_cls = String(avail[0]) if avail.size() > 0 else ""
	for c in _class_btns_row.get_children():
		c.queue_free()
	_class_box.get_children()  # no-op
	for id in avail:
		var d := ClassDatabase.get_data(id)
		var b := UiKit.button(String(d.get("title", id)), 18, d.get("col", UiKit.ACCENT))
		b.custom_minimum_size = Vector2(160, 40)
		var cid2: String = id
		if locked_cls != "" and String(id) != locked_cls:
			b.disabled = true
		b.pressed.connect(func(): _cls=cid2; _refresh())
		if String(id) == _cls:
			b.add_theme_color_override("font_color", d.get("col", UiKit.ACCENT))
		_class_btns_row.add_child(b)
	if _class_desc and is_instance_valid(_class_desc):
		_class_desc.queue_free()
	_class_desc = UiKit.label(String(ClassDatabase.get_data(_cls).get("desc", "")) + ("   (klasa zapisanej postaci — nie można jej zmienić)" if locked_cls != "" else ""), 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_class_box.add_child(_class_desc)

func _on_start_pressed() -> void:
	if _mode == "lan" and _p2 == _p1:
		Audio.play("deny")
		return
	Audio.play("confirm")
	GameState.set_difficulty(_diff)
	Flow.pending_replay = -1
	if not _chapters.is_empty() and int(_chapters[_ch_pos]) != GameState.story_chapter():
		Flow.pending_replay = int(_chapters[_ch_pos])
	on_start.emit(_mode, _p1, _p2, _cls)
