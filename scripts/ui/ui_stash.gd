class_name UiStash
extends Control
## Skrytka w stylu Diablo 2 Resurrected: wspólna dla wszystkich postaci, 3 zakładki.
## Klik w przedmiot w ekwipunku przenosi go do skrytki, klik w skrytce — z powrotem do ekwipunku.

signal on_close

var _tab := 0
var _stash_grid: GridContainer
var _inv_grid: GridContainer
var _tab_btns: Array = []
var _info: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.05, 0.05, 0.08)))
	add_child(UiKit.dim(Color(0.02, 0.02, 0.04, 0.5)))
	var outer := UiKit.vbox(8)
	UiKit.full_margin(outer, 24.0)
	add_child(outer)
	outer.add_child(UiKit.title("SKRYTKA", 38))
	_info = UiKit.label("Kliknij przedmiot, aby przenieść go między ekwipunkiem a skrytką. Skrytka jest wspólna dla wszystkich postaci.", 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(_info)
	var row := UiKit.hbox(24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(row)
	# lewa: skrytka
	var left := UiKit.panel(UiKit.BG, 6)
	row.add_child(left)
	var lv := UiKit.vbox(6)
	left.add_child(lv)
	var tabs := UiKit.hbox(6)
	lv.add_child(tabs)
	lv.add_child(UiKit.label("Skrytka (wspólna)", 16, UiKit.ACCENT))
	for t in GameState.STASH_TABS:
		var b := UiKit.button("Zakładka %d" % (t + 1), 15)
		var ti: int = t
		b.pressed.connect(func(): _tab = ti; Audio.play("select"); _refresh())
		tabs.add_child(b)
		_tab_btns.append(b)
	_stash_grid = GridContainer.new()
	_stash_grid.columns = 10
	_stash_grid.add_theme_constant_override("h_separation", 3)
	_stash_grid.add_theme_constant_override("v_separation", 3)
	lv.add_child(_stash_grid)
	# prawa: ekwipunek
	var right := UiKit.panel(UiKit.BG, 6)
	row.add_child(right)
	var rv := UiKit.vbox(6)
	right.add_child(rv)
	rv.add_child(UiKit.label("Ekwipunek", 16, UiKit.ACCENT2))
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 10
	_inv_grid.add_theme_constant_override("h_separation", 3)
	_inv_grid.add_theme_constant_override("v_separation", 3)
	rv.add_child(_inv_grid)
	var back := UiKit.button("Zamknij", 20)
	back.pressed.connect(func(): Audio.play("back"); on_close.emit())
	var bar := UiKit.hbox(0)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(back)
	outer.add_child(bar)
	_refresh()

func _cell(entry: Variant, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(52, 52)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.add_theme_stylebox_override("normal", UiKit.sb(Color(0.1, 0.11, 0.16), 0, 2, Color(0.2, 0.22, 0.3)))
	b.add_theme_stylebox_override("hover", UiKit.sb(Color(0.18, 0.2, 0.28), 0, 2, UiKit.ACCENT))
	b.add_theme_stylebox_override("pressed", UiKit.sb(Color(0.25, 0.28, 0.38), 0, 2, UiKit.ACCENT))
	b.clip_contents = true
	b.size = Vector2(52, 52)
	if entry is Dictionary:
		var e: Dictionary = entry
		b.add_theme_stylebox_override("normal", UiKit.sb(Color(0.1, 0.11, 0.16), 0, 2, ItemDB.rarity_color_of(ItemDB.rarity_of_entry(e))))
		b.tooltip_text = "%s%s" % [String(ItemDB.get_data(String(e["id"])).get("name", e["id"])), (" ×%d" % int(e["n"])) if int(e["n"]) > 1 else ""]
		# ikona i licznik to dzieci przycisku — nie zmieniają jego rozmiaru
		var tr := TextureRect.new()
		tr.texture = Art.item_icon(String(e["id"]), 40)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(6, 6)
		tr.size = Vector2(40, 40)
		b.add_child(tr)
		if int(e["n"]) > 1:
			var cnt := UiKit.label(str(int(e["n"])), 12, Color(1, 1, 1))
			cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cnt.position = Vector2(30, 34)
			b.add_child(cnt)
		b.pressed.connect(cb)
	return b

func _refresh() -> void:
	for i in _tab_btns.size():
		(_tab_btns[i] as Button).add_theme_color_override("font_color", UiKit.ACCENT if i == _tab else UiKit.TEXT)
	for c in _stash_grid.get_children():
		c.queue_free()
	for c in _inv_grid.get_children():
		c.queue_free()
	var t: Array = GameState.stash()[_tab]
	for i in GameState.STASH_SLOTS:
		var slot: int = i
		_stash_grid.add_child(_cell(t[i], func():
			if GameState.stash_take(_tab, slot):
				Audio.play("select", 1.1, -6.0)
			else:
				Audio.play("deny")
			_refresh()))
	var inv_a := GameState.inv()
	for i in inv_a.size():
		var idx: int = i
		_inv_grid.add_child(_cell(inv_a[i], func():
			if GameState.stash_put(idx, _tab):
				Audio.play("select", 0.9, -6.0)
			else:
				Audio.play("deny")
				_info.text = "Ta zakładka jest pełna."
			_refresh()))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		on_close.emit()
