class_name UiLanLobby
extends Control
## Lobby LAN: Host tworzy pokój (dostaje KOD) albo gracz dołącza wpisując kod.
## Wybierasz klasę, potem gra się wspólnie w kampanię.

signal on_close
signal on_start(p1: String, p2: String, cls: String)

const CHARS := ["lord", "lady"]

var _mode := "host"        # host | join
var _char := "lord"
var _cls := "wojownik"
var _code := ""

var _code_field: LineEdit
var _code_label: Label
var _status: Label
var _char_row: HBoxContainer
var _class_row: HBoxContainer
var _class_desc: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.07, 0.11)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.05, 0.55)))
	var outer := UiKit.vbox(10)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.full(outer)
	add_child(outer)

	outer.add_child(UiKit.title("GRA LAN", 42))
	outer.add_child(UiKit.label("Host tworzy pokój i podaje KOD. Drugi gracz wpisuje tylko kod.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var modes := UiKit.hbox(10)
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(modes)
	var bh := UiKit.button("Hostuj", 20)
	bh.pressed.connect(func(): _mode = "host"; _refresh())
	modes.add_child(bh)
	var bj := UiKit.button("Dołącz", 20)
	bj.pressed.connect(func(): _mode = "join"; _refresh())
	modes.add_child(bj)

	outer.add_child(UiKit.sep(4))

	# --- kod
	var code_panel := UiKit.panel(UiKit.BG, 12)
	code_panel.custom_minimum_size = Vector2(560, 0)
	var cc := UiKit.hbox(10)
	code_panel.add_child(cc)
	outer.add_child(code_panel)
	_code_label = UiKit.label("KOD POKOJU", 16, UiKit.ACCENT)
	cc.add_child(_code_label)
	_code_field = LineEdit.new()
	_code_field.placeholder_text = "np. 7K2M"
	_code_field.max_length = 8
	_code_field.custom_minimum_size = Vector2(200, 44)
	_code_field.add_theme_font_size_override("font_size", 26)
	_code_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cc.add_child(_code_field)
	var gen := UiKit.button("Generuj", 18)
	gen.pressed.connect(func(): _on_generate())
	cc.add_child(gen)

	# --- postać
	_char_row = UiKit.hbox(10)
	_char_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(_char_row)

	# --- klasa
	outer.add_child(UiKit.label("Klasa", 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_class_row = UiKit.hbox(10)
	_class_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(_class_row)
	_class_desc = UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_class_desc)

	_status = UiKit.label("", 16, UiKit.ACCENT2, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_status)

	outer.add_child(UiKit.sep(6))
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(row)
	var back := UiKit.button("Wstecz", 20)
	back.pressed.connect(func(): Audio.play("back"); _leave(); on_close.emit())
	row.add_child(back)
	var go := UiKit.button("Start", 24)
	go.custom_minimum_size = Vector2(260, 50)
	go.pressed.connect(_on_go)
	row.add_child(go)

	Net.hosting_ready.connect(_on_hosting_ready)
	Net.joined_ok.connect(_on_joined_ok)
	Net.join_failed.connect(_on_join_failed)
	Net.peer_joined.connect(_on_peer_joined)

	_refresh()

func _leave() -> void:
	Net.reset()

func _on_generate() -> void:
	_code = Net.make_code()
	_code_field.text = _code

func _refresh() -> void:
	_char_row.visible = true
	if _mode == "host":
		_code_label.text = "KOD POKOJU (podaj drugiemu graczowi)"
		_code_field.editable = true
	else:
		_code_label.text = "WPISZ KOD OD HOSTA"
		_code_field.editable = true
	# postać
	for c in _char_row.get_children():
		c.queue_free()
	for id in CHARS:
		var b := UiKit.button(String(CharacterDB.get_data(id).get("title", id)), 20)
		var cid: String = id
		b.pressed.connect(func(): _char = cid; _refresh())
		if String(id) == _char:
			b.add_theme_color_override("font_color", UiKit.ACCENT)
		_char_row.add_child(b)
	# klasa
	for c in _class_row.get_children():
		c.queue_free()
	var avail := ClassDatabase.for_character(_char)
	if not avail.has(_cls):
		_cls = String(avail[0]) if avail.size() > 0 else ""
	for id in avail:
		var d := ClassDatabase.get_data(id)
		var b := UiKit.button(String(d.get("title", id)), 18, d.get("col", UiKit.ACCENT))
		var cid2: String = id
		b.pressed.connect(func(): _cls = cid2; _refresh())
		if String(id) == _cls:
			b.add_theme_color_override("font_color", d.get("col", UiKit.ACCENT))
		_class_row.add_child(b)
	_class_desc.text = String(ClassDatabase.get_data(_cls).get("desc", ""))

func _on_go() -> void:
	var code := _code_field.text.strip_edges().to_upper()
	if code.length() != 4:
		_status.text = "Kod musi mieć 4 znaki."
		Audio.play("deny")
		return
	Net.my_class = _cls
	Net.my_name = String(CharacterDB.get_data(_char).get("title", _char))
	Audio.play("confirm")
	if _mode == "host":
		_status.text = "Tworzę pokój…"
		Net.host_game(code)
	else:
		_status.text = "Szukam pokoju %s…" % code
		Net.join_game(code)

func _on_hosting_ready(code: String) -> void:
	_code = code
	_code_field.text = code
	_status.text = "Pokój otwarty. Czekam na drugiego gracza… (kod: %s)" % code

func _on_peer_joined(_id: int) -> void:
	_status.text = "Gracz dołączył! Startujemy."
	_start_local()

func _on_joined_ok() -> void:
	_status.text = "Połączono! Startujemy."
	_start_local()

func _on_join_failed(reason: String) -> void:
	_status.text = reason
	Audio.play("deny")

func _start_local() -> void:
	on_start.emit(_char, "", _cls)
