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
	var btn_lan := UiKit.button("LAN (Lord + Lady)", 20)
	btn_lan.pressed.connect(func(): _mode="lan"; _refresh())
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

var _class_btns_row: HBoxContainer
var _class_desc: Label

func _refresh() -> void:
	_p2_box.visible = (_mode == "lan")
	if _mode == "lan" and _p2 == _p1:
		_p2 = "lady" if _p1 == "lord" else "lord"
	# klasa dla wybranej postaci
	var cid := _p1 if _class_pick == "p1" else _p2
	var avail := ClassDatabase.for_character(cid)
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
		b.pressed.connect(func(): _cls=cid2; _refresh())
		if String(id) == _cls:
			b.add_theme_color_override("font_color", d.get("col", UiKit.ACCENT))
		_class_btns_row.add_child(b)
	if _class_desc and is_instance_valid(_class_desc):
		_class_desc.queue_free()
	_class_desc = UiKit.label(String(ClassDatabase.get_data(_cls).get("desc", "")), 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_class_box.add_child(_class_desc)

func _on_start_pressed() -> void:
	if _mode == "lan" and _p2 == _p1:
		Audio.play("deny")
		return
	Audio.play("confirm")
	on_start.emit(_mode, _p1, _p2, _cls)
