class_name UiMmoStash
extends UiMmoPanel
## Skrytka wspólna dla postaci na serwerze: 3 zakładki. Dwuklik w plecaku przenosi przedmiot do skrytki, w skrytce — z powrotem.

var _state: Dictionary = {}
var _tab := 0
var _stash: ItemList
var _inv: ItemList
var _stash_slots: Array = []
var _tab_btns: Array = []

func _init() -> void:
	super._init("SKRYTKA")

func apply_state(data: Dictionary) -> void:
	_state = data
	if _stash != null:
		_fill()

func _build() -> void:
	_box.add_child(UiKit.label("Dwuklik przenosi przedmiot między plecakiem a skrytką. Skrytka jest wspólna dla wszystkich Twoich zakładek.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var tabs := UiKit.hbox(8)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(tabs)
	for t in 3:
		var b := UiKit.button("Zakładka %d" % (t + 1), 16)
		var ti: int = t
		b.pressed.connect(func(): _tab = ti; Audio.play("select"); _fill())
		tabs.add_child(b)
		_tab_btns.append(b)
	var row := UiKit.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(row)
	var left := UiKit.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UiKit.label("Skrytka", 17, UiKit.ACCENT))
	_stash = ItemList.new()
	_stash.custom_minimum_size = Vector2(380, 420)
	_stash.item_activated.connect(func(i: int):
		if i >= 0 and i < _stash_slots.size():
			Audio.play("select", 1.1, -6.0)
			Mmo.send_act("stash_take", {"tab": _tab, "slot": int(_stash_slots[i])}))
	left.add_child(_stash)
	var right := UiKit.vbox(4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(UiKit.label("Plecak", 17, UiKit.ACCENT2))
	_inv = ItemList.new()
	_inv.custom_minimum_size = Vector2(380, 420)
	_inv.item_activated.connect(func(i: int):
		Audio.play("select", 0.9, -6.0)
		Mmo.send_act("stash_put", {"idx": i, "tab": _tab}))
	right.add_child(_inv)
	Mmo.me_received.connect(func(_i): if _stash != null: _fill())
	if not _state.is_empty():
		_fill()

func _label_of(e: Dictionary) -> String:
	var d := ItemDB.get_data(String(e["id"]))
	var txt := String(d.get("name", e["id"]))
	if int(e["n"]) > 1:
		txt += " x%d" % int(e["n"])
	if e.has("q") and not is_equal_approx(float(e["q"]), 1.0):
		txt += "  (%.0f%%)" % (float(e["q"]) * 100.0)
	return txt

func _fill() -> void:
	for i in _tab_btns.size():
		(_tab_btns[i] as Button).add_theme_color_override("font_color", UiKit.ACCENT if i == _tab else UiKit.TEXT)
	_stash.clear()
	_stash_slots.clear()
	var tabs: Array = _state.get("tabs", [])
	if _tab < tabs.size():
		for e in tabs[_tab]:
			_stash.add_item(_label_of(e), Art.item_icon(String(e["id"]), 24))
			_stash.set_item_custom_fg_color(_stash.item_count - 1, ItemDB.rarity_color_of(ItemDB.rarity_of_entry(e)))
			_stash_slots.append(int(e["slot"]))
	_inv.clear()
	for e in Mmo.my_info.get("inv", []):
		_inv.add_item(_label_of(e), Art.item_icon(String(e["id"]), 24))
		_inv.set_item_custom_fg_color(_inv.item_count - 1, ItemDB.rarity_color_of(ItemDB.rarity_of_entry(e)))
