class_name UiTrade
extends Control
## Wymiana przedmiotów między dwoma graczami (/wymiana). Każdy wkłada przedmioty do swojej oferty,
## obie strony zatwierdzają i przedmioty zamieniają się miejscami. Każda zmiana oferty zdejmuje zatwierdzenia.
## Host rozstrzyga: gdy oboje zatwierdzą, wysyła „execute” z obiema ofertami, a obie strony je wykonują.

signal on_close

var _mine: Dictionary = {}     # id -> liczba
var _theirs: Dictionary = {}
var _my_ok := false
var _their_ok := false
var _bag_box: VBoxContainer
var _mine_box: VBoxContainer
var _theirs_box: VBoxContainer
var _ok_btn: Button
var _status: Label
var _done := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.05, 0.04, 0.08, 0.25)))
	var root := UiKit.vbox(10)
	UiKit.full_margin(root, 40.0)
	add_child(root)
	root.add_child(UiKit.title("WYMIANA", 38))
	_status = UiKit.label("", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_status)
	var cols := UiKit.hbox(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	_bag_box = _column(cols, "TWÓJ PLECAK (kliknij, by dodać)")
	_mine_box = _column(cols, "TWOJA OFERTA (kliknij, by zabrać)")
	_theirs_box = _column(cols, "OFERTA: %s" % Net.remote_nick.to_upper())
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	_ok_btn = UiKit.button("Zatwierdź wymianę", 22, UiKit.GOOD)
	_ok_btn.custom_minimum_size = Vector2(300, 48)
	_ok_btn.pressed.connect(_toggle_ok)
	row.add_child(_ok_btn)
	var cancel := UiKit.button("Anuluj", 20, UiKit.BAD)
	cancel.pressed.connect(func():
		Audio.play("back")
		Net.send_trade("cancel")
		_close())
	row.add_child(cancel)
	Net.trade_received.connect(_on_trade)
	_refresh()
	_ok_btn.grab_focus()

func _exit_tree() -> void:
	if Net.trade_received.is_connected(_on_trade):
		Net.trade_received.disconnect(_on_trade)

func _column(parent: Control, title: String) -> VBoxContainer:
	var p := UiKit.panel(UiKit.BG, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var v := UiKit.vbox(6)
	p.add_child(v)
	v.add_child(UiKit.label(title, 13, UiKit.ACCENT))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UiKit.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	return list

func _name(id: String) -> String:
	return String(ItemDB.get_data(id).get("name", id))

func _have(id: String) -> int:
	return GameState.item_count(id)

func _fill(list: VBoxContainer, items: Dictionary, on_click: Callable, left_over: Dictionary = {}) -> void:
	for c in list.get_children():
		c.queue_free()
	var ids := items.keys()
	ids.sort()
	for id in ids:
		var shown := int(items[id]) - int(left_over.get(id, 0))
		if shown <= 0:
			continue
		var b := UiKit.button("%s  ×%d" % [_name(String(id)), shown], 16)
		b.custom_minimum_size = Vector2(0, 36)
		b.icon = Art.item_icon(String(id), 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if on_click.is_valid():
			b.pressed.connect(on_click.bind(String(id)))
		else:
			b.disabled = true
			b.focus_mode = Control.FOCUS_NONE
		list.add_child(b)
	if list.get_child_count() == 0:
		list.add_child(UiKit.label("— pusto —", 14, UiKit.DIM))

func _refresh() -> void:
	var bag := {}
	for e in GameState.inv():
		if e is Dictionary:
			bag[String(e["id"])] = int(bag.get(String(e["id"]), 0)) + int(e["n"])
	_fill(_bag_box, bag, _add, _mine)
	_fill(_mine_box, _mine, _remove)
	_fill(_theirs_box, _theirs, Callable())
	_ok_btn.text = "Cofnij zatwierdzenie" if _my_ok else "Zatwierdź wymianę"
	var s := "Ty: %s   ·   %s: %s" % ["zatwierdzone ✔" if _my_ok else "nie", Net.remote_nick, "zatwierdzone ✔" if _their_ok else "nie"]
	_status.text = s + "\nKażda zmiana oferty zdejmuje zatwierdzenia obu stron."

func _changed() -> void:
	_my_ok = false
	_their_ok = false
	Net.send_trade("offer", {"items": _mine})
	_refresh()

func _add(id: String) -> void:
	if int(_mine.get(id, 0)) >= _have(id):
		return
	Audio.play("select")
	_mine[id] = int(_mine.get(id, 0)) + 1
	_changed()

func _remove(id: String) -> void:
	Audio.play("select")
	_mine[id] = int(_mine.get(id, 0)) - 1
	if int(_mine[id]) <= 0:
		_mine.erase(id)
	_changed()

func _toggle_ok() -> void:
	Audio.play("confirm")
	_my_ok = not _my_ok
	if _my_ok:
		for id in _mine:
			if _have(String(id)) < int(_mine[id]):
				_my_ok = false
				GameState.toast.emit("Nie masz już tych przedmiotów.", UiKit.BAD)
				break
	Net.send_trade("confirm", {"ok": _my_ok, "items": _mine})
	_refresh()
	_maybe_execute()

func _maybe_execute() -> void:
	if _done or not Net.is_host or not _my_ok or not _their_ok:
		return
	Net.send_trade("execute", {"h": _mine, "g": _theirs})
	_apply(_mine, _theirs)

func _on_trade(kind: String, data: Dictionary) -> void:
	if _done:
		return
	match kind:
		"offer":
			_theirs = data.get("items", {})
			_my_ok = false
			_their_ok = false
			_refresh()
		"confirm":
			_theirs = data.get("items", {})
			_their_ok = bool(data.get("ok", false))
			_refresh()
			_maybe_execute()
		"cancel":
			GameState.toast.emit("%s anulował wymianę." % Net.remote_nick, UiKit.BAD)
			_close()
		"execute":
			if not Net.is_host and _my_ok:
				_apply(data.get("g", {}), data.get("h", {}))

## give — to, co oddaję; get — to, co dostaję.
func _apply(give: Dictionary, get_items: Dictionary) -> void:
	_done = true
	for id in give:
		if _have(String(id)) < int(give[id]):
			GameState.toast.emit("Wymiana nieudana: brakuje przedmiotów.", UiKit.BAD)
			_close()
			return
	for id in give:
		GameState.remove_item(String(id), int(give[id]))
	for id in get_items:
		GameState.add_item(String(id), int(get_items[id]))
	GameState.save_game()
	Audio.play("levelup", 1.1, -4.0)
	GameState.toast.emit("Wymiana zakończona!", UiKit.GOOD)
	_close()

func _close() -> void:
	_done = true
	on_close.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Net.send_trade("cancel")
		_close()
